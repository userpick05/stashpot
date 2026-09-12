import '../../l10n/app_localizations.dart';
import '../../models/recipe.dart';

/// Built-in recipe tags. Stored on a recipe as these stable KEYS (lowercase),
/// so the visible label can be localized (incl. 繁體中文) without rewriting data.
/// Custom household tags are stored as their own text and shown verbatim.
///
/// Two loose groups — meal type, then main food — but they're one flat tag set
/// so a recipe can be both "dinner" and "chicken" and be found under either.
const List<String> kRecipeTagKeys = [
  // Meal / dish type
  'breakfast',
  'lunch',
  'dinner',
  'dessert',
  'snack',
  'drink',
  'side',
  'soup',
  'salad',
  // Main food
  'chicken',
  'beef',
  'pork',
  'seafood',
  'vegetarian',
  'pasta',
];

bool isBuiltInRecipeTag(String tag) => kRecipeTagKeys.contains(tag);

/// Visible label for a tag: a localized built-in, or the custom tag verbatim.
String recipeTagLabelOf(AppLocalizations l, String tag) {
  switch (tag) {
    case 'breakfast':
      return l.recipeTagBreakfast;
    case 'lunch':
      return l.recipeTagLunch;
    case 'dinner':
      return l.recipeTagDinner;
    case 'dessert':
      return l.recipeTagDessert;
    case 'snack':
      return l.recipeTagSnack;
    case 'drink':
      return l.recipeTagDrink;
    case 'side':
      return l.recipeTagSide;
    case 'soup':
      return l.recipeTagSoup;
    case 'salad':
      return l.recipeTagSalad;
    case 'chicken':
      return l.recipeTagChicken;
    case 'beef':
      return l.recipeTagBeef;
    case 'pork':
      return l.recipeTagPork;
    case 'seafood':
      return l.recipeTagSeafood;
    case 'vegetarian':
      return l.recipeTagVegetarian;
    case 'pasta':
      return l.recipeTagPasta;
    default:
      return tag;
  }
}

/// Keyword → built-in tag hints, for auto-SUGGESTING tags from a recipe's name.
/// Only ever pre-selects the picker; the user confirms, so a stray guess is a
/// deselect away, never a silent mislabel.
const Map<String, String> _keywordTag = {
  // mains
  'chicken': 'chicken',
  'beef': 'beef',
  'steak': 'beef',
  'burger': 'beef',
  'pork': 'pork',
  'bacon': 'pork',
  'ham': 'pork',
  'sausage': 'pork',
  'fish': 'seafood',
  'salmon': 'seafood',
  'tuna': 'seafood',
  'shrimp': 'seafood',
  'prawn': 'seafood',
  'crab': 'seafood',
  'lobster': 'seafood',
  'seafood': 'seafood',
  'pasta': 'pasta',
  'spaghetti': 'pasta',
  'noodle': 'pasta',
  'lasagna': 'pasta',
  'macaroni': 'pasta',
  // meal / dish type
  'soup': 'soup',
  'stew': 'soup',
  'salad': 'salad',
  'cake': 'dessert',
  'cookie': 'dessert',
  'brownie': 'dessert',
  'pie': 'dessert',
  'dessert': 'dessert',
  'ice cream': 'dessert',
  'pudding': 'dessert',
  'pancake': 'breakfast',
  'waffle': 'breakfast',
  'omelet': 'breakfast',
  'omelette': 'breakfast',
  'breakfast': 'breakfast',
  'smoothie': 'drink',
  'cocktail': 'drink',
  'juice': 'drink',
  'latte': 'drink',
};

/// Best-effort built-in tags implied by a recipe name, in [kRecipeTagKeys]
/// order and de-duplicated. Used only to pre-select the tag picker.
List<String> suggestRecipeTags(String name) {
  final lower = name.toLowerCase();
  final hits = <String>{};
  _keywordTag.forEach((word, tag) {
    if (lower.contains(word)) hits.add(tag);
  });
  return [for (final k in kRecipeTagKeys) if (hits.contains(k)) k];
}

/// The tags actually in use across a set of recipes, ordered with the built-in
/// tags first (in canonical order) and custom tags after, alphabetically. This
/// is what the filter row offers, so it never shows a tag nothing is filed
/// under.
List<String> recipeTagsInUse(List<Recipe> recipes) {
  final used = <String>{for (final r in recipes) ...r.tags};
  final builtIn = [for (final k in kRecipeTagKeys) if (used.contains(k)) k];
  final custom = used.where((t) => !isBuiltInRecipeTag(t)).toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return [...builtIn, ...custom];
}

/// Filter recipes by a name search and a set of selected tags. A recipe matches
/// when its name contains [search] (case-insensitive) AND — if any tags are
/// selected — it carries at least one of them (OR across tags, so selecting
/// "chicken" and "beef" shows recipes that are either).
List<Recipe> filterRecipes(
  List<Recipe> recipes, {
  String search = '',
  Set<String> selectedTags = const {},
}) {
  final q = search.trim().toLowerCase();
  return recipes.where((r) {
    if (q.isNotEmpty && !r.name.toLowerCase().contains(q)) return false;
    if (selectedTags.isNotEmpty &&
        !r.tags.any((t) => selectedTags.contains(t))) {
      return false;
    }
    return true;
  }).toList();
}
