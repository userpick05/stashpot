import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/inventory_providers.dart';
import '../../core/utils/category_icons.dart';
import '../../models/inventory_item.dart';

/// Quick "running low?" flow: search the pantry and tap an item. Returns the
/// chosen item (or null if dismissed). The caller adds it to the shopping list
/// AFTER this sheet has fully closed — showing the snackbar while the sheet is
/// still animating away leaves it stuck on screen.
Future<InventoryItem?> showRunningLowSheet(BuildContext context) {
  return showModalBottomSheet<InventoryItem>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _RunningLowSheet(),
  );
}

class _RunningLowSheet extends ConsumerStatefulWidget {
  const _RunningLowSheet();

  @override
  ConsumerState<_RunningLowSheet> createState() => _RunningLowSheetState();
}

class _RunningLowSheetState extends ConsumerState<_RunningLowSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(inventoryProvider).valueOrNull ?? [];
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? items
        : items.where((i) => i.name.toLowerCase().contains(q)).toList();
    filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (context, scrollController) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Row(
                  children: [
                    Icon(Icons.remove_shopping_cart,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 10),
                    Text('Running low?',
                        style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Find an item to add to the list…',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                ),
              ),
              if (filtered.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      items.isEmpty
                          ? 'Your pantry is empty'
                          : 'No items match "${_searchCtrl.text}"',
                      style: TextStyle(color: Theme.of(context).colorScheme.outline),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final item = filtered[i];
                      return _RunningLowTile(item: item);
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RunningLowTile extends StatelessWidget {
  final InventoryItem item;
  const _RunningLowTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final qty = item.quantity % 1 == 0
        ? item.quantity.toInt().toString()
        : item.quantity.toString();
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(categoryIcon(item.category),
            color: Theme.of(context).colorScheme.onPrimaryContainer),
      ),
      title: Text(item.name),
      subtitle: Text('$qty ${item.unit}  ·  ${locationLabel(item.location)}'),
      trailing: const Icon(Icons.add_shopping_cart),
      // Just return the picked item; the Home screen adds it once we're closed.
      onTap: () => Navigator.of(context).pop(item),
    );
  }
}
