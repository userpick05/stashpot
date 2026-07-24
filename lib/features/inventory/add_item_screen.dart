import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/providers/inventory_providers.dart';
import '../../core/providers/scanning_providers.dart';
import '../../core/utils/category_guess.dart';
import '../../core/utils/category_icons.dart';
import '../../core/utils/labels.dart';
import '../../l10n/app_localizations.dart';
import '../../models/inventory_item.dart';

class AddItemScreen extends ConsumerStatefulWidget {
  /// When non-null, the screen edits this existing item instead of adding.
  final InventoryItem? existing;
  /// 'scan' or 'photo' to jump straight into that flow on open.
  final String? autoStart;
  const AddItemScreen({super.key, this.existing, this.autoStart});

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _storeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  ItemCategory _category = ItemCategory.other;
  String _location = kDefaultLocationKey;
  String _unit = 'item';
  DateTime? _expiryDate;
  String? _barcode;
  String? _imageUrl;
  bool _loading = false;
  bool _looking = false;
  bool _identifying = false;
  bool _uploadingPhoto = false;
  bool _categoryManuallySet = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _qtyCtrl.text = e.quantity % 1 == 0
          ? e.quantity.toInt().toString()
          : e.quantity.toString();
      _storeCtrl.text = e.store ?? '';
      _notesCtrl.text = e.notes ?? '';
      _category = e.category;
      _location = e.location;
      _unit = _units.contains(e.unit) ? e.unit : _units.first;
      _expiryDate = e.expiryDate;
      _barcode = e.barcode;
      _imageUrl = e.imageUrl;
      _categoryManuallySet = true; // don't auto-override an existing item's type
    } else if (widget.autoStart != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.autoStart == 'scan') _scanBarcode();
        if (widget.autoStart == 'photo') _identifyByPhoto();
      });
    }
  }

  // Prompt for a new custom location, save it to the household, and select it.
  Future<void> _addLocationFlow() async {
    final l = AppLocalizations.of(context);
    final ctrl = TextEditingController();
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 0, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.addItemNewLocationTitle,
                style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: l.addItemNewLocationHint,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (v) => Navigator.pop(ctx, v),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx, ctrl.text),
                child: Text(l.commonAdd),
              ),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    final hid = ref.read(householdIdProvider);
    if (hid != null) {
      await ref.read(firestoreServiceProvider).addLocation(hid, trimmed);
    }
    if (mounted) setState(() => _location = trimmed);
  }

  Future<void> _attachPhoto() async {
    final l = AppLocalizations.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(l.addItemTakePhoto),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l.addItemChooseFromGallery),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.addItemCameraPermissionPhoto)),
          );
        }
        return;
      }
    }
    final photo = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1280,
      imageQuality: 80,
    );
    if (photo == null) return;
    final householdId = ref.read(householdIdProvider);
    if (householdId == null) return;
    setState(() => _uploadingPhoto = true);
    try {
      final bytes = await photo.readAsBytes();
      final url = await ref.read(storageServiceProvider).uploadImage(householdId, bytes);
      if (mounted) setState(() => _imageUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.addItemPhotoUploadFailed(e.toString())),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  // Auto-detect the food type as the user types (until they pick one themselves).
  void _onNameChanged(String name) {
    if (_categoryManuallySet) return;
    final guess = guessCategory(name);
    if (guess != null && guess != _category) {
      setState(() => _category = guess);
    }
  }

  static const _units = ['item', 'g', 'kg', 'ml', 'L', 'oz', 'lb', 'cup', 'bunch'];

  Future<void> _identifyByPhoto() async {
    final l = AppLocalizations.of(context);
    // The vision model answers in the app's language.
    final lang = Localizations.localeOf(context).languageCode;
    // Let the user choose camera or gallery.
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(l.addItemTakePhoto),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l.addItemChooseFromGallery),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    // Camera capture requires the runtime CAMERA permission (it's declared in
    // the manifest for the scanner). Gallery uses the system picker — no grant.
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.addItemCameraPermissionPhoto)),
          );
        }
        return;
      }
    }

    final XFile? photo = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (photo == null || !mounted) return;

    setState(() => _identifying = true);
    try {
      final bytes = await photo.readAsBytes();
      final result = await ref
          .read(geminiServiceProvider)
          .identifyFood(bytes, languageCode: lang);
      if (!mounted) return;
      if (result == null || result.name == 'Unknown' || result.confidence == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.addItemIdentifyFailed)),
        );
        return;
      }
      setState(() {
        _nameCtrl.text = result.name;
        _category = result.category;
        if (result.details != null) _notesCtrl.text = result.details!;
        if (result.store != null) _storeCtrl.text = result.store!;
      });
      final pct = (result.confidence * 100).round();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.addItemIdentified(result.name, pct))),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.addItemPhotoIdError(e.toString())),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _identifying = false);
    }
  }

  /// The barcode wasn't in the product database — offer to identify it from a
  /// photo instead (the vision model reads packaging in any script), rather
  /// than dead-ending on "not found".
  Future<void> _offerPhotoFallback(String code) async {
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    final takePhoto = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.addItemBarcodeNotFoundTitle(code),
                style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(l.addItemBarcodeNotFoundBody),
            const SizedBox(height: 20),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l.addItemEnterManually),
                ),
                const Spacer(),
                FilledButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: () => Navigator.pop(ctx, true),
                  label: Text(l.addItemTakePhotoInstead),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (takePhoto == true && mounted) await _identifyByPhoto();
  }

  Future<void> _scanBarcode() async {
    final l = AppLocalizations.of(context);
    // Ask Open Food Facts for the name in the app's language when it has one.
    final lang = Localizations.localeOf(context).languageCode;
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.addItemCameraPermissionScan)),
        );
      }
      return;
    }
    if (!mounted) return;
    // The live camera preview NPEs inside the camera engine on some devices
    // (Pixel 10 / Android 16), so capture a full-resolution photo and decode
    // THAT with ML Kit (via mobile_scanner's analyzeImage) — this never starts
    // the camera preview, so it can't hit that crash. No maxWidth: downscaling
    // blurs the bars below the detector's threshold.
    final photo = await ImagePicker().pickImage(source: ImageSource.camera);
    if (photo == null || !mounted) return;

    setState(() => _looking = true);
    String? code;
    final scanner = MobileScannerController();
    try {
      final capture = await scanner.analyzeImage(photo.path);
      if (capture != null) {
        for (final b in capture.barcodes) {
          if (b.rawValue != null && b.rawValue!.isNotEmpty) {
            code = b.rawValue;
            break;
          }
        }
      }
    } catch (_) {
      code = null;
    } finally {
      await scanner.dispose();
    }
    if (!mounted) return;
    if (code == null || code.isEmpty) {
      setState(() => _looking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.addItemBarcodeUnreadable)),
      );
      return;
    }

    setState(() {
      _barcode = code;
      _looking = true;
    });
    try {
      final product = await ref
          .read(openFoodFactsServiceProvider)
          .lookup(code, languageCode: lang);
      if (!mounted) return;
      if (product == null) {
        // Open Food Facts has thin coverage outside Western markets, so a miss
        // is common (especially for Chinese products). Don't dead-end: offer the
        // photo identifier, which reads the packaging in any script.
        setState(() => _looking = false);
        await _offerPhotoFallback(code);
        return;
      }
      setState(() {
        if (product.displayName != null) _nameCtrl.text = product.displayName!;
        _category = product.category;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.addItemProductFound(product.displayName ?? code))),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.addItemLookupError(e.toString())),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _looking = false);
    }
  }

  // Bottom sheet to pick from the household's saved stores.
  Future<void> _pickStore() async {
    final l = AppLocalizations.of(context);
    final stores = ref.read(storesProvider).valueOrNull ?? [];
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: stores.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l.addItemNoSavedStores,
                  textAlign: TextAlign.center,
                ),
              )
            : ListView(
                shrinkWrap: true,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(l.addItemPickStore,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  for (final s in stores)
                    ListTile(
                      leading: const Icon(Icons.storefront),
                      title: Text(s),
                      onTap: () => Navigator.pop(ctx, s),
                    ),
                ],
              ),
      ),
    );
    if (picked != null) setState(() => _storeCtrl.text = picked);
  }

  // Silently remember a newly-typed store so it's pickable next time. (No
  // confirm dialog — matches the shopping sheet, and AlertDialogs black-screen
  // via Impeller on some devices.)
  Future<void> _maybeSaveNewStore(String householdId, String store) async {
    final known = ref.read(storesProvider).valueOrNull ?? [];
    final exists = known.any((s) => s.toLowerCase() == store.toLowerCase());
    if (exists) return;
    await ref.read(firestoreServiceProvider).addStore(householdId, store);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _storeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final householdId = ref.read(householdIdProvider);
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (householdId == null || uid == null) return;

    final store = _storeCtrl.text.trim();
    // Offer to remember a newly-typed store before saving the item.
    if (store.isNotEmpty) {
      await _maybeSaveNewStore(householdId, store);
      if (!mounted) return;
    }

    setState(() => _loading = true);
    try {
      final e = widget.existing;
      final item = InventoryItem(
        id: e?.id ?? const Uuid().v4(),
        name: _nameCtrl.text.trim(),
        barcode: _barcode,
        imageUrl: _imageUrl,
        category: _category,
        quantity: double.tryParse(_qtyCtrl.text) ?? 1,
        unit: _unit,
        location: _location,
        store: store.isEmpty ? null : store,
        expiryDate: _expiryDate,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        addedAt: e?.addedAt ?? DateTime.now(),
        addedBy: e?.addedBy ?? uid,
      );
      // addItem uses set() keyed by id, so it both creates and updates.
      await ref.read(firestoreServiceProvider).addItem(householdId, item);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l.addItemTitleEdit : l.addItemTitleAdd),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: Text(l.commonSave),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Scan barcode → auto-fill from Open Food Facts
            OutlinedButton.icon(
              onPressed: _looking ? null : _scanBarcode,
              icon: _looking
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.qr_code_scanner),
              label: Text(_looking
                  ? l.addItemLookingUp
                  : _barcode == null
                      ? l.addItemScanBarcode
                      : l.addItemScanned(_barcode!)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 8),

            // Identify by photo → Gemini vision
            OutlinedButton.icon(
              onPressed: _identifying ? null : _identifyByPhoto,
              icon: _identifying
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.center_focus_strong),
              label: Text(
                  _identifying ? l.addItemIdentifying : l.addItemIdentifyByPhoto),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 16),

            // Name (auto-detects food type as you type)
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.sentences,
              onChanged: _onNameChanged,
              decoration: InputDecoration(
                labelText: l.addItemNameLabel,
                border: const OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? l.addItemNameRequired : null,
            ),
            const SizedBox(height: 16),

            // Qty + Unit
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _qtyCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: l.addItemQuantityLabel,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      return n == null || n <= 0 ? l.addItemQuantityInvalid : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: _unit,
                    decoration: InputDecoration(
                      labelText: l.addItemUnitLabel,
                      border: const OutlineInputBorder(),
                    ),
                    // _units holds the STORED keys; only the label is localized.
                    items: _units
                        .map((u) => DropdownMenuItem(
                            value: u, child: Text(unitLabelOf(l, u))))
                        .toList(),
                    onChanged: (v) => setState(() => _unit = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category (food type) — auto-detected, tap to override
            DropdownButtonFormField<ItemCategory>(
              value: _category,
              decoration: InputDecoration(
                labelText: l.addItemFoodTypeLabel,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final c in kPickableCategories.contains(_category)
                    ? kPickableCategories
                    : [...kPickableCategories, _category])
                  DropdownMenuItem(
                    value: c,
                    child: Row(
                      children: [
                        Icon(categoryIcon(c), size: 18),
                        const SizedBox(width: 8),
                        Text(categoryLabelOf(l, c)),
                      ],
                    ),
                  ),
              ],
              onChanged: (v) => setState(() {
                _category = v!;
                _categoryManuallySet = true;
              }),
            ),
            const SizedBox(height: 16),

            // Location — built-ins + custom locations, plus "Add location…"
            Builder(builder: (context) {
              const addSentinel = '__add_location__';
              final keys = [...ref.watch(allLocationKeysProvider)];
              if (!keys.contains(_location)) keys.add(_location);
              return DropdownButtonFormField<String>(
                value: _location,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l.addItemLocationLabel,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  // The dropdown's values are the STORED location keys.
                  for (final k in keys)
                    DropdownMenuItem(
                      value: k,
                      child: Row(
                        children: [
                          Icon(locationIcon(k), size: 18),
                          const SizedBox(width: 8),
                          Text(locationLabelOf(l, k)),
                        ],
                      ),
                    ),
                  DropdownMenuItem(
                    value: addSentinel,
                    child: Row(
                      children: [
                        const Icon(Icons.add, size: 18),
                        const SizedBox(width: 8),
                        Text(l.addItemAddLocation),
                      ],
                    ),
                  ),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  if (v == addSentinel) {
                    _addLocationFlow();
                  } else {
                    setState(() => _location = v);
                  }
                },
              );
            }),
            const SizedBox(height: 16),

            // Store — pick from saved list or type a new one (used to group
            // shopping lists by store later).
            TextFormField(
              controller: _storeCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l.addItemStoreLabel,
                hintText: l.addItemStoreHint,
                prefixIcon: const Icon(Icons.storefront),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_drop_down),
                  tooltip: l.addItemPickStoreTooltip,
                  onPressed: _pickStore,
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Expiry date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(_expiryDate == null
                  ? l.addItemExpiryLabel
                  // Date order follows the locale (DateFormat.yMd), not d/m/y.
                  : l.addItemExpiresOn(_expiryDate!)),
              trailing: _expiryDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _expiryDate = null),
                    )
                  : null,
              onTap: _pickExpiry,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l.addItemNotesLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Photo (optional) — stored but not shown in the list
            if (_imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(_imageUrl!,
                          width: 64, height: 64, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 48)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(l.addItemPhotoAttached)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: l.addItemRemovePhoto,
                      onPressed: () => setState(() => _imageUrl = null),
                    ),
                  ],
                ),
              ),
            OutlinedButton.icon(
              onPressed: _uploadingPhoto ? null : _attachPhoto,
              icon: _uploadingPhoto
                  ? const SizedBox(
                      height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.add_a_photo),
              label: Text(_uploadingPhoto
                  ? l.addItemUploading
                  : _imageUrl == null
                      ? l.addItemAddPhoto
                      : l.addItemReplacePhoto),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
            const SizedBox(height: 24),

            FilledButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? l.addItemSaveChanges : l.addItemAddToPantry),
            ),
          ],
        ),
      ),
    );
  }
}
