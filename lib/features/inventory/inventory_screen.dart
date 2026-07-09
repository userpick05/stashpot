import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/providers/inventory_providers.dart';
import '../../core/utils/category_icons.dart';
import '../../core/utils/shopping_actions.dart';
import '../../core/widgets/swipe_to_delete.dart';
import '../../models/inventory_item.dart';
import 'inventory_item_card.dart';
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
  List<InventoryItem> _filter(List<InventoryItem> items) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((i) {
      return i.name.toLowerCase().contains(q) ||
          locationLabel(i.location).toLowerCase().contains(q) ||
          i.category.label.toLowerCase().contains(q);
    }).toList();
  }

  // Ordered, non-empty sections for the chosen grouping. [locationKeys] is the
  // ordered set of locations to show when grouping by location (built-ins +
  // custom + any orphan keys still present on items).
  List<({String label, IconData icon, List<InventoryItem> items})> _sections(
    List<InventoryItem> items,
    InventoryGroupBy groupBy,
    List<String> locationKeys,
  ) {
    final result = <({String label, IconData icon, List<InventoryItem> items})>[];
    if (groupBy == InventoryGroupBy.location) {
      for (final key in locationKeys) {
        final group = items.where((i) => i.location == key).toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        if (group.isNotEmpty) {
          result.add((label: locationLabel(key), icon: locationIcon(key), items: group));
        }
      }
    } else {
      final order = [...kPickableCategories, ItemCategory.produce];
      for (final cat in order) {
        final group = items.where((i) => i.category == cat).toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        if (group.isNotEmpty) {
          result.add((label: cat.label, icon: categoryIcon(cat), items: group));
        }
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final inventory = ref.watch(inventoryProvider);
    final expiring = ref.watch(expiringItemsProvider);
    final groupBy = ref.watch(inventoryGroupByProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pantry'),
        actions: [
          PopupMenuButton<InventoryGroupBy>(
            icon: const Icon(Icons.sort),
            tooltip: 'Group by',
            initialValue: groupBy,
            onSelected: (v) => ref.read(inventoryGroupByProvider.notifier).state = v,
            itemBuilder: (_) => const [
              PopupMenuItem(value: InventoryGroupBy.location, child: Text('Group by location')),
              PopupMenuItem(value: InventoryGroupBy.category, child: Text('Group by category')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
      body: inventory.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (allItems) {
          if (allItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.kitchen_outlined, size: 80, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('Your pantry is empty', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text('Tap + to add your first item'),
                ],
              ),
            );
          }

          final items = _filter(allItems);
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
          final sections = _sections(items, groupBy, locationKeys);
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
                      '${expiring.length} item${expiring.length == 1 ? '' : 's'} expiring soon or expired',
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
                  Text('No items match "${_searchCtrl.text}"',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ));
          }

          for (final section in sections) {
            children.add(Padding(
              key: ValueKey('hdr-${section.label}'),
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
                      ? item.category.label
                      : locationLabel(item.location),
                  onTap: () => context.push('/inventory/edit', extra: item),
                  onTapQuantity: () => showQuantityEditSheet(context, ref, item),
                  onAddToShopping: () => sendItemToShopping(context, ref, item),
                  onRemoveToShopping: () async {
                    final hid = ref.read(householdIdProvider);
                    await sendItemToShopping(context, ref, item);
                    if (hid != null) {
                      await ref.read(firestoreServiceProvider).deleteItem(hid, item.id);
                    }
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
                    hintText: 'Search pantry…',
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
        label: const Text('Add item'),
      ),
    );
  }
}
