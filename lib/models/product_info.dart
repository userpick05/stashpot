import 'inventory_item.dart';

/// Result of an Open Food Facts product lookup.
class ProductInfo {
  final String barcode;
  final String? name;
  final String? brand;
  final String? imageUrl;
  final String? quantity; // e.g. "400 g" — free text from OFF
  final ItemCategory category;

  const ProductInfo({
    required this.barcode,
    this.name,
    this.brand,
    this.imageUrl,
    this.quantity,
    this.category = ItemCategory.other,
  });

  // A display name combining brand + product name when both exist.
  String? get displayName {
    if (name == null || name!.isEmpty) return null;
    if (brand != null && brand!.isNotEmpty && !name!.contains(brand!)) {
      return '$brand $name';
    }
    return name;
  }

  // Best-effort map of Open Food Facts category tags to our ItemCategory.
  static ItemCategory categoryFromTags(List<String> tags) {
    final joined = tags.join(' ').toLowerCase();
    bool has(List<String> keys) => keys.any(joined.contains);

    if (has(['dairy', 'dairies', 'milk', 'cheese', 'yogurt', 'yoghurt', 'butter'])) {
      return ItemCategory.dairy;
    }
    if (has(['meat', 'beef', 'pork', 'poultry', 'chicken', 'fish', 'seafood'])) {
      return ItemCategory.meat;
    }
    if (has(['fruit', 'vegetable', 'produce', 'legume', 'fresh-'])) {
      return ItemCategory.produce;
    }
    if (has(['frozen'])) return ItemCategory.frozen;
    if (has(['beverage', 'drink', 'water', 'juice', 'soda', 'coffee', 'tea'])) {
      return ItemCategory.beverages;
    }
    if (has(['snack', 'chips', 'crisps', 'biscuit', 'cookie', 'candy', 'chocolate', 'confection'])) {
      return ItemCategory.snacks;
    }
    if (has(['pasta', 'rice', 'cereal', 'flour', 'canned', 'sauce', 'condiment', 'spice', 'pantry', 'grocery'])) {
      return ItemCategory.pantry;
    }
    return ItemCategory.other;
  }
}
