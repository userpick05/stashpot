import 'package:flutter_test/flutter_test.dart';
import 'package:stashpot/models/catalog_item.dart';

/// The catalog document id is derived from the item name, and Firestore is
/// strict about what a document id may contain. A '/' in the name used to throw
/// and make the whole "add to shopping list" look like it failed.
void main() {
  group('CatalogItem.idFor', () {
    // Firestore document ids may not contain '/'. This is the reported bug:
    // "sourdough/Italian bread" wouldn't save.
    test('a slash in the name no longer produces an illegal id', () {
      final id = CatalogItem.idFor('sourdough/Italian bread');
      expect(id.contains('/'), isFalse);
      expect(id, 'sourdough italian bread');
    });

    test('backslashes are handled too', () {
      expect(CatalogItem.idFor(r'a\b').contains('\\'), isFalse);
    });

    test('runs of separators and spaces collapse to one space', () {
      expect(CatalogItem.idFor('a // b'), 'a b');
      expect(CatalogItem.idFor('a/b/c'), 'a b c');
    });

    test('an ordinary name is just lowercased and trimmed', () {
      expect(CatalogItem.idFor('  Whole Milk  '), 'whole milk');
    });

    test("the reserved '.' and '..' ids are escaped", () {
      expect(CatalogItem.idFor('.'), isNot('.'));
      expect(CatalogItem.idFor('..'), isNot('..'));
      expect(CatalogItem.idFor('/'), isNot('/'));
    });

    test("the reserved __x__ pattern is escaped", () {
      expect(RegExp(r'^__.*__$').hasMatch(CatalogItem.idFor('__proto__')),
          isFalse);
    });

    test('the same product still de-duplicates regardless of case/spacing', () {
      expect(CatalogItem.idFor('Sourdough / Italian Bread'),
          CatalogItem.idFor('sourdough/italian bread'));
    });
  });
}
