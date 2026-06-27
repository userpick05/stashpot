import 'inventory_item.dart';

/// Result of a Gemini photo product-identification call.
class FoodIdResult {
  final String name;
  final ItemCategory category;
  final String? details; // size / variety / flavor / extra info → goes to notes
  final String? store; // suggested store, e.g. inferred from a store brand
  final double confidence; // 0..1

  const FoodIdResult({
    required this.name,
    required this.category,
    this.details,
    this.store,
    required this.confidence,
  });

  factory FoodIdResult.fromJson(Map<String, dynamic> json) {
    String? clean(String? s) {
      final t = s?.trim();
      return (t == null || t.isEmpty) ? null : t;
    }

    return FoodIdResult(
      name: (json['name'] as String?)?.trim() ?? 'Unknown',
      category: _categoryFromName(json['category'] as String?),
      details: clean(json['details'] as String?),
      store: clean(json['store'] as String?),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static ItemCategory _categoryFromName(String? name) {
    final target = name?.toLowerCase().trim();
    return ItemCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == target,
      orElse: () => ItemCategory.other,
    );
  }
}
