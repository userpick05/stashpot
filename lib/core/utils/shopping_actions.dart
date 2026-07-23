import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../providers/auth_providers.dart';
import '../providers/inventory_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../models/inventory_item.dart';
import '../../models/shopping_item.dart';

/// If [name] already matches an item on the shopping list, asks whether to
/// skip it or add it anyway. Returns true to proceed with the add, false to
/// skip. When there's no duplicate (or the caller didn't ask to check),
/// returns true immediately without prompting.
Future<bool> _confirmIfDuplicate(
  BuildContext context,
  WidgetRef ref,
  String name,
  bool shouldCheck,
) async {
  if (!shouldCheck) return true;
  final existing = ref.read(shoppingProvider).valueOrNull ?? [];
  final isDuplicate = existing
      .any((s) => s.name.trim().toLowerCase() == name.trim().toLowerCase());
  if (!isDuplicate) return true;
  if (!context.mounted) return false;

  final choice = await showModalBottomSheet<String>(
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
            Text(l.shoppingDupListTitle(name),
                style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(l.shoppingDupListBody),
            const SizedBox(height: 20),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, 'skip'),
                  child: Text(l.commonSkip),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, 'add'),
                  child: Text(l.shoppingAddAnyway),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
  return choice == 'add';
}

/// Adds a pantry item to the shopping list, carrying its name, quantity, store
/// and note (e.g. size). Shows a snackbar with Undo. Shared by the pantry-item
/// action and the Home "Running low?" flow so both behave identically.
///
/// When [confirmIfDuplicate] is true, and an item with the same name is
/// already on the shopping list, asks whether to skip it or add it anyway.
Future<void> sendItemToShopping(
  BuildContext context,
  WidgetRef ref,
  InventoryItem item, {
  bool confirmIfDuplicate = false,
}) async {
  final householdId = ref.read(householdIdProvider);
  final uid = ref.read(authStateProvider).valueOrNull?.uid;
  if (householdId == null || uid == null) return;

  final proceed =
      await _confirmIfDuplicate(context, ref, item.name, confirmIfDuplicate);
  if (!proceed) return;

  final svc = ref.read(firestoreServiceProvider);
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  final l = AppLocalizations.of(context);

  final shoppingItem = ShoppingItem(
    id: const Uuid().v4(),
    name: item.name,
    store: item.store,
    quantity: item.quantity,
    note: item.notes, // carry the note (e.g. size) over to the shopping list
    checked: false,
    addedAt: DateTime.now(),
    addedBy: uid,
  );
  await svc.addShoppingItem(householdId, shoppingItem);

  // Show on the next frame, not in the middle of this route-change/rebuild.
  // When a snackbar is shown mid-transition its entrance animation can skip the
  // "completed" callback that arms the auto-dismiss timer, so it sticks forever.
  // We also close it on an explicit timer as a backstop, so dismissal never
  // depends on that fragile internal timer.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    messenger.hideCurrentSnackBar();
    final controller = messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        content: Text(l.shoppingAddedToList(item.name)),
        action: SnackBarAction(
          label: l.commonUndo,
          onPressed: () => svc.deleteShoppingItem(householdId, shoppingItem.id),
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 4, milliseconds: 300), controller.close);
  });
}

/// Moves [moveQty] of a pantry [item] to the shopping list. If [moveQty] is at
/// or above the item's quantity, the pantry item is removed entirely (the old
/// "remove & add to shopping" behaviour); otherwise the pantry item stays and
/// its quantity is reduced by [moveQty]. Carries the store and note over, and
/// shows a snackbar whose Undo reverses BOTH sides — it deletes the new
/// shopping item and restores the pantry item to exactly how it was.
Future<void> moveItemToShopping(
  BuildContext context,
  WidgetRef ref,
  InventoryItem item,
  double moveQty,
) async {
  if (moveQty <= 0) return;
  final householdId = ref.read(householdIdProvider);
  final uid = ref.read(authStateProvider).valueOrNull?.uid;
  if (householdId == null || uid == null) return;

  final svc = ref.read(firestoreServiceProvider);
  final messenger = ScaffoldMessenger.of(context);
  final l = AppLocalizations.of(context);

  final movingAll = moveQty >= item.quantity;
  final movedQty = movingAll ? item.quantity : moveQty;

  final shoppingItem = ShoppingItem(
    id: const Uuid().v4(),
    name: item.name,
    store: item.store,
    quantity: movedQty,
    note: item.notes,
    checked: false,
    addedAt: DateTime.now(),
    addedBy: uid,
  );
  await svc.addShoppingItem(householdId, shoppingItem);

  if (movingAll) {
    await svc.deleteItem(householdId, item.id);
  } else {
    await svc
        .updateItem(householdId, item.copyWith(quantity: item.quantity - moveQty));
  }

  final label = shoppingItem.quantityLabel;
  final msg = movingAll
      ? l.shoppingMovedToList(item.name)
      : l.shoppingMovedQtyToList(label, item.name);

  // Restoring the pantry item to its original state works the same whether we
  // deleted it (recreates the doc) or reduced it (overwrites the reduced doc),
  // because addItem does a set() on the item's own id with its original data.
  Future<void> undo() async {
    await svc.deleteShoppingItem(householdId, shoppingItem.id);
    await svc.addItem(householdId, item);
  }

  // Shown on the next frame with a backstop close, for the same reason as
  // sendItemToShopping — a snackbar shown mid rebuild can otherwise stick.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    messenger.hideCurrentSnackBar();
    final controller = messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        content: Text(msg),
        action: SnackBarAction(label: l.commonUndo, onPressed: undo),
      ),
    );
    Future.delayed(const Duration(seconds: 4, milliseconds: 300), controller.close);
  });
}

/// Adds a free-text item (not yet in the pantry) straight to the shopping
/// list — used by the Home "Running low?" search when nothing matches.
/// Same duplicate-check + snackbar-with-Undo behavior as [sendItemToShopping].
Future<void> addNameToShopping(
  BuildContext context,
  WidgetRef ref,
  String name, {
  bool confirmIfDuplicate = false,
}) async {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return;
  final householdId = ref.read(householdIdProvider);
  final uid = ref.read(authStateProvider).valueOrNull?.uid;
  if (householdId == null || uid == null) return;

  final proceed =
      await _confirmIfDuplicate(context, ref, trimmed, confirmIfDuplicate);
  if (!proceed) return;

  final svc = ref.read(firestoreServiceProvider);
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  final l = AppLocalizations.of(context);

  final shoppingItem = ShoppingItem(
    id: const Uuid().v4(),
    name: trimmed,
    checked: false,
    addedAt: DateTime.now(),
    addedBy: uid,
  );
  await svc.addShoppingItem(householdId, shoppingItem);

  WidgetsBinding.instance.addPostFrameCallback((_) {
    messenger.hideCurrentSnackBar();
    final controller = messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        content: Text(l.shoppingAddedToList(trimmed)),
        action: SnackBarAction(
          label: l.commonUndo,
          onPressed: () => svc.deleteShoppingItem(householdId, shoppingItem.id),
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 4, milliseconds: 300), controller.close);
  });
}
