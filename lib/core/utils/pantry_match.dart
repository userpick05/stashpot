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
    // product-marketing modifiers — almost never the actual object, and the
    // cause of false "similar item" matches (e.g. "Mucinex Multi-Symptom"
    // matching "Multi Seed" on "multi"). Matching should key on the item, not
    // these throwaway words.
    'multi', 'symptom', 'symptoms', 'max', 'maximum',
    'strength', 'value', 'family', 'size', 'count', 'ct', 'pack', 'packs',
    'original', 'natural', 'formula', 'brand', 'mega', 'ultra', 'super',
    'daily', 'nighttime', 'daytime', 'relief', 'advanced', 'complete',
    'total', 'essential', 'essentials', 'new', 'improved',
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

  /// Pantry names that overlap [query], split into STRONG matches (effectively
  /// the same item — "you already have this") and merely SIMILAR ones (share a
  /// word, e.g. "chicken" surfacing "chicken breast" and "chicken broth" — a
  /// nudge to check, not a claim you have it).
  static ({List<String> strong, List<String> similar}) overlap(
    String query,
    List<String> pantryNames,
  ) {
    final strong = <String>[];
    final similar = <String>[];
    final q = coreWords(query);
    final qNorm = query.trim().toLowerCase();
    if (q.isEmpty) {
      // No Latin core words. If the query still has Latin letters it was all
      // stop-words, so stay silent (no false alarms). If it has none — a
      // Chinese name, say — coreWords can't help, so fall back to whole-name
      // matching, otherwise the warning would be silently dead for CJK users.
      if (qNorm.isEmpty || RegExp(r'[a-z]').hasMatch(qNorm)) {
        return (strong: strong, similar: similar);
      }
      for (final name in pantryNames) {
        final n = name.trim().toLowerCase();
        if (n == qNorm) {
          strong.add(name);
        } else if (n.isNotEmpty && (n.contains(qNorm) || qNorm.contains(n))) {
          similar.add(name);
        }
      }
      return (strong: strong, similar: similar);
    }
    for (final name in pantryNames) {
      final p = coreWords(name);
      if (p.intersection(q).isEmpty) continue;
      // Same item: identical core words, or the raw names match once normalized.
      final sameCore = p.length == q.length && p.difference(q).isEmpty;
      if (sameCore || name.trim().toLowerCase() == qNorm) {
        strong.add(name);
      } else {
        similar.add(name);
      }
    }
    return (strong: strong, similar: similar);
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
