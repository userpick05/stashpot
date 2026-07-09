import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/providers/inventory_providers.dart';
import '../../core/providers/scanning_providers.dart';
import '../../core/utils/category_guess.dart';
import '../../core/utils/category_icons.dart';
import '../../models/inventory_item.dart';
import '../scanning/barcode_scanner_screen.dart';

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
            Text('New location', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'e.g. Garage shelf',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (v) => Navigator.pop(ctx, v),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx, ctrl.text),
                child: const Text('Add'),
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
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
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
            const SnackBar(content: Text('Camera permission is needed to take a photo')),
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
            content: Text('Photo upload failed: $e'),
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
    // Let the user choose camera or gallery.
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
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
            const SnackBar(content: Text('Camera permission is needed to take a photo')),
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
      final result = await ref.read(geminiServiceProvider).identifyFood(bytes);
      if (!mounted) return;
      if (result == null || result.name == 'Unknown' || result.confidence == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't identify the food — enter it manually")),
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
        SnackBar(content: Text('Identified: ${result.name} ($pct% sure)')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo ID failed: $e. You can still add it manually.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _identifying = false);
    }
  }

  Future<void> _scanBarcode() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is needed to scan')),
        );
      }
      return;
    }
    if (!mounted) return;
    // Live-preview scanner (mobile_scanner). Returns the decoded barcode, or
    // null if the user backs out / chooses to enter the item manually.
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (code == null || code.isEmpty || !mounted) return;

    setState(() {
      _barcode = code;
      _looking = true;
    });
    try {
      final product = await ref.read(openFoodFactsServiceProvider).lookup(code);
      if (!mounted) return;
      if (product == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No product found for $code — enter details manually')),
        );
        return;
      }
      setState(() {
        if (product.displayName != null) _nameCtrl.text = product.displayName!;
        _category = product.category;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Found: ${product.displayName ?? code}')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lookup failed: $e. You can still add it manually.'),
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
    final stores = ref.read(storesProvider).valueOrNull ?? [];
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: stores.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No saved stores yet. Type a store name below and you\'ll be '
                  'asked to add it to the list.',
                  textAlign: TextAlign.center,
                ),
              )
            : ListView(
                shrinkWrap: true,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text('Pick a store',
                        style: TextStyle(fontWeight: FontWeight.bold)),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit item' : 'Add item'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: const Text('Save'),
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
                  ? 'Looking up product…'
                  : _barcode == null
                      ? 'Scan barcode'
                      : 'Scanned: $_barcode (rescan)'),
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
              label: Text(_identifying ? 'Identifying…' : 'Identify by photo'),
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
              decoration: const InputDecoration(
                labelText: 'Item name *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter a name' : null,
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
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      return n == null || n <= 0 ? 'Invalid' : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: _unit,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                    ),
                    items: _units
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
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
              decoration: const InputDecoration(
                labelText: 'Food type',
                border: OutlineInputBorder(),
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
                        Text(c.label),
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
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final k in keys)
                    DropdownMenuItem(
                      value: k,
                      child: Row(
                        children: [
                          Icon(locationIcon(k), size: 18),
                          const SizedBox(width: 8),
                          Text(locationLabel(k)),
                        ],
                      ),
                    ),
                  const DropdownMenuItem(
                    value: addSentinel,
                    child: Row(
                      children: [
                        Icon(Icons.add, size: 18),
                        SizedBox(width: 8),
                        Text('Add location…'),
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
                labelText: 'Store (optional)',
                hintText: 'e.g. Costco, Walmart, Trader Joe\'s',
                prefixIcon: const Icon(Icons.storefront),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_drop_down),
                  tooltip: 'Pick from saved stores',
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
                  ? 'Expiry date (optional)'
                  : 'Expires: ${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'),
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
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
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
                    const Expanded(child: Text('Photo attached')),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Remove photo',
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
                  ? 'Uploading…'
                  : _imageUrl == null
                      ? 'Add photo'
                      : 'Replace photo'),
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
                  : Text(_isEditing ? 'Save changes' : 'Add to pantry'),
            ),
          ],
        ),
      ),
    );
  }
}
