import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../providers/auth_providers.dart';
import '../../models/inventory_item.dart';
import '../../models/shopping_item.dart';

/// Adds a pantry item to the shopping list, carrying its name, quantity and
/// store. Shows a snackbar with Undo. Shared by the pantry-item action and the
/// Home "Running low?" flow so both behave identically.
Future<void> sendItemToShopping(
  BuildContext context,
  WidgetRef ref,
  InventoryItem item,
) async {
  final householdId = ref.read(householdIdProvider);
  final uid = ref.read(authStateProvider).valueOrNull?.uid;
  if (householdId == null || uid == null) return;

  final svc = ref.read(firestoreServiceProvider);
  final shoppingItem = ShoppingItem(
    id: const Uuid().v4(),
    name: item.name,
    store: item.store,
    quantity: item.quantity,
    checked: false,
    addedAt: DateTime.now(),
    addedBy: uid,
  );
  await svc.addShoppingItem(householdId, shoppingItem);

  if (context.mounted) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Added "${item.name}" to shopping list'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => svc.deleteShoppingItem(householdId, shoppingItem.id),
        ),
      ),
    );
  }
}
