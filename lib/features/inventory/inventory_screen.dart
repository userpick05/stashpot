import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/providers/inventory_providers.dart';
import '../../core/utils/category_icons.dart';
import '../../core/utils/labels.dart';
import '../../core/utils/shopping_actions.dart';
import '../../core/widgets/swipe_to_delete.dart';
import '../../l10n/app_localizations.dart';
import '../../models/inventory_item.dart';
import 'inventory_item_card.dart';
import 'move_to_shopping_sheet.dart';
import 'quantity_edit_sheet.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Filter by name, location label, or category label (case-insensitive).
  // Matches the LOCALIZED labels, so searching "冰箱" works in Chinese and
  // "Fridge" works in English.
  List<InventoryItem> _filter(List<InventoryItem> items, AppLocalizations l) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((i) {
      return i.name.toLowerCase().contains(q) ||
          locationLabelOf(l, i.location).toLowerCase().contains(q) ||
          categoryLabelOf(l, i.category).toLowerCase().contains(q) ||
          (i.store?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  // Ordered, non-empty sections for the chosen grouping. [locationKeys] is the
  // ordered set of locations to show when grouping by location (built-ins +
  // custom + any orphan keys still present on items).
  List<({String id, String label, IconData icon, List<InventoryItem> items})> _sections(
    List<InventoryItem> items,
    InventoryGroupBy groupBy,
    List<String> locationKeys,
    AppLocalizations l,
  ) {
    final result = <({String id, String label, IconData icon, List<InventoryItem> items})>[];
    if (groupBy == InventoryGroupBy.location) {
      for (final key in locationKeys) {
        final group = items.where((i) => i.location == key).toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        if (group.isNotEmpty) {
          result.add((
            id: 'loc-$key',
            label: locationLabelOf(l, key),
            icon: locationIcon(key),
            items: group
          ));
        }
      }
    } else if (groupBy == InventoryGroupBy.store) {
      // Group by the store each item is bought at; no-store items go last.
      // This bucket label is display-only — nothing is stored under it.
      final noStore = l.noStoreGroup;
      final byStore = <String, List<InventoryItem>>{};
      for (final i in items) {
        final key = (i.store != null && i.store!.trim().isNotEmpty)
            ? i.store!.trim()
            : noStore;
        byStore.putIfAbsent(key, () => []).add(i);
      }
      final keys = byStore.keys.toList()
        ..sort((a, b) {
          if (a == noStore) return 1;
          if (b == noStore) return -1;
          return a.toLowerCase().compareTo(b.toLowerCase());
        });
      for (final key in keys) {
        final group = byStore[key]!
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        result.add((
          id: 'store-$key',
          label: key,
          icon: Icons.storefront,
          items: group
        ));
      }
    } else {
      final order = [...kPickableCategories, ItemCategory.produce];
      for (final cat in order) {
        final group = items.where((i) => i.category == cat).toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        if (group.isNotEmpty) {
          result.add((
            id: 'cat-${cat.name}',
            label: categoryLabelOf(l, cat),
            icon: categoryIcon(cat),
            items: group
          ));
        }
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final inventory = ref.watch(inventoryProvider);
    final expiring = ref.watch(expiringItemsProvider);
    final groupBy = ref.watch(inventoryGroupByProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.navPantry),
        actions: [
          PopupMenuButton<InventoryGroupBy>(
            icon: const Icon(Icons.sort),
            tooltip: l.pantryGroupByTooltip,
            initialValue: groupBy,
            onSelected: (v) => ref.read(inventoryGroupByProvider.notifier).state = v,
            itemBuilder: (_) => [
              PopupMenuItem(
                  value: InventoryGroupBy.location, child: Text(l.pantryGroupByLocation)),
              PopupMenuItem(
                  value: InventoryGroupBy.category, child: Text(l.pantryGroupByCategory)),
              PopupMenuItem(value: InventoryGroupBy.store, child: Text(l.pantryGroupByStore)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l.settingsSignOut,
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
      body: inventory.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l.commonError(e.toString()))),
        data: (allItems) {
          if (allItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.kitchen_outlined, size: 80, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(l.pantryEmptyTitle, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(l.pantryEmptySubtitle),
                ],
              ),
            );
          }

          final items = _filter(allItems, l);
          // Location keys to show: the standard ordered set, plus any orphan
          // location still present on an item (e.g. a since-deleted custom one).
          final locationKeys = [
            ...ref.watch(allLocationKeysProvider),
            ...{
              for (final i in allItems)
                if (!ref.watch(allLocationKeysProvider).contains(i.location))
                  i.location
            },
          ];
          final sections = _sections(items, groupBy, locationKeys, l);
          final children = <Widget>[];

          // Only show the expiry banner when not actively searching.
          if (_query.isEmpty && expiring.isNotEmpty) {
            children.add(Container(
              key: const ValueKey('expiry-banner'),
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.pantryExpiringBanner(expiring.length),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ));
          }

          if (sections.isEmpty) {
            children.add(Padding(
              key: const ValueKey('no-matches'),
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 64, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 12),
                  Text(l.pantryNoMatches(_searchCtrl.text),
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ));
          }

          for (final section in sections) {
            children.add(Padding(
              key: ValueKey('hdr-${section.id}'),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Row(
                children: [
                  Icon(section.icon, size: 20, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(section.label,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(width: 6),
                  Text('(${section.items.length})', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ));
            for (final item in section.items) {
              children.add(SwipeToDelete(
                key: ValueKey(item.id),
                itemId: item.id,
                label: item.name,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                onDelete: () async {
                  final hid = ref.read(householdIdProvider);
                  if (hid != null) {
                    await ref.read(firestoreServiceProvider).deleteItem(hid, item.id);
                  }
                },
                child: InventoryItemCard(
                  item: item,
                  secondaryLabel: groupBy == InventoryGroupBy.location
                      ? categoryLabelOf(l, item.category)
                      : locationLabelOf(l, item.location),
                  onTap: () => context.push('/inventory/edit', extra: item),
                  onTapQuantity: () => showQuantityEditSheet(context, ref, item),
                  onAddToShopping: () => sendItemToShopping(context, ref, item),
                  onRemoveToShopping: () async {
                    final moveQty = await showMoveToShoppingSheet(context, item);
                    if (moveQty == null || !context.mounted) return;
                    await moveItemToShopping(context, ref, item, moveQty);
                  },
                ),
              ));
            }
          }
          children.add(const SizedBox(key: ValueKey('tail-spacer'), height: 88));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: l.pantrySearchHint,
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
              Expanded(child: ListView(children: children)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/inventory/add'),
        icon: const Icon(Icons.add),
        label: Text(l.pantryAddItemFab),
      ),
    );
  }
}
