import 'package:flutter_test/flutter_test.dart';
import 'package:stashpot/core/utils/recipe_tags.dart';
import 'package:stashpot/models/recipe.dart';

Recipe _r(String name, {List<String> tags = const []}) => Recipe(
      id: name,
      name: name,
      tags: tags,
      addedAt: DateTime(2026, 1, 1),
      addedBy: 'u',
    );

void main() {
  group('isBuiltInRecipeTag', () {
    test('recognises built-in keys and rejects custom text', () {
      expect(isBuiltInRecipeTag('dinner'), isTrue);
      expect(isBuiltInRecipeTag('chicken'), isTrue);
      expect(isBuiltInRecipeTag('Grandma'), isFalse);
      expect(isBuiltInRecipeTag('Dinner'), isFalse); // keys are lowercase
    });
  });

  group('suggestRecipeTags', () {
    test('maps obvious food + dish words to built-in tags', () {
      expect(suggestRecipeTags('Grilled Chicken Salad'),
          containsAll(<String>['salad', 'chicken']));
      expect(suggestRecipeTags('Chocolate Cake'), contains('dessert'));
      expect(suggestRecipeTags('Spaghetti Bolognese'), contains('pasta'));
      expect(suggestRecipeTags('Beef Stew'),
          containsAll(<String>['beef', 'soup']));
    });

    test('is case-insensitive and de-duplicates', () {
      final tags = suggestRecipeTags('SALMON salmon Salmon');
      expect(tags, equals(<String>['seafood']));
    });

    test('returns nothing for an unrecognised name', () {
      expect(suggestRecipeTags('Mystery Dish'), isEmpty);
    });

    test('returns tags in canonical order', () {
      // 'dinner' (dish) doesn't come from a keyword, but chicken + soup do;
      // soup is a dish-type key that sorts before chicken in kRecipeTagKeys.
      final tags = suggestRecipeTags('Chicken Soup');
      expect(tags, equals(<String>['soup', 'chicken']));
    });
  });

  group('recipeTagsInUse', () {
    test('built-ins first in canonical order, then custom alphabetical', () {
      final recipes = [
        _r('a', tags: ['chicken', 'dinner']),
        _r('b', tags: ['Zesty', 'Aunt May', 'dessert']),
      ];
      expect(recipeTagsInUse(recipes),
          equals(<String>['dinner', 'dessert', 'chicken', 'Aunt May', 'Zesty']));
    });

    test('omits tags nothing is filed under', () {
      final tags = recipeTagsInUse([_r('a', tags: ['dinner'])]);
      expect(tags, equals(<String>['dinner']));
      expect(tags, isNot(contains('lunch')));
    });
  });

  group('filterRecipes', () {
    final recipes = [
      _r('Chicken Parm', tags: ['dinner', 'chicken']),
      _r('Beef Tacos', tags: ['dinner', 'beef']),
      _r('Fruit Salad', tags: ['salad']),
    ];

    test('no filters returns everything', () {
      expect(filterRecipes(recipes).length, 3);
    });

    test('search matches on name, case-insensitive', () {
      final out = filterRecipes(recipes, search: 'beef');
      expect(out.map((r) => r.name), equals(<String>['Beef Tacos']));
    });

    test('tag filter is OR across selected tags', () {
      final out = filterRecipes(recipes, selectedTags: {'chicken', 'beef'});
      expect(out.map((r) => r.name),
          equals(<String>['Chicken Parm', 'Beef Tacos']));
    });

    test('search and tags combine with AND', () {
      final out = filterRecipes(recipes,
          search: 'tacos', selectedTags: {'dinner'});
      expect(out.map((r) => r.name), equals(<String>['Beef Tacos']));
      // A dinner that does not match the search is excluded.
      final none = filterRecipes(recipes,
          search: 'salad', selectedTags: {'dinner'});
      expect(none, isEmpty);
    });
  });

  group('Recipe.tags round-trips through Firestore map', () {
    test('tags are written when present and read back', () {
      final map = _r('x', tags: ['dinner', 'chicken']).toFirestore();
      expect(map['tags'], equals(<String>['dinner', 'chicken']));
    });

    test('empty tags are omitted from the map', () {
      expect(_r('x').toFirestore().containsKey('tags'), isFalse);
    });
  });
}
