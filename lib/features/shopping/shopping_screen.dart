import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/providers/inventory_providers.dart';
import '../../core/utils/category_guess.dart';
import '../../core/widgets/swipe_to_delete.dart';
import '../../l10n/app_localizations.dart';
import '../../models/inventory_item.dart';
import '../../models/shopping_item.dart';
import 'add_shopping_item_sheet.dart';
import 'reorder_screen.dart';

class ShoppingScreen extends ConsumerWidget {
  const ShoppingScreen({super.key});

  // Ask what to do when a checked item is already in the pantry.
  // Returns 'add' (merge quantity), 'skip', or null (dismissed → leave it).
  Future<String?> _askDuplicateChoice(BuildContext context, String name) {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final l = AppLocalizations.of(ctx);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.shoppingDupPantryTitle(name),
                  style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(l.shoppingDupPantryBody),
              const SizedBox(height: 20),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, 'skip'),
                    child: Text(l.commonSkip),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    onPressed: () => Navigator.pop(ctx, 'add'),
                    label: Text(l.shoppingAddQuantity),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Turn checked-off shopping items into pantry items. For each item already in
  // the pantry, ask whether to skip it or add its quantity to the existing one.
  // Undo restores the shopping items and reverses any pantry changes.
  Future<void> _moveCheckedToPantry(
    BuildContext context,
    WidgetRef ref,
    String householdId,
    List<ShoppingItem> checked,
  ) async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;
    final svc = ref.read(firestoreServiceProvider);
    final inventory = ref.read(inventoryProvider).valueOrNull ?? [];
    final messenger = ScaffoldMessenger.of(context);
    final l = AppLocalizations.of(context);

    final createdIds = <String>[]; // new pantry items → delete on undo
    final originalById = <String, InventoryItem>{}; // merged → restore on undo
    final runningQty = <String, double>{}; // id → qty after merges (stale-safe)
    final removedShopping = <ShoppingItem>[]; // → restore on undo
    var addedCount = 0, mergedCount = 0, skippedCount = 0;

    for (final s in checked) {
      // Same name AND same note counts as the same item — so two products with
      // the same name but different sizes (kept in the note, e.g. "1 gal" vs
      // "24-pack") stay separate instead of being merged.
      final sNote = (s.note ?? '').trim().toLowerCase();
      InventoryItem? existing;
      for (final i in inventory) {
        if (i.name.trim().toLowerCase() == s.name.trim().toLowerCase() &&
            (i.notes ?? '').trim().toLowerCase() == sNote) {
          existing = i;
          break;
        }
      }

      if (existing != null) {
        if (!context.mounted) break;
        final choice = await _askDuplicateChoice(context, s.name);
        if (choice == null) continue; // dismissed → leave this item as-is
        if (choice == 'add') {
          originalById.putIfAbsent(existing.id, () => existing!);
          final base = runningQty[existing.id] ?? existing.quantity;
          final newQty = base + s.quantity;
          runningQty[existing.id] = newQty;
          await svc.updateItem(
              householdId, existing.copyWith(quantity: newQty));
          mergedCount++;
        } else {
          skippedCount++;
        }
      } else {
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
            location: kDefaultLocationKey,
            store: s.store,
            notes: s.note, // carry the note (e.g. size) into the pantry
            addedAt: DateTime.now(),
            addedBy: uid,
          ),
        );
        addedCount++;
      }
      await svc.deleteShoppingItem(householdId, s.id);
      removedShopping.add(s);
    }

    if (removedShopping.isEmpty) return; // nothing processed

    final parts = <String>[];
    if (addedCount > 0) parts.add(l.shoppingSummaryAdded(addedCount));
    if (mergedCount > 0) parts.add(l.shoppingSummaryMerged(mergedCount));
    if (skippedCount > 0) parts.add(l.shoppingSummarySkipped(skippedCount));

    // Show after the current frame so it isn't shown mid sheet-close (which can
    // leave a snackbar stuck on screen).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      messenger.clearSnackBars();
      final controller = messenger.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          content: Text(l.shoppingPantryUpdated(
              parts.join(l.shoppingSummarySeparator))),
          action: SnackBarAction(
            label: l.commonUndo,
            onPressed: () {
              for (final id in createdIds) {
                svc.deleteItem(householdId, id);
              }
              for (final it in originalById.values) {
                svc.updateItem(householdId, it);
              }
              for (final s in removedShopping) {
                svc.updateShoppingItem(householdId, s);
              }
            },
          ),
        ),
      );
      Future.delayed(const Duration(seconds: 4, milliseconds: 300), controller.close);
    });
  }

  // Internal sentinel for the "no store" bucket — never shown as-is and never
  // stored; the header text goes through l.noStoreGroup.
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
    final l = AppLocalizations.of(context);
    final shopping = ref.watch(shoppingProvider);
    final householdId = ref.watch(householdIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.navShopping),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: l.shoppingReorderTooltip,
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
                tooltip: l.shoppingMoveToPantryTooltip,
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
                tooltip: l.shoppingClearCheckedTooltip,
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
                                  l.shoppingClearedCount(checked.length)),
                              action: SnackBarAction(
                                label: l.commonUndo,
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
        error: (e, _) => Center(child: Text(l.commonError('$e'))),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 80, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(l.shoppingEmptyTitle,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(l.shoppingEmptyHint),
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
                        store == _noStoreKey ? l.noStoreGroup : store,
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
        label: Text(l.commonAdd),
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
