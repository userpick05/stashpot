import 'package:flutter_test/flutter_test.dart';
import 'package:stashpot/models/inventory_item.dart';
import 'package:stashpot/models/shopping_item.dart';

/// Amy's "one card that moves between the lists" ask: moving an item from the
/// pantry to the shopping list and back must lose NOTHING.
void main() {
  final when = DateTime(2026, 9, 7);

  InventoryItem pantryItem() => InventoryItem(
        id: 'p1',
        name: 'Whole Milk',
        barcode: '012345678905',
        imageUrl: 'https://example.com/milk.jpg',
        category: ItemCategory.dairy,
        quantity: 2,
        unit: 'L',
        expiryDate: DateTime(2026, 9, 20),
        location: 'fridge',
        store: 'Meijer',
        notes: '1 gal',
        addedAt: when,
        addedBy: 'u1',
      );

  test('pantry -> shopping carries every field', () {
    final s = ShoppingItem.fromInventory(pantryItem(),
        id: 's1', quantity: 2, addedBy: 'u1');
    expect(s.name, 'Whole Milk');
    expect(s.category, ItemCategory.dairy);
    expect(s.unit, 'L');
    expect(s.location, 'fridge');
    expect(s.store, 'Meijer');
    expect(s.note, '1 gal');
    expect(s.expiryDate, DateTime(2026, 9, 20));
    expect(s.imageUrl, 'https://example.com/milk.jpg');
    expect(s.barcode, '012345678905');
    expect(s.checked, isFalse);
  });

  test('pantry -> shopping -> pantry is lossless', () {
    final s = ShoppingItem.fromInventory(pantryItem(),
        id: 's1', quantity: 2, addedBy: 'u1');
    final back = s.toInventory(id: 'p2', addedBy: 'u1');
    final orig = pantryItem();
    expect(back.name, orig.name);
    expect(back.category, orig.category);
    expect(back.unit, orig.unit);
    expect(back.location, orig.location);
    expect(back.store, orig.store);
    expect(back.notes, orig.notes);
    expect(back.expiryDate, orig.expiryDate);
    expect(back.imageUrl, orig.imageUrl);
    expect(back.barcode, orig.barcode);
    expect(back.quantity, orig.quantity);
  });

  test('a plain quick-add shopping item falls back sensibly on the way in', () {
    final s = ShoppingItem(
        id: 's2', name: 'Bananas', checked: false, addedAt: when, addedBy: 'u1');
    // No category/location set -> category can fall back to a guess, location
    // to the default. (Fallback only applies because category is 'other'.)
    final inv = s.toInventory(
        id: 'p3', addedBy: 'u1', categoryFallback: ItemCategory.fruit);
    expect(inv.category, ItemCategory.fruit);
    expect(inv.location, kDefaultLocationKey);
    expect(inv.unit, 'item');
  });

  test('an explicit shopping category is NOT overridden by the fallback', () {
    final s = ShoppingItem(
        id: 's3',
        name: 'Salmon',
        checked: false,
        category: ItemCategory.meat,
        addedAt: when,
        addedBy: 'u1');
    final inv = s.toInventory(
        id: 'p4', addedBy: 'u1', categoryFallback: ItemCategory.other);
    expect(inv.category, ItemCategory.meat);
  });

  test('Firestore round-trip preserves the carried fields', () {
    final s = ShoppingItem.fromInventory(pantryItem(),
        id: 's5', quantity: 2, addedBy: 'u1');
    final map = s.toFirestore();
    // Sanity: the extras are actually written.
    expect(map['category'], 'dairy');
    expect(map['unit'], 'L');
    expect(map['location'], 'fridge');
    expect(map['imageUrl'], isNotNull);
    expect(map['barcode'], isNotNull);
    expect(map['expiryDate'], isNotNull);
  });

  test('a lean item omits defaulted fields from Firestore', () {
    final s = ShoppingItem(
        id: 's6', name: 'Eggs', checked: false, addedAt: when, addedBy: 'u1');
    final map = s.toFirestore();
    expect(map.containsKey('category'), isFalse); // other
    expect(map.containsKey('unit'), isFalse); // item
    expect(map.containsKey('location'), isFalse);
    expect(map.containsKey('expiryDate'), isFalse);
  });
}
