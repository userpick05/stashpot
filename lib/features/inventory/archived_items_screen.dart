import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/auth_providers.dart';
import '../../core/providers/inventory_providers.dart';
import '../../core/utils/category_icons.dart';
import '../../core/utils/shopping_actions.dart';
import '../../l10n/app_localizations.dart';
import '../../models/inventory_item.dart';

/// The archive: items kept but out of stock. Restore one back to the Stash List,
/// add it to the shopping list, or delete it for good.
class ArchivedItemsScreen extends ConsumerWidget {
  const ArchivedItemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final archived = ref.watch(archivedInventoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.archivedTitle)),
      body: archived.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l.commonError(e.toString()))),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.archive_outlined,
                        size: 72, color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 16),
                    Text(l.archivedEmptyTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(l.archivedEmptySubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.outline)),
                  ],
                ),
              ),
            );
          }
          final sorted = [...items]
            ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sorted.length,
            itemBuilder: (context, i) => _ArchivedRow(item: sorted[i]),
          );
        },
      ),
    );
  }
}

class _ArchivedRow extends ConsumerWidget {
  final InventoryItem item;
  const _ArchivedRow({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final svc = ref.read(firestoreServiceProvider);
    final hid = ref.read(householdIdProvider);
    final note = (item.notes ?? '').trim();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.surfaceContainerHighest,
          child: Icon(categoryIconFor(item.category, item.customCategory),
              color: scheme.onSurfaceVariant),
        ),
        title: Text(item.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: note.isEmpty ? null : Text(note, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add_shopping_cart),
              tooltip: l.archivedAddToShopping,
              onPressed: () => sendItemToShopping(context, ref, item),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (v) async {
                if (hid == null) return;
                if (v == 'restore') {
                  await svc.setItemArchived(hid, item.id, false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(l.archivedRestoredSnack(item.name))));
                  }
                } else if (v == 'delete') {
                  await svc.deleteItem(hid, item.id);
                  if (context.mounted) {
                    final messenger = ScaffoldMessenger.of(context);
                    messenger
                      ..clearSnackBars()
                      ..showSnackBar(SnackBar(
                        content: Text(l.archivedDeletedSnack(item.name)),
                        action: SnackBarAction(
                          label: l.commonUndo,
                          onPressed: () => svc.addItem(hid, item),
                        ),
                      ));
                  }
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'restore',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.unarchive_outlined),
                    title: Text(l.archivedRestore),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.delete_outline, color: Colors.red),
                    title: Text(l.commonDelete),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
