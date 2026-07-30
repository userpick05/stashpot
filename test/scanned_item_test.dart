import 'package:flutter_test/flutter_test.dart';
import 'package:stashpot/models/inventory_item.dart';
import 'package:stashpot/models/scanned_item.dart';

/// The screenshot scan hands back model-authored JSON, so parsing has to survive
/// the model drifting off the requested shape. Losing a whole scan of 30 items
/// because one field came back as a string would be far worse than one row the
/// user has to correct.
void main() {
  group('ScannedItem.tryParse', () {
    test('reads a well-formed row', () {
      final item = ScannedItem.tryParse({
        'name': 'a2 Milk Vitamin D Whole Milk',
        'note': '59oz',
        'quantity': 2,
        'category': 'dairy',
        'partial': false,
        'quantityAssumed': false,
      })!;
      expect(item.name, 'a2 Milk Vitamin D Whole Milk');
      expect(item.note, '59oz');
      expect(item.quantity, 2);
      expect(item.category, ItemCategory.dairy);
      expect(item.quantityAssumed, isFalse);
      expect(item.selected, isTrue, reason: 'rows start checked');
      expect(item.destination, isNull, reason: 'follows the master toggle');
    });

    test('rejects a row with no usable name', () {
      expect(ScannedItem.tryParse({'quantity': 2}), isNull);
      expect(ScannedItem.tryParse({'name': '   '}), isNull);
      expect(ScannedItem.tryParse('not a map'), isNull);
      expect(ScannedItem.tryParse(null), isNull);
    });

    test('accepts a quantity sent as a string', () {
      expect(ScannedItem.tryParse({'name': 'Eggs', 'quantity': '3'})!.quantity, 3);
      expect(
          ScannedItem.tryParse({'name': 'Eggs', 'quantity': 'x2'})!.quantity, 2);
    });

    test('a missing quantity defaults to 1 and is flagged as assumed', () {
      final item = ScannedItem.tryParse({'name': 'Bananas'})!;
      expect(item.quantity, 1);
      expect(item.quantityAssumed, isTrue,
          reason: 'the UI must mark quantities it guessed');
    });

    test('a zero or negative quantity is treated as a misread, not as none', () {
      expect(ScannedItem.tryParse({'name': 'Eggs', 'quantity': 0})!.quantity, 1);
      expect(ScannedItem.tryParse({'name': 'Eggs', 'quantity': -2})!.quantity, 1);
    });

    test('an unknown or translated category falls back to other', () {
      expect(ScannedItem.tryParse({'name': 'X', 'category': 'zzz'})!.category,
          ItemCategory.other);
      expect(ScannedItem.tryParse({'name': 'X', 'category': '乳製品'})!.category,
          ItemCategory.other);
      expect(ScannedItem.tryParse({'name': 'X'})!.category, ItemCategory.other);
    });

    test('category matching is case-insensitive', () {
      expect(
          ScannedItem.tryParse({'name': 'X', 'category': 'PersonalCare'})!
              .category,
          ItemCategory.personalCare);
    });

    test('an empty or literal-null note becomes null', () {
      expect(ScannedItem.tryParse({'name': 'X', 'note': ''})!.note, isNull);
      expect(ScannedItem.tryParse({'name': 'X', 'note': '   '})!.note, isNull);
      // Models sometimes emit the string "null" instead of a JSON null.
      expect(ScannedItem.tryParse({'name': 'X', 'note': 'null'})!.note, isNull);
    });

    test('the safety flags fail OPEN, not closed', () {
      // partial and quantityAssumed exist to tell the user "check this row".
      // Every other field is parsed leniently, so these must be too: a model
      // answering "true" as a string would otherwise silently drop the very
      // warning the user is meant to act on. Erring toward showing a warning
      // costs a glance; erring the other way writes a wrong quantity.
      for (final truthy in [true, 'true', 'TRUE', 'yes', '1']) {
        expect(
            ScannedItem.tryParse(
                {'name': 'X', 'quantity': 1, 'partial': truthy})!.partial,
            isTrue,
            reason: 'partial should be set for $truthy');
        expect(
            ScannedItem.tryParse({
              'name': 'X',
              'quantity': 1,
              'quantityAssumed': truthy
            })!
                .quantityAssumed,
            isTrue,
            reason: 'quantityAssumed should be set for $truthy');
      }
      for (final falsy in [false, 'false', 'no', '0', null]) {
        expect(
            ScannedItem.tryParse(
                {'name': 'X', 'quantity': 1, 'partial': falsy})!.partial,
            isFalse,
            reason: 'partial should stay clear for $falsy');
      }
    });

    test('a row whose quantity was read is not flagged', () {
      final i = ScannedItem.tryParse(
          {'name': 'X', 'quantity': 2, 'quantityAssumed': false})!;
      expect(i.quantityAssumed, isFalse);
    });
  });

  group('ScanResult', () {
    test('is empty when nothing was found', () {
      expect(const ScanResult().isEmpty, isTrue);
      expect(const ScanResult(items: []).isEmpty, isTrue);
    });
  });

  group('productKey — the coalescing identity', () {
    ScannedItem item(String name, [String? note]) =>
        ScannedItem(name: name, note: note);

    test('name and note together identify a product', () {
      expect(item('Milk', '1 gal').productKey, item('Milk', '1 gal').productKey);
    });

    test('different sizes of one product stay separate', () {
      // The whole reason note is part of the key: merging these would combine
      // a gallon and a quart into one pantry line.
      expect(item('Milk', '1 gal').productKey,
          isNot(item('Milk', '1 qt').productKey));
    });

    test('ignores case and surrounding whitespace', () {
      expect(item('  MILK ', ' 1 GAL ').productKey,
          item('milk', '1 gal').productKey);
    });

    test('a missing note and an empty note are the same thing', () {
      expect(item('Eggs').productKey, item('Eggs', '').productKey);
      expect(item('Eggs').productKey, item('Eggs', '   ').productKey);
    });

    test('two readings of one cart line collide, so they coalesce', () {
      // This is the case that matters: the model failing to de-duplicate an
      // overlapping screenshot must produce ONE write, not two.
      final a = ScannedItem(name: 'a2 Milk Vitamin D Whole Milk', note: '59oz');
      final b = ScannedItem(name: 'a2 Milk Vitamin D Whole Milk', note: '59oz');
      expect(a.productKey, b.productKey);
    });
  });

  group('suggestedLocation', () {
    String locOf(ItemCategory c) =>
        ScannedItem(name: 'X', category: c).suggestedLocation;

    test('perishables go somewhere cold rather than the default', () {
      expect(locOf(ItemCategory.frozen), 'freezer');
      expect(locOf(ItemCategory.dairy), 'fridge');
      expect(locOf(ItemCategory.meat), 'fridge');
    });

    test('anything ambiguous keeps the default location', () {
      expect(locOf(ItemCategory.pantry), kDefaultLocationKey);
      expect(locOf(ItemCategory.household), kDefaultLocationKey);
      expect(locOf(ItemCategory.other), kDefaultLocationKey);
      expect(locOf(ItemCategory.fruit), kDefaultLocationKey);
    });

    test('only ever returns a built-in location key', () {
      for (final c in ItemCategory.values) {
        expect(kBuiltInLocationKeys, contains(locOf(c)),
            reason: 'a made-up location would not group or translate');
      }
    });
  });
}
