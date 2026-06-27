/// Fuzzy match between a recipe ingredient line and pantry items.
///
/// Both the ingredient line and each pantry name are reduced to their "core"
/// words — stripping quantities, units, and prep/descriptor words, and
/// singularizing plurals — then they match if they share a core word.
/// e.g. "1 onion, chopped" matches pantry "onion", "yellow onion", or "onions".
class PantryMatch {
  // Words to drop: measures, prep/descriptors, and fillers.
  static const _stop = {
    // measures / units
    'cup', 'cups', 'tablespoon', 'tablespoons', 'tbsp', 'teaspoon', 'teaspoons',
    'tsp', 'oz', 'ounce', 'ounces', 'lb', 'lbs', 'pound', 'pounds', 'gram',
    'grams', 'kg', 'ml', 'liter', 'liters', 'litre', 'clove', 'cloves', 'can',
    'cans', 'package', 'packages', 'pkg', 'pinch', 'dash', 'slice', 'slices',
    'piece', 'pieces', 'bunch', 'bunches', 'handful', 'jar', 'jars', 'bottle',
    'stick', 'sticks', 'sprig', 'sprigs', 'head', 'heads', 'quart', 'pint',
    'gallon', 'large', 'medium', 'small', 'extra',
    // prep / descriptors
    'chopped', 'diced', 'minced', 'sliced', 'grated', 'shredded', 'crushed',
    'ground', 'fresh', 'freshly', 'frozen', 'dried', 'cooked', 'uncooked', 'raw',
    'peeled', 'seeded', 'halved', 'quartered', 'cubed', 'beaten', 'melted',
    'softened', 'room', 'temperature', 'finely', 'roughly', 'thinly', 'coarsely',
    'plus', 'more', 'for', 'garnish', 'divided', 'drained', 'rinsed', 'optional',
    'taste', 'boneless', 'skinless', 'ripe', 'firm', 'packed', 'plain', 'whole',
    'reduced', 'low', 'fat', 'free', 'organic', 'toasted', 'warm', 'cold', 'hot',
    'approximately', 'about', 'cut', 'trimmed', 'washed', 'crumbled', 'unsalted',
    // fillers
    'of', 'a', 'an', 'the', 'and', 'or', 'into', 'with', 'in', 'on', 'as',
    'each', 'your', 'such', 'like', 'some', 'any',
  };

  static String _singular(String w) {
    if (w.endsWith('ss')) return w; // glass, mass
    if (w.endsWith('ies') && w.length > 4) {
      return '${w.substring(0, w.length - 3)}y'; // berries -> berry
    }
    if (w.endsWith('oes') && w.length > 4) {
      return w.substring(0, w.length - 2); // tomatoes -> tomato
    }
    if (w.endsWith('s') && w.length > 3) {
      return w.substring(0, w.length - 1); // onions -> onion
    }
    return w;
  }

  /// Meaningful, singularized words in a name/line (3+ letters, no stop words).
  static Set<String> coreWords(String s) {
    final out = <String>{};
    for (final raw in s.toLowerCase().split(RegExp(r'[^a-z]+'))) {
      if (raw.length < 3 || _stop.contains(raw)) continue;
      out.add(_singular(raw));
    }
    return out;
  }

  /// True if any pantry item shares a core word with the ingredient line.
  static bool hasIngredient(String ingredientLine, List<String> pantryNames) {
    final lineWords = coreWords(ingredientLine);
    if (lineWords.isEmpty) return false;
    for (final name in pantryNames) {
      if (coreWords(name).intersection(lineWords).isNotEmpty) return true;
    }
    return false;
  }

  /// Splits ingredients into (have, missing) given pantry item names.
  static (List<String> have, List<String> missing) split(
    List<String> ingredients,
    List<String> pantryNames,
  ) {
    final have = <String>[];
    final missing = <String>[];
    for (final ing in ingredients) {
      (hasIngredient(ing, pantryNames) ? have : missing).add(ing);
    }
    return (have, missing);
  }
}
