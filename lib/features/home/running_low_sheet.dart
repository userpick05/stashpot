import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/inventory_providers.dart';
import '../../core/utils/category_icons.dart';
import '../../core/utils/labels.dart';
import '../../l10n/app_localizations.dart';
import '../../models/inventory_item.dart';

/// What the "Running low?" sheet was closed with: either an existing pantry
/// item, or a free-text name for something that isn't in the pantry yet.
class RunningLowPick {
  final InventoryItem? item;
  final String? newName;
  const RunningLowPick.item(InventoryItem this.item) : newName = null;
  const RunningLowPick.newName(String this.newName) : item = null;
}

/// Quick "running low?" flow: search the pantry and tap an item, or — if
/// nothing matches — add what you typed straight to the shopping list.
/// Returns the pick (or null if dismissed). The caller adds it to the
/// shopping list AFTER this sheet has fully closed — showing the snackbar
/// while the sheet is still animating away leaves it stuck on screen.
Future<RunningLowPick?> showRunningLowSheet(BuildContext context) {
  return showModalBottomSheet<RunningLowPick>(
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
    final l = AppLocalizations.of(context);
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
                    Text(l.runningLowTitle,
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
                    hintText: l.runningLowSearchHint,
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          items.isEmpty
                              ? l.runningLowPantryEmpty
                              : l.shoppingNoMatches(_searchCtrl.text),
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.outline),
                        ),
                        if (q.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            icon: const Icon(Icons.add_shopping_cart),
                            label: Text(
                                l.runningLowAddToList(_searchCtrl.text.trim())),
                            onPressed: () => Navigator.of(context)
                                .pop(RunningLowPick.newName(_searchCtrl.text.trim())),
                          ),
                        ],
                      ],
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
    final l = AppLocalizations.of(context);
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
      subtitle: Text('$qty ${unitLabelOf(l, item.unit)}'
          '  ·  ${locationLabelOf(l, item.location)}'),
      trailing: const Icon(Icons.add_shopping_cart),
      // Just return the picked item; the Home screen adds it once we're closed.
      onTap: () => Navigator.of(context).pop(RunningLowPick.item(item)),
    );
  }
}
