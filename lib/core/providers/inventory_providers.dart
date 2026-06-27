import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/catalog_item.dart';
import '../../models/inventory_item.dart';
import '../../models/shopping_item.dart';
import 'auth_providers.dart';

final inventoryProvider = StreamProvider<List<InventoryItem>>((ref) {
  final householdId = ref.watch(householdIdProvider);
  if (householdId == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).inventoryStream(householdId);
});

// Shared, per-household list of stores the user buys from.
final storesProvider = StreamProvider<List<String>>((ref) {
  final householdId = ref.watch(householdIdProvider);
  if (householdId == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).storesStream(householdId);
});

// Shared shopping list for the household.
final shoppingProvider = StreamProvider<List<ShoppingItem>>((ref) {
  final householdId = ref.watch(householdIdProvider);
  if (householdId == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).shoppingStream(householdId);
});

// Catalog of previously-added items, for the reorder screen.
final catalogProvider = StreamProvider<List<CatalogItem>>((ref) {
  final householdId = ref.watch(householdIdProvider);
  if (householdId == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).catalogStream(householdId);
});

// How the pantry list is organized into sections.
enum InventoryGroupBy { location, category }

final inventoryGroupByProvider =
    StateProvider<InventoryGroupBy>((_) => InventoryGroupBy.location);

// Expiring items: expired + expires within 7 days
final expiringItemsProvider = Provider<List<InventoryItem>>((ref) {
  final items = ref.watch(inventoryProvider).valueOrNull ?? [];
  return items
      .where((i) => i.expiryDate != null && (i.isExpired || i.expiresThisWeek || i.expiresSoon))
      .toList()
    ..sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));
});
