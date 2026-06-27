import '../../models/inventory_item.dart';

/// Best-effort guess of a food category from a typed item name.
/// Cheap keyword match — instant, offline, no API. User can always override.
ItemCategory? guessCategory(String name) {
  final n = name.toLowerCase();
  bool has(List<String> keys) => keys.any((k) => n.contains(k));

  // Order matters: more specific first.
  if (has(['milk', 'cheese', 'yogurt', 'yoghurt', 'butter', 'cream', 'egg'])) {
    return ItemCategory.dairy;
  }
  if (has(['chicken', 'beef', 'pork', 'bacon', 'sausage', 'ham', 'steak',
      'turkey', 'lamb', 'fish', 'salmon', 'tuna', 'shrimp', 'meat', 'mince'])) {
    return ItemCategory.meat;
  }
  if (has(['apple', 'banana', 'orange', 'grape', 'berry', 'strawberr', 'melon',
      'mango', 'peach', 'pear', 'lemon', 'lime', 'avocado', 'fruit', 'kiwi'])) {
    return ItemCategory.fruit;
  }
  if (has(['lettuce', 'tomato', 'onion', 'potato', 'carrot', 'spinach', 'pepper',
      'broccoli', 'cucumber', 'celery', 'garlic', 'kale', 'cabbage', 'bean sprout',
      'vegetable', 'veggie', 'zucchini', 'mushroom'])) {
    return ItemCategory.vegetable;
  }
  if (has(['bread', 'bagel', 'bun', 'roll', 'muffin', 'croissant', 'tortilla',
      'cake', 'pastry', 'donut', 'baguette'])) {
    return ItemCategory.bakery;
  }
  if (has(['frozen', 'ice cream', 'popsicle'])) return ItemCategory.frozen;
  if (has(['water', 'juice', 'soda', 'coffee', 'tea', 'beer', 'wine', 'cola',
      'lemonade', 'drink', 'kombucha'])) {
    return ItemCategory.beverages;
  }
  if (has(['chip', 'cookie', 'candy', 'chocolate', 'cracker', 'popcorn', 'snack',
      'pretzel', 'granola bar', 'nuts'])) {
    return ItemCategory.snacks;
  }
  if (has(['toothpaste', 'shampoo', 'deodorant', 'lotion', 'razor', 'soap',
      'medicine', 'vitamin', 'bandage', 'floss', 'conditioner'])) {
    return ItemCategory.personalCare;
  }
  if (has(['detergent', 'paper towel', 'toilet paper', 'cleaner', 'bleach', 'wipe',
      'trash bag', 'laundry', 'dish soap', 'sponge', 'foil', 'napkin'])) {
    return ItemCategory.household;
  }
  if (has(['rice', 'pasta', 'flour', 'sugar', 'cereal', 'beans', 'sauce', 'oil',
      'spice', 'salt', 'canned', 'soup', 'peanut butter', 'honey', 'oat', 'noodle'])) {
    return ItemCategory.pantry;
  }
  return null; // no confident guess
}
