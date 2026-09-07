import 'package:flutter_test/flutter_test.dart';
import 'package:stashpot/core/utils/pantry_match.dart';

/// The "already in your pantry?" warning: a STRONG match means "you have this",
/// a SIMILAR match is a nudge to check (the user's example: typing "chicken"
/// should surface both "chicken breast" and "chicken broth" so they can judge).
void main() {
  group('PantryMatch.overlap', () {
    test('an item you already have is a strong match', () {
      final r = PantryMatch.overlap('chicken breast', ['Chicken Breast', 'Milk']);
      expect(r.strong, ['Chicken Breast']);
      expect(r.similar, isEmpty);
    });

    test('a generic query surfaces its specifics as similar, not strong', () {
      final r = PantryMatch.overlap(
          'chicken', ['Chicken Breast', 'Chicken Broth', 'Milk']);
      expect(r.strong, isEmpty);
      expect(r.similar, containsAll(['Chicken Breast', 'Chicken Broth']));
      expect(r.similar, isNot(contains('Milk')));
    });

    test('nothing related returns no matches at all', () {
      final r = PantryMatch.overlap('bananas', ['Milk', 'Eggs', 'Bread']);
      expect(r.strong, isEmpty);
      expect(r.similar, isEmpty);
    });

    test('case and plurals do not stop a strong match', () {
      // coreWords singularizes, so "onions" and "Onion" share a core word.
      final r = PantryMatch.overlap('onions', ['Onion']);
      expect(r.strong, ['Onion']);
    });

    test('a more specific query still flags the generic item as similar', () {
      final r = PantryMatch.overlap('boneless chicken breast', ['Chicken']);
      // "chicken" is a subset, not the same item — similar, so the user sees it.
      expect(r.similar, ['Chicken']);
      expect(r.strong, isEmpty);
    });

    test('an all-stopword query matches nothing (no false alarms)', () {
      final r = PantryMatch.overlap('a of the', ['Chicken', 'Milk']);
      expect(r.strong, isEmpty);
      expect(r.similar, isEmpty);
    });

    test('CJK names still match by whole name (for Frank)', () {
      // coreWords is Latin-only, so without a fallback a Chinese user would
      // never see the warning. Exact and containment should still fire.
      final exact = PantryMatch.overlap('牛奶', ['牛奶', '雞蛋']);
      expect(exact.strong, ['牛奶']);
      final contained = PantryMatch.overlap('牛奶', ['全脂牛奶']);
      expect(contained.similar, ['全脂牛奶']);
      final none = PantryMatch.overlap('香蕉', ['牛奶', '雞蛋']);
      expect(none.strong, isEmpty);
      expect(none.similar, isEmpty);
    });
  });
}
