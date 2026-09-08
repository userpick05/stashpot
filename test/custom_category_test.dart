import 'package:flutter_test/flutter_test.dart';
import 'package:stashpot/models/inventory_item.dart';
import 'package:stashpot/models/shopping_item.dart';

/// Custom food types must survive Firestore serialization and the move between
/// the shopping list and the pantry, the same as built-in categories.
void main() {
  final when = DateTime(2026, 9, 8);

  test('a custom food type round-trips through Firestore-style maps', () {
    final s = ShoppingItem(
      id: 's1', name: 'Puppy Kibble', checked: false,
      category: ItemCategory.other, customCategory: 'Pet',
      addedAt: when, addedBy: 'u1',
    );
    final map = s.toFirestore();
    expect(map['customCategory'], 'Pet');
    // category is 'other', which toFirestore omits — that's fine, custom wins.
    expect(map.containsKey('category'), isFalse);
  });

  test('custom type carries pantry -> shopping -> pantry', () {
    final inv = InventoryItem(
      id: 'p1', name: 'Puppy Kibble', category: ItemCategory.other,
      customCategory: 'Pet', quantity: 1, unit: 'item',
      location: kDefaultLocationKey, addedAt: when, addedBy: 'u1',
    );
    final s = ShoppingItem.fromInventory(inv, id: 's1', quantity: 1, addedBy: 'u1');
    expect(s.customCategory, 'Pet');
    final back = s.toInventory(id: 'p2', addedBy: 'u1',
        categoryFallback: ItemCategory.snacks);
    // The custom type wins over the guess fallback, and category stays other.
    expect(back.customCategory, 'Pet');
    expect(back.category, ItemCategory.other);
  });

  test('a built-in category still uses the guess fallback when unset', () {
    final s = ShoppingItem(
      id: 's2', name: 'Chicken', checked: false, addedAt: when, addedBy: 'u1');
    final back = s.toInventory(id: 'p3', addedBy: 'u1',
        categoryFallback: ItemCategory.meat);
    expect(back.customCategory, isNull);
    expect(back.category, ItemCategory.meat);
  });
}
