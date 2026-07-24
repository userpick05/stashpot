import '../../l10n/app_localizations.dart';
import '../../models/inventory_item.dart';

/// Localized label for a category. The enum's `.name` remains the value stored
/// in Firestore — only the display text changes.
String categoryLabelOf(AppLocalizations l, ItemCategory c) => switch (c) {
      ItemCategory.fruit => l.categoryFruit,
      ItemCategory.vegetable => l.categoryVegetable,
      ItemCategory.meat => l.categoryMeat,
      ItemCategory.dairy => l.categoryDairy,
      ItemCategory.bakery => l.categoryBakery,
      ItemCategory.pantry => l.categoryPantry,
      ItemCategory.frozen => l.categoryFrozen,
      ItemCategory.beverages => l.categoryBeverages,
      ItemCategory.snacks => l.categorySnacks,
      ItemCategory.household => l.categoryHousehold,
      ItemCategory.personalCare => l.categoryPersonalCare,
      ItemCategory.produce => l.categoryProduce,
      ItemCategory.other => l.categoryOther,
    };

/// Localized label for a location key. Custom household locations — which the
/// user typed themselves, possibly in Chinese — pass through unchanged.
String locationLabelOf(AppLocalizations l, String key) => switch (key) {
      'fridge' => l.locationFridge,
      'freezer' => l.locationFreezer,
      'pantry' => l.locationPantry,
      'other' => l.locationOther,
      _ => key,
    };

/// Meal types are STORED as these English keys ('Breakfast'/'Lunch'/...), so
/// existing planner data keeps working — only the display text is localized.
String mealTypeLabelOf(AppLocalizations l, String key) => switch (key) {
      'Breakfast' => l.mealBreakfast,
      'Lunch' => l.mealLunch,
      'Dinner' => l.mealDinner,
      'Snack' => l.mealSnack,
      _ => key,
    };

/// Units are stored as keys ('item', 'g', 'kg', ...); display is localized.
String unitLabelOf(AppLocalizations l, String unit) => switch (unit) {
      'item' => l.unitItem,
      'g' => l.unitG,
      'kg' => l.unitKg,
      'ml' => l.unitMl,
      'L' => l.unitL,
      'oz' => l.unitOz,
      'lb' => l.unitLb,
      'cup' => l.unitCup,
      'bunch' => l.unitBunch,
      _ => unit,
    };
