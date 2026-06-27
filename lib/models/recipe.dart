import 'package:cloud_firestore/cloud_firestore.dart';

/// A saved recipe. Web recipes are stored lightweight (link + rating) and fetch
/// their ingredients/steps on demand. Hand-entered recipes store their
/// ingredients/steps/servings directly here.
class Recipe {
  final String id;
  final int? spoonacularId;
  final String name;
  final String? imageUrl;
  final String? sourceUrl;
  final double? score; // 0..100 (Spoonacular score)
  final int? likes; // popularity / review count
  final List<String> ingredients; // stored for manual recipes
  final List<String> steps; // stored for manual recipes
  final int? servings;
  final DateTime addedAt;
  final String addedBy;

  const Recipe({
    required this.id,
    this.spoonacularId,
    required this.name,
    this.imageUrl,
    this.sourceUrl,
    this.score,
    this.likes,
    this.ingredients = const [],
    this.steps = const [],
    this.servings,
    required this.addedAt,
    required this.addedBy,
  });

  // Spoonacular score (0..100) → 0..5 stars.
  double get stars => score == null ? 0 : (score! / 20).clamp(0, 5);

  // Hand-entered recipe: ingredients/steps live on the doc, no web source.
  bool get isManual =>
      spoonacularId == null && sourceUrl == null && ingredients.isNotEmpty;

  factory Recipe.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Recipe(
      id: doc.id,
      spoonacularId: (d['spoonacularId'] as num?)?.toInt(),
      name: d['name'] as String,
      imageUrl: d['imageUrl'] as String?,
      sourceUrl: d['sourceUrl'] as String?,
      score: (d['score'] as num?)?.toDouble(),
      likes: (d['likes'] as num?)?.toInt(),
      ingredients: (d['ingredients'] as List?)?.cast<String>() ?? const [],
      steps: (d['steps'] as List?)?.cast<String>() ?? const [],
      servings: (d['servings'] as num?)?.toInt(),
      addedAt: (d['addedAt'] as Timestamp).toDate(),
      addedBy: d['addedBy'] as String,
    );
  }

  Map<String, dynamic> toFirestore() => {
        if (spoonacularId != null) 'spoonacularId': spoonacularId,
        'name': name,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (sourceUrl != null) 'sourceUrl': sourceUrl,
        if (score != null) 'score': score,
        if (likes != null) 'likes': likes,
        if (ingredients.isNotEmpty) 'ingredients': ingredients,
        if (steps.isNotEmpty) 'steps': steps,
        if (servings != null) 'servings': servings,
        'addedAt': Timestamp.fromDate(addedAt),
        'addedBy': addedBy,
      };
}
