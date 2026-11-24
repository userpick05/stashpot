import 'package:flutter_test/flutter_test.dart';
import 'package:stashpot/models/inventory_item.dart';

InventoryItem _item({bool archived = false}) => InventoryItem(
      id: 'i1',
      name: 'Eggs',
      category: ItemCategory.dairy,
      quantity: 1,
      unit: 'dozen',
      location: 'fridge',
      archived: archived,
      addedAt: DateTime(2026, 1, 1),
      addedBy: 'u',
    );

void main() {
  group('InventoryItem.archived', () {
    test('defaults to false and is omitted from Firestore when false', () {
      final item = _item();
      expect(item.archived, isFalse);
      expect(item.toFirestore().containsKey('archived'), isFalse);
    });

    test('is written to Firestore only when true', () {
      expect(_item(archived: true).toFirestore()['archived'], isTrue);
    });

    test('copyWith toggles archived and leaves it otherwise', () {
      final active = _item();
      expect(active.copyWith(archived: true).archived, isTrue);
      // An unrelated copyWith keeps the current archived value.
      expect(_item(archived: true).copyWith(quantity: 5).archived, isTrue);
      expect(active.copyWith(quantity: 5).archived, isFalse);
    });

    test('a custom unit round-trips through Firestore', () {
      expect(_item().toFirestore()['unit'], 'dozen');
    });
  });
}
