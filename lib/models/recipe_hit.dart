import 'recipe.dart';

/// A recipe search result from Spoonacular (not yet saved).
class RecipeHit {
  final int id;
  final String title;
  final String? image;
  final String? sourceUrl;
  final double? score; // 0..100
  final int? likes;
  final int? usedCount; // pantry mode: ingredients you have
  final int? missedCount; // pantry mode: ingredients you're missing
  final List<String> missedIngredients;

  const RecipeHit({
    required this.id,
    required this.title,
    this.image,
    this.sourceUrl,
    this.score,
    this.likes,
    this.usedCount,
    this.missedCount,
    this.missedIngredients = const [],
  });

  double get stars => score == null ? 0 : (score! / 20).clamp(0, 5);

  factory RecipeHit.fromJson(Map<String, dynamic> j) {
    return RecipeHit(
      id: (j['id'] as num).toInt(),
      title: (j['title'] ?? '').toString(),
      image: j['image'] as String?,
      sourceUrl: j['sourceUrl'] as String?,
      score: (j['spoonacularScore'] as num?)?.toDouble(),
      likes: (j['aggregateLikes'] as num?)?.toInt(),
      usedCount: (j['usedIngredientCount'] as num?)?.toInt(),
      missedCount: (j['missedIngredientCount'] as num?)?.toInt(),
      missedIngredients: (j['missedIngredients'] as List?)
              ?.map((e) => (e['name'] ?? e['original'] ?? '').toString())
              .where((s) => s.isNotEmpty)
              .toList() ??
          const [],
    );
  }

  Recipe toRecipe(String uid) => Recipe(
        id: '',
        spoonacularId: id > 0 ? id : null,
        name: title,
        imageUrl: image,
        sourceUrl: sourceUrl,
        score: score,
        likes: likes,
        addedAt: DateTime.now(),
        addedBy: uid,
      );
}
