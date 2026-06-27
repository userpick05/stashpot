import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/providers/inventory_providers.dart';
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

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _storeCtrl.text = e.store ?? '';
      _noteCtrl.text = e.note ?? '';
      _quantity = e.quantity.round().clamp(1, 999);
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

  Future<void> _add() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final householdId = ref.read(householdIdProvider);
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (householdId == null || uid == null) return;

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
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_isEditing ? 'Edit item' : 'Add to shopping list',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            autofocus: !_isEditing,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Item *',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _add(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _storeCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Store (optional)',
                    prefixIcon: const Icon(Icons.storefront),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_drop_down),
                      tooltip: 'Pick from saved stores',
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
              const Text('Quantity'),
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
            decoration: const InputDecoration(
              labelText: 'Note (optional) e.g. "the big box"',
              border: OutlineInputBorder(),
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
                : Text(_isEditing ? 'Save changes' : 'Add'),
          ),
        ],
      ),
    );
  }
}
