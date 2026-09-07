import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/providers/inventory_providers.dart';
import '../../core/providers/scanning_providers.dart';
import '../../core/utils/category_icons.dart';
import '../../core/utils/labels.dart';
import '../../core/utils/pantry_match.dart';
import '../../l10n/app_localizations.dart';
import '../../models/inventory_item.dart';
import '../../models/shopping_item.dart';

/// Bottom sheet for adding or editing a shopping-list item.
class AddShoppingItemSheet extends ConsumerStatefulWidget {
  /// When non-null, edits this existing item instead of adding a new one.
  final ShoppingItem? existing;
  const AddShoppingItemSheet({super.key, this.existing});

  @override
  ConsumerState<AddShoppingItemSheet> createState() =>
      _AddShoppingItemSheetState();
}

class _AddShoppingItemSheetState extends ConsumerState<AddShoppingItemSheet> {
  final _nameCtrl = TextEditingController();
  final _storeCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  int _quantity = 1;
  bool _saving = false;
  bool _identifying = false;

  // Same optional fields a pantry item has, so a card carries everything.
  ItemCategory _category = ItemCategory.other;
  String _unit = 'item';
  String? _location; // optional on the shopping side
  DateTime? _expiryDate;

  static const _units = ['item', 'g', 'kg', 'ml', 'L', 'oz', 'lb', 'cup', 'bunch'];

  bool get _isEditing => widget.existing != null;

  // Snap a photo and let Gemini identify the item, prefilling the fields — the
  // same flow the pantry add screen uses.
  Future<void> _identifyByPhoto() async {
    final l = AppLocalizations.of(context);
    // Captured before any await — the vision model answers in this language.
    final lang = Localizations.localeOf(context).languageCode;
    // Let the user choose camera or gallery — gallery lets her pick a saved
    // screenshot of something she wants to shop for.
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(l.shoppingTakePhoto),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l.shoppingChooseFromGallery),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    // Camera capture needs the runtime permission; gallery uses the system
    // picker and needs no grant.
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.shoppingCameraPermissionNeeded)),
          );
        }
        return;
      }
    }

    final photo = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (photo == null || !mounted) return;

    setState(() => _identifying = true);
    try {
      final bytes = await photo.readAsBytes();
      // The vision model answers in the app's language, so a Chinese user
      // photographing Chinese packaging gets a Chinese item name.
      final result = await ref
          .read(geminiServiceProvider)
          .identifyFood(bytes, languageCode: lang);
      if (!mounted) return;
      if (result == null || result.name == 'Unknown' || result.confidence == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.shoppingCouldNotIdentify)),
        );
        return;
      }
      setState(() {
        _nameCtrl.text = result.name;
        if (result.details != null) _noteCtrl.text = result.details!;
        if (result.store != null) _storeCtrl.text = result.store!;
      });
      final pct = (result.confidence * 100).round();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.shoppingIdentified(result.name, pct))),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.shoppingPhotoIdFailed('$e')),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _identifying = false);
    }
  }

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _storeCtrl.text = e.store ?? '';
      _noteCtrl.text = e.note ?? '';
      _quantity = e.quantity.round().clamp(1, 999);
      _category = e.category;
      _unit = _units.contains(e.unit) ? e.unit : _units.first;
      _location = e.location;
      _expiryDate = e.expiryDate;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _storeCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStore() async {
    final stores = ref.read(storesProvider).valueOrNull ?? [];
    if (stores.isEmpty) return;
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
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

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  // Add a custom location on the fly, mirroring the pantry editor.
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

  /// If the typed item is already in the pantry (or something like it is), give
  /// the user a chance to reconsider before it goes on the list — so a "chicken"
  /// they already have doesn't get bought twice, and a "chicken" that only
  /// surfaces "chicken broth" is theirs to judge. Returns true to go ahead.
  ///
  /// Skipped when editing an existing item — the warning is for fresh adds.
  Future<bool> _confirmNotAlreadyStocked(String name) async {
    if (_isEditing) return true;
    final pantry = ref.read(inventoryProvider).valueOrNull ?? const [];
    final match = PantryMatch.overlap(name, [for (final i in pantry) i.name]);
    if (match.strong.isEmpty && match.similar.isEmpty) return true;

    final l = AppLocalizations.of(context);
    // Bottom sheet, not a dialog — AlertDialogs black-screen via Impeller here.
    final proceed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Icon(Icons.inventory_2_outlined,
                    color: Theme.of(ctx).colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    match.strong.isNotEmpty
                        ? l.pantryWarnTitleHave
                        : l.pantryWarnTitleSimilar,
                    style: Theme.of(ctx).textTheme.titleMedium,
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              if (match.strong.isNotEmpty) ...[
                Text(l.pantryWarnAlready,
                    style: Theme.of(ctx).textTheme.labelLarge),
                for (final n in match.strong)
                  _PantryHit(name: n, strong: true),
                const SizedBox(height: 8),
              ],
              if (match.similar.isNotEmpty) ...[
                Text(l.pantryWarnSimilar,
                    style: Theme.of(ctx).textTheme.labelLarge),
                for (final n in match.similar)
                  _PantryHit(name: n, strong: false),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(l.commonCancel),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(l.pantryWarnAddAnyway),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
    return proceed ?? false;
  }

  Future<void> _add() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final householdId = ref.read(householdIdProvider);
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (householdId == null || uid == null) return;

    if (!await _confirmNotAlreadyStocked(name)) return;
    if (!mounted) return;

    setState(() => _saving = true);
    try {
      final store = _storeCtrl.text.trim();
      final svc = ref.read(firestoreServiceProvider);
      // Remember a new store for next time (silent — quick-add context).
      final known = ref.read(storesProvider).valueOrNull ?? [];
      if (store.isNotEmpty &&
          !known.any((s) => s.toLowerCase() == store.toLowerCase())) {
        await svc.addStore(householdId, store);
      }
      final e = widget.existing;
      final item = ShoppingItem(
        id: e?.id ?? const Uuid().v4(),
        name: name,
        store: store.isEmpty ? null : store,
        quantity: _quantity.toDouble(),
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        checked: e?.checked ?? false,
        category: _category,
        unit: _unit,
        location: _location,
        expiryDate: _expiryDate,
        // Not editable here yet, but carried so an edit never drops them.
        imageUrl: e?.imageUrl,
        barcode: e?.barcode,
        addedAt: e?.addedAt ?? DateTime.now(),
        addedBy: e?.addedBy ?? uid,
      );
      if (e != null) {
        await svc.updateShoppingItem(householdId, item);
      } else {
        await svc.addShoppingItem(householdId, item);
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_isEditing ? l.shoppingEditTitle : l.shoppingAddTitle,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            autofocus: !_isEditing,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l.shoppingItemLabel,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _add(),
          ),
          if (!_isEditing) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _identifying ? null : _identifyByPhoto,
              icon: _identifying
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.camera_alt),
              label: Text(_identifying
                  ? l.shoppingIdentifying
                  : l.shoppingTakePhotoToIdentify),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _storeCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l.shoppingStoreOptional,
                    prefixIcon: const Icon(Icons.storefront),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_drop_down),
                      tooltip: l.shoppingPickFromSavedStores,
                      onPressed: _pickStore,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Quantity stepper
          Row(
            children: [
              Text(l.shoppingQuantity),
              const Spacer(),
              IconButton.outlined(
                icon: const Icon(Icons.remove),
                onPressed: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('$_quantity',
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              IconButton.outlined(
                icon: const Icon(Icons.add),
                onPressed: () => setState(() => _quantity++),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            decoration: InputDecoration(
              labelText: l.shoppingNoteOptional,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          // ── Same optional fields a pantry item has (all optional) ────────
          DropdownButtonFormField<String>(
            initialValue: _unit,
            decoration: InputDecoration(
              labelText: l.addItemUnitLabel,
              border: const OutlineInputBorder(),
            ),
            items: _units
                .map((u) =>
                    DropdownMenuItem(value: u, child: Text(unitLabelOf(l, u))))
                .toList(),
            onChanged: (v) => setState(() => _unit = v ?? _unit),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ItemCategory>(
            initialValue: _category,
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
                  child: Row(children: [
                    Icon(categoryIcon(c), size: 18),
                    const SizedBox(width: 8),
                    Text(categoryLabelOf(l, c)),
                  ]),
                ),
            ],
            onChanged: (v) => setState(() => _category = v ?? _category),
          ),
          const SizedBox(height: 12),
          Builder(builder: (context) {
            const addSentinel = '__add_location__';
            const noneSentinel = '__none__';
            final keys = [...ref.watch(allLocationKeysProvider)];
            if (_location != null && !keys.contains(_location)) {
              keys.add(_location!);
            }
            return DropdownButtonFormField<String>(
              initialValue: _location ?? noneSentinel,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l.addItemLocationLabel,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                    value: noneSentinel, child: Text(l.shoppingLocationNone)),
                for (final k in keys)
                  DropdownMenuItem(
                    value: k,
                    child: Row(children: [
                      Icon(locationIcon(k), size: 18),
                      const SizedBox(width: 8),
                      Text(locationLabelOf(l, k)),
                    ]),
                  ),
                DropdownMenuItem(
                  value: addSentinel,
                  child: Row(children: [
                    const Icon(Icons.add, size: 18),
                    const SizedBox(width: 8),
                    Text(l.addItemAddLocation),
                  ]),
                ),
              ],
              onChanged: (v) {
                if (v == null) return;
                if (v == addSentinel) {
                  _addLocationFlow();
                } else if (v == noneSentinel) {
                  setState(() => _location = null);
                } else {
                  setState(() => _location = v);
                }
              },
            );
          }),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today),
            title: Text(_expiryDate == null
                ? l.addItemExpiryLabel
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
          FilledButton(
            onPressed: _saving ? null : _add,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isEditing ? l.commonSave : l.commonAdd),
          ),
        ],
        ),
      ),
    );
  }
}

/// One matched pantry item in the "already have this?" warning. A filled dot for
/// a strong match, a hollow one for a merely-similar item, so the two read
/// differently at a glance.
class _PantryHit extends StatelessWidget {
  final String name;
  final bool strong;
  const _PantryHit({required this.name, required this.strong});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(strong ? Icons.check_circle : Icons.circle_outlined,
              size: 16, color: strong ? scheme.primary : scheme.outline),
          const SizedBox(width: 8),
          Expanded(child: Text(name)),
        ],
      ),
    );
  }
}
