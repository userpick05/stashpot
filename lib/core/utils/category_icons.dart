import 'package:flutter/material.dart';
import '../../models/inventory_item.dart';

IconData categoryIcon(ItemCategory c) => switch (c) {
      ItemCategory.fruit => Icons.apple,
      ItemCategory.vegetable => Icons.eco,
      ItemCategory.meat => Icons.kebab_dining,
      ItemCategory.dairy => Icons.egg,
      ItemCategory.bakery => Icons.bakery_dining,
      ItemCategory.pantry => Icons.rice_bowl,
      ItemCategory.frozen => Icons.ac_unit,
      ItemCategory.beverages => Icons.local_drink,
      ItemCategory.snacks => Icons.cookie,
      ItemCategory.household => Icons.cleaning_services,
      ItemCategory.personalCare => Icons.soap,
      ItemCategory.produce => Icons.eco,
      ItemCategory.other => Icons.category,
    };

IconData locationIcon(String key) => switch (key) {
      'fridge' => Icons.kitchen,
      'freezer' => Icons.ac_unit,
      'pantry' => Icons.shelves,
      'other' => Icons.inventory_2,
      _ => Icons.place, // custom locations
    };
