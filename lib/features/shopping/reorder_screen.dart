import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/providers/inventory_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../models/catalog_item.dart';
import '../../models/shopping_item.dart';

/// Browse previously-added items (the catalog), search them, and tap to add
/// back onto the shopping list. Grouped by store with collapsible sections.
class ReorderScreen extends ConsumerStatefulWidget {
  const ReorderScreen({super.key});

  @override
  ConsumerState<ReorderScreen> createState() => _ReorderScreenState();
}

class _ReorderScreenState extends ConsumerState<ReorderScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  // Internal sentinel for the "no store" bucket — never shown as-is and never
  // stored; the section title goes through l.noStoreGroup.
  static const _noStoreKey = 'Other / no store';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Map<String, List<CatalogItem>> _group(List<CatalogItem> items) {
    final groups = <String, List<CatalogItem>>{};
    for (final item in items) {
      final key = (item.store != null && item.store!.trim().isNotEmpty)
          ? item.store!
          : _noStoreKey;
      groups.putIfAbsent(key, () => []).add(item);
    }
    for (final list in groups.values) {
      // Most-frequently added first, then alphabetical.
      list.sort((a, b) {
        if (a.timesAdded != b.timesAdded) {
          return b.timesAdded.compareTo(a.timesAdded);
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    }
    return groups;
  }

  List<String> _sortedKeys(Map<String, List<CatalogItem>> groups) {
    return groups.keys.toList()
      ..sort((a, b) {
        if (a == _noStoreKey) return 1;
        if (b == _noStoreKey) return -1;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });
  }

  Future<void> _addToList(CatalogItem c) async {
    final householdId = ref.read(householdIdProvider);
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (householdId == null || uid == null) return;
    await ref.read(firestoreServiceProvider).addShoppingItem(
          householdId,
          ShoppingItem(
            id: const Uuid().v4(),
            name: c.name,
            store: c.store,
            quantity: c.quantity,
            note: c.note,
            checked: false,
            addedAt: DateTime.now(),
            addedBy: uid,
          ),
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).reorderAdded(c.name)),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final catalog = ref.watch(catalogProvider);
    final householdId = ref.watch(householdIdProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.reorderTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: l.reorderSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: catalog.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(l.commonError('$e'))),
              data: (all) {
                final filtered = _query.isEmpty
                    ? all
                    : all
                        .where((c) => c.name.toLowerCase().contains(_query))
                        .toList();

                if (all.isEmpty) {
                  return _Empty(
                    icon: Icons.history,
                    text: l.reorderEmpty,
                  );
                }
                if (filtered.isEmpty) {
                  return _Empty(
                    icon: Icons.search_off,
                    text: l.shoppingNoMatches(_searchCtrl.text),
                  );
                }

                final groups = _group(filtered);
                final keys = _sortedKeys(groups);

                return ListView(
                  children: [
                    for (final store in keys)
                      _StoreSection(
                        store: store,
                        storeLabel: store == _noStoreKey ? l.noStoreGroup : store,
                        items: groups[store]!,
                        // Expand sections when searching so matches are visible.
                        initiallyExpanded: _query.isNotEmpty,
                        onAdd: _addToList,
                        onDelete: householdId == null
                            ? null
                            : (c) => ref
                                .read(firestoreServiceProvider)
                                .deleteCatalogItem(householdId, c.id),
                      ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreSection extends StatelessWidget {
  /// Raw grouping key (may be the internal "no store" sentinel) — used for the
  /// storage key only.
  final String store;

  /// What the user actually sees for this section.
  final String storeLabel;
  final List<CatalogItem> items;
  final bool initiallyExpanded;
  final Future<void> Function(CatalogItem) onAdd;
  final void Function(CatalogItem)? onDelete;

  const _StoreSection({
    required this.store,
    required this.storeLabel,
    required this.items,
    required this.initiallyExpanded,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ExpansionTile(
      // Re-key so expansion state follows search changes.
      key: PageStorageKey('$store-$initiallyExpanded-${items.length}'),
      initiallyExpanded: initiallyExpanded,
      leading: Icon(Icons.storefront, color: Theme.of(context).colorScheme.primary),
      title: Text(storeLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(l.reorderItemCount(items.length)),
      children: [
        for (final c in items)
          ListTile(
            contentPadding: const EdgeInsets.only(left: 32, right: 8),
            title: Text(c.name),
            subtitle: c.note != null ? Text(c.note!) : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: l.reorderForgetItem,
                    onPressed: () => onDelete!(c),
                  ),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l.commonAdd),
                  onPressed: () => onAdd(c),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Empty({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(text, textAlign: TextAlign.center),
            ),
          ],
        ),
      );
}
