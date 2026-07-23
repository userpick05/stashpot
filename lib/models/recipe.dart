import 'package:cloud_firestore/cloud_firestore.dart';

/// Bump whenever a fix changes what we'd store for a recipe, so already-cached
/// details are re-fetched instead of preserving the old build's mistake.
/// 2 = run-on instructions split into steps, which unblocked translation.
const int kDetailsVersion = 2;

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
  final List<String> ingredients; // stored for manual + saved link recipes
  final List<String> steps; // stored for manual + saved link recipes

  /// Parallel to [ingredients]: the Latin-script form each line should be
  /// matched against. Only stored for a translated recipe, where the displayed
  /// line is in a script PantryMatch can't tokenize. Empty means "match on the
  /// ingredient line itself".
  final List<String> matchNames;

  final int? servings;

  /// Language the stored [ingredients]/[steps] are written in, for link
  /// recipes whose content was fetched (and possibly translated) on save. Null
  /// for hand-entered recipes. When it doesn't match the reader's language the
  /// screen re-fetches instead of showing them the wrong language.
  final String? detailsLang;

  /// Which build's parser wrote those cached details. When [kDetailsVersion]
  /// moves ahead of it, the cache is stale — a recipe stored by a build with a
  /// translation bug would otherwise stay wrong forever, since it looks like a
  /// perfectly good same-language hit.
  final int detailsV;

  /// True when those stored details were written or translated by the AI, so
  /// the disclosure survives a save/reopen instead of quietly disappearing.
  final bool detailsAi;

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
    this.matchNames = const [],
    this.servings,
    this.detailsLang,
    this.detailsV = 0,
    this.detailsAi = false,
    required this.addedAt,
    required this.addedBy,
  });

  Recipe copyWith({
    String? name,
    List<String>? ingredients,
    List<String>? steps,
    List<String>? matchNames,
    int? servings,
    String? detailsLang,
    int? detailsV,
    bool? detailsAi,
  }) =>
      Recipe(
        id: id,
        spoonacularId: spoonacularId,
        name: name ?? this.name,
        imageUrl: imageUrl,
        sourceUrl: sourceUrl,
        score: score,
        likes: likes,
        ingredients: ingredients ?? this.ingredients,
        steps: steps ?? this.steps,
        matchNames: matchNames ?? this.matchNames,
        servings: servings ?? this.servings,
        detailsLang: detailsLang ?? this.detailsLang,
        detailsV: detailsV ?? this.detailsV,
        detailsAi: detailsAi ?? this.detailsAi,
        addedAt: addedAt,
        addedBy: addedBy,
      );

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
      matchNames: (d['matchNames'] as List?)?.cast<String>() ?? const [],
      servings: (d['servings'] as num?)?.toInt(),
      detailsLang: d['detailsLang'] as String?,
      detailsV: (d['detailsV'] as num?)?.toInt() ?? 0,
      detailsAi: d['detailsAi'] as bool? ?? false,
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
        if (matchNames.isNotEmpty) 'matchNames': matchNames,
        if (servings != null) 'servings': servings,
        if (detailsLang != null) 'detailsLang': detailsLang,
        if (detailsV > 0) 'detailsV': detailsV,
        if (detailsAi) 'detailsAi': true,
        'addedAt': Timestamp.fromDate(addedAt),
        'addedBy': addedBy,
      };
}
