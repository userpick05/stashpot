import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/catalog_item.dart';
import '../../models/inventory_item.dart';
import '../../models/shopping_item.dart';
import 'auth_providers.dart';

// All items the household has, archived and not. Prefer [inventoryProvider]
// (active only) for the Stash List and pantry cross-checks.
final allInventoryProvider = StreamProvider<List<InventoryItem>>((ref) {
  final householdId = ref.watch(householdIdProvider);
  if (householdId == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).inventoryStream(householdId);
});

// Active (in-stock) items only — archived ones are out of stock, so they drop
// off the Stash List and out of every pantry/expiry/already-have check.
final inventoryProvider = Provider<AsyncValue<List<InventoryItem>>>((ref) {
  return ref
      .watch(allInventoryProvider)
      .whenData((items) => items.where((i) => !i.archived).toList());
});

// Archived items — kept but out of stock, surfaced in the Archived view and as
// quick-add options when building the shopping list.
final archivedInventoryProvider = Provider<AsyncValue<List<InventoryItem>>>((ref) {
  return ref
      .watch(allInventoryProvider)
      .whenData((items) => items.where((i) => i.archived).toList());
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

// Custom, user-created storage locations for the household (beyond the four
// built-ins). Just the custom names — built-ins are added on top in the UI.
final customLocationsProvider = StreamProvider<List<String>>((ref) {
  final householdId = ref.watch(householdIdProvider);
  if (householdId == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).locationsStream(householdId);
});

// The full ordered list of location keys to offer/show: built-ins first, then
// custom locations (alphabetical), de-duplicated.
final allLocationKeysProvider = Provider<List<String>>((ref) {
  final custom = ref.watch(customLocationsProvider).valueOrNull ?? const [];
  final seen = <String>{...kBuiltInLocationKeys};
  final result = <String>[...kBuiltInLocationKeys];
  for (final l in custom) {
    if (l.trim().isEmpty) continue;
    if (seen.add(l)) result.add(l);
  }
  return result;
});

// User-created units for the household (beyond the built-in ones), e.g. "dozen".
final customUnitsProvider = StreamProvider<List<String>>((ref) {
  final householdId = ref.watch(householdIdProvider);
  if (householdId == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).unitsStream(householdId);
});

// User-created food types for the household (beyond the built-in categories).
final customCategoriesProvider = StreamProvider<List<String>>((ref) {
  final householdId = ref.watch(householdIdProvider);
  if (householdId == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).categoriesStream(householdId);
});

// Catalog of previously-added items, for the reorder screen.
final catalogProvider = StreamProvider<List<CatalogItem>>((ref) {
  final householdId = ref.watch(householdIdProvider);
  if (householdId == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).catalogStream(householdId);
});

// How the pantry list is organized into sections.
enum InventoryGroupBy { location, category, store }

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
