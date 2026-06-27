import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/providers/inventory_providers.dart';
import '../../core/utils/category_guess.dart';
import '../../core/widgets/swipe_to_delete.dart';
import '../../models/inventory_item.dart';
import '../../models/shopping_item.dart';
import 'add_shopping_item_sheet.dart';
import 'reorder_screen.dart';

class ShoppingScreen extends ConsumerWidget {
  const ShoppingScreen({super.key});

  // Turn checked-off shopping items into pantry items, then remove them from
  // the list. Undo restores both sides.
  Future<void> _moveCheckedToPantry(
    BuildContext context,
    WidgetRef ref,
    String householdId,
    List<ShoppingItem> checked,
  ) async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;
    final svc = ref.read(firestoreServiceProvider);
    final createdIds = <String>[];
    for (final s in checked) {
      final id = const Uuid().v4();
      createdIds.add(id);
      await svc.addItem(
        householdId,
        InventoryItem(
          id: id,
          name: s.name,
          category: guessCategory(s.name) ?? ItemCategory.other,
          quantity: s.quantity,
          unit: 'item',
          location: ItemLocation.pantry,
          store: s.store,
          addedAt: DateTime.now(),
          addedBy: uid,
        ),
      );
      await svc.deleteShoppingItem(householdId, s.id);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Moved ${checked.length} item${checked.length == 1 ? '' : 's'} to pantry'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              for (final id in createdIds) {
                svc.deleteItem(householdId, id);
              }
              for (final s in checked) {
                svc.updateShoppingItem(householdId, s);
              }
            },
          ),
        ),
      );
    }
  }

  static const _noStoreKey = 'Other / no store';

  Map<String, List<ShoppingItem>> _groupByStore(List<ShoppingItem> items) {
    final groups = <String, List<ShoppingItem>>{};
    for (final item in items) {
      final key =
          (item.store != null && item.store!.trim().isNotEmpty) ? item.store! : _noStoreKey;
      groups.putIfAbsent(key, () => []).add(item);
    }
    // Within each store: unchecked first, then checked.
    for (final list in groups.values) {
      list.sort((a, b) {
        if (a.checked != b.checked) return a.checked ? 1 : -1;
        return a.addedAt.compareTo(b.addedAt);
      });
    }
    return groups;
  }

  List<String> _sortedStoreKeys(Map<String, List<ShoppingItem>> groups) {
    return groups.keys.toList()
      ..sort((a, b) {
        if (a == _noStoreKey) return 1;
        if (b == _noStoreKey) return -1;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopping = ref.watch(shoppingProvider);
    final householdId = ref.watch(householdIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping list'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Reorder previous items',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReorderScreen()),
            ),
          ),
          shopping.maybeWhen(
            data: (items) {
              final checked = items.where((i) => i.checked).toList();
              if (checked.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.move_to_inbox),
                tooltip: 'Move checked to pantry',
                onPressed: householdId == null
                    ? null
                    : () => _moveCheckedToPantry(context, ref, householdId, checked),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          shopping.maybeWhen(
            data: (items) {
              final checked = items.where((i) => i.checked).toList();
              if (checked.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_sweep),
                tooltip: 'Clear checked items',
                // Clear immediately with an Undo snackbar (no confirm dialog —
                // AlertDialogs black-screen via Impeller on some devices).
                onPressed: householdId == null
                    ? null
                    : () async {
                        final svc = ref.read(firestoreServiceProvider);
                        await svc.clearCheckedShopping(householdId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Cleared ${checked.length} checked item${checked.length == 1 ? '' : 's'}'),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () {
                                  for (final i in checked) {
                                    svc.addShoppingItem(householdId, i);
                                  }
                                },
                              ),
                            ),
                          );
                        }
                      },
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: shopping.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 80, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('Your shopping list is empty',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text('Tap + to add something to buy'),
                ],
              ),
            );
          }

          final groups = _groupByStore(items);
          final storeKeys = _sortedStoreKeys(groups);

          return ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              for (final store in storeKeys) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Row(
                    children: [
                      Icon(Icons.storefront,
                          size: 18, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        store,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('(${groups[store]!.length})',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                for (final item in groups[store]!)
                  _ShoppingTile(item: item, householdId: householdId),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: householdId == null
            ? null
            : () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (_) => const AddShoppingItemSheet(),
                ),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }
}

class _ShoppingTile extends ConsumerWidget {
  final ShoppingItem item;
  final String? householdId;
  const _ShoppingTile({required this.item, required this.householdId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.read(firestoreServiceProvider);
    return SwipeToDelete(
      key: ValueKey(item.id),
      itemId: item.id,
      label: item.name,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      onDelete: () async {
        if (householdId != null) await svc.deleteShoppingItem(householdId!, item.id);
      },
      child: ListTile(
        onTap: householdId == null
            ? null
            : () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (_) => AddShoppingItemSheet(existing: item),
                ),
        leading: Checkbox(
          value: item.checked,
          onChanged: householdId == null
              ? null
              : (v) => svc.setShoppingChecked(householdId!, item.id, v ?? false),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(
                  decoration: item.checked ? TextDecoration.lineThrough : null,
                  color:
                      item.checked ? Theme.of(context).colorScheme.outline : null,
                ),
              ),
            ),
            if (item.quantity > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('×${item.quantityLabel}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    )),
              ),
          ],
        ),
        subtitle: item.note != null ? Text(item.note!) : null,
      ),
    );
  }
}
