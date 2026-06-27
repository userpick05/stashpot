/// Full recipe data fetched on demand from Spoonacular.
class RecipeIngredient {
  final String name; // clean name, used for pantry match + shopping
  final String original; // full line, e.g. "600 grams chicken breast, cubed"

  const RecipeIngredient({required this.name, required this.original});
}

/// Per-serving nutrition (free-text values like "240 kcal", "12 g").
class Nutrition {
  final String? calories;
  final String? protein;
  final String? carbs;
  final String? fat;

  const Nutrition({this.calories, this.protein, this.carbs, this.fat});

  bool get isEmpty =>
      calories == null && protein == null && carbs == null && fat == null;

  /// From Spoonacular's nutrition.nutrients array.
  static Nutrition? fromSpoonacular(dynamic nutritionNode) {
    final nutrients = (nutritionNode is Map ? nutritionNode['nutrients'] : null) as List?;
    if (nutrients == null) return null;
    String? find(String name) {
      for (final n in nutrients) {
        if ((n['name'] as String?)?.toLowerCase() == name.toLowerCase()) {
          final amt = n['amount'];
          final value = amt is num
              ? (amt % 1 == 0 ? amt.toInt().toString() : amt.toStringAsFixed(1))
              : amt.toString();
          return '$value ${n['unit'] ?? ''}'.trim();
        }
      }
      return null;
    }

    final nut = Nutrition(
      calories: find('Calories'),
      protein: find('Protein'),
      carbs: find('Carbohydrates'),
      fat: find('Fat'),
    );
    return nut.isEmpty ? null : nut;
  }

  /// From schema.org JSON-LD NutritionInformation.
  static Nutrition? fromJsonLd(dynamic node) {
    if (node is! Map) return null;
    String? s(dynamic v) => v?.toString().trim().isEmpty ?? true ? null : v.toString().trim();
    final nut = Nutrition(
      calories: s(node['calories']),
      protein: s(node['proteinContent']),
      carbs: s(node['carbohydrateContent']),
      fat: s(node['fatContent']),
    );
    return nut.isEmpty ? null : nut;
  }
}

class RecipeDetails {
  final int id;
  final String title;
  final String? image;
  final String? sourceUrl;
  final int? servings;
  final int? readyInMinutes;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
  final Nutrition? nutrition;

  const RecipeDetails({
    required this.id,
    required this.title,
    this.image,
    this.sourceUrl,
    this.servings,
    this.readyInMinutes,
    this.ingredients = const [],
    this.steps = const [],
    this.nutrition,
  });

  factory RecipeDetails.fromJson(Map<String, dynamic> j) {
    final ingredients = (j['extendedIngredients'] as List?)
            ?.map((e) {
              final m = e as Map<String, dynamic>;
              return RecipeIngredient(
                name: (m['nameClean'] ?? m['name'] ?? '').toString().trim(),
                original: (m['original'] ?? m['name'] ?? '').toString().trim(),
              );
            })
            .where((i) => i.original.isNotEmpty)
            .toList() ??
        const [];

    // analyzedInstructions[].steps[].step, with an HTML fallback.
    final steps = <String>[];
    final analyzed = j['analyzedInstructions'] as List?;
    if (analyzed != null) {
      for (final block in analyzed) {
        for (final s in (block['steps'] as List? ?? const [])) {
          final text = (s['step'] ?? '').toString().trim();
          if (text.isNotEmpty) steps.add(text);
        }
      }
    }

    return RecipeDetails(
      id: (j['id'] as num).toInt(),
      title: (j['title'] ?? '').toString(),
      image: j['image'] as String?,
      sourceUrl: j['sourceUrl'] as String?,
      servings: (j['servings'] as num?)?.toInt(),
      readyInMinutes: (j['readyInMinutes'] as num?)?.toInt(),
      ingredients: ingredients,
      steps: steps,
      nutrition: Nutrition.fromSpoonacular(j['nutrition']),
    );
  }
}
