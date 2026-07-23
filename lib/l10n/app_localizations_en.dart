// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Stashpot';

  @override
  String get appTagline => 'Your home pantry, always in sync';

  @override
  String get navHome => 'Home';

  @override
  String get navPantry => 'Pantry';

  @override
  String get navShopping => 'Shopping';

  @override
  String get navRecipes => 'Recipes';

  @override
  String get navPlanner => 'Planner';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSaving => 'Saving…';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonRename => 'Rename';

  @override
  String get commonUndo => 'Undo';

  @override
  String get commonSkip => 'Skip';

  @override
  String get commonClose => 'Close';

  @override
  String get commonLater => 'Later';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonDone => 'Done';

  @override
  String commonError(String message) {
    return 'Error: $message';
  }

  @override
  String get categoryFruit => 'Fruit';

  @override
  String get categoryVegetable => 'Vegetables';

  @override
  String get categoryMeat => 'Meat & Fish';

  @override
  String get categoryDairy => 'Dairy & Eggs';

  @override
  String get categoryBakery => 'Bakery';

  @override
  String get categoryPantry => 'Dry Goods';

  @override
  String get categoryFrozen => 'Frozen';

  @override
  String get categoryBeverages => 'Beverages';

  @override
  String get categorySnacks => 'Snacks';

  @override
  String get categoryHousehold => 'Household';

  @override
  String get categoryPersonalCare => 'Personal Care';

  @override
  String get categoryProduce => 'Produce';

  @override
  String get categoryOther => 'Other';

  @override
  String get locationFridge => 'Fridge';

  @override
  String get locationFreezer => 'Freezer';

  @override
  String get locationPantry => 'Pantry';

  @override
  String get locationOther => 'Other';

  @override
  String get mealBreakfast => 'Breakfast';

  @override
  String get mealLunch => 'Lunch';

  @override
  String get mealDinner => 'Dinner';

  @override
  String get mealSnack => 'Snack';

  @override
  String get unitItem => 'item';

  @override
  String get unitG => 'g';

  @override
  String get unitKg => 'kg';

  @override
  String get unitMl => 'ml';

  @override
  String get unitL => 'L';

  @override
  String get unitOz => 'oz';

  @override
  String get unitLb => 'lb';

  @override
  String get unitCup => 'cup';

  @override
  String get unitBunch => 'bunch';

  @override
  String get noStoreGroup => 'Other / no store';

  @override
  String get settingsTitle => 'Settings';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsInviteFriends => 'Invite friends';

  @override
  String get settingsInviteSubtitle => 'Share your household invite code';

  @override
  String get settingsPantryLocations => 'Pantry locations';

  @override
  String get settingsPantryLocationsSubtitle =>
      'Add or edit your own storage locations';

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSubtitle => 'Choose the app language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChineseTraditional => '繁體中文';

  @override
  String addItemBarcodeNotFoundTitle(String code) {
    return 'No product found for $code';
  }

  @override
  String get addItemBarcodeNotFoundBody =>
      'Local and imported products often aren\'t in the barcode database. You can identify it from a photo of the packaging instead.';

  @override
  String get addItemTakePhotoInstead => 'Take a photo instead';

  @override
  String get addItemEnterManually => 'Enter manually';

  @override
  String get homeGreetingMorning => 'Good morning';

  @override
  String get homeGreetingAfternoon => 'Good afternoon';

  @override
  String get homeGreetingEvening => 'Good evening';

  @override
  String homeGreetingNamed(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String get homeStatExpiring => 'Expiring';

  @override
  String get homeRunningLow => 'Running low?';

  @override
  String get homeRunningLowSubtitle =>
      'Find an item and add it to the shopping list';

  @override
  String get homeWhatsForDinner => 'What\'s for dinner';

  @override
  String get homeRecipeOfTheDay => 'Recipe of the day';

  @override
  String get homeToday => 'Today';

  @override
  String get homeTomorrow => 'Tomorrow';

  @override
  String get homeNothingPlanned => 'Nothing planned';

  @override
  String get homeQuickActions => 'Quick actions';

  @override
  String get homeFindRecipes => 'Find recipes';

  @override
  String get homePlanAMeal => 'Plan a meal';

  @override
  String get homeShoppingList => 'Shopping list';

  @override
  String get homeAddToPantry => 'Add to pantry';

  @override
  String get homeAddItem => 'Add item';

  @override
  String get homeScan => 'Scan';

  @override
  String get homePhoto => 'Photo';

  @override
  String get locationsBuiltIn => 'Built-in';

  @override
  String get locationsYours => 'Your locations';

  @override
  String get locationsEmpty => 'No custom locations yet. Tap + to add one.';

  @override
  String get locationsAdd => 'Add location';

  @override
  String get locationsNew => 'New location';

  @override
  String get locationsRename => 'Rename location';

  @override
  String get locationsHint => 'e.g. Garage shelf';

  @override
  String locationsRemoved(String name) {
    return 'Removed location \"$name\"';
  }

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authEmailInvalid => 'Enter a valid email';

  @override
  String get authPasswordTooShort => 'Password must be 6+ characters';

  @override
  String get authPasswordMin => 'Minimum 6 characters';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authNoAccountRegister => 'Don\'t have an account? Register';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authYourName => 'Your name';

  @override
  String get authNameRequired => 'Enter your name';

  @override
  String get authHaveAccountSignIn => 'Already have an account? Sign in';

  @override
  String get authHouseholdNameRequired => 'Enter a household name';

  @override
  String get authInviteCodeRequired => 'Enter an invite code';

  @override
  String get authSetUpHousehold => 'Set up your household';

  @override
  String get authSetUpHouseholdSubtitle =>
      'Create a new household or join your partner\'s existing one.';

  @override
  String get authStartNewHousehold => 'Start a new household';

  @override
  String get authHouseholdNameLabel => 'Household name (e.g. \"The Smiths\")';

  @override
  String get authCreateHousehold => 'Create household';

  @override
  String get authOr => 'or';

  @override
  String get authJoinExisting => 'Join an existing household';

  @override
  String get authJoinExistingSubtitle =>
      'Ask the person who set it up to share their invite code.';

  @override
  String get authInviteCodeLabel => 'Invite code';

  @override
  String get authJoinHousehold => 'Join household';

  @override
  String get inviteTitle => 'Invite your partner';

  @override
  String get inviteBody =>
      'Share this code so they can join your pantry. They register their own account, then enter it under \"Join an existing household\".';

  @override
  String get inviteCopyCode => 'Copy code';

  @override
  String get inviteCopied => 'Invite code copied';

  @override
  String swipeRemoved(String label) {
    return 'Removed $label';
  }

  @override
  String get updateAvailable => 'Update available';

  @override
  String get updateStarting => 'Starting download…';

  @override
  String updateDownloadingPercent(String percent) {
    return 'Downloading… $percent%';
  }

  @override
  String get updateNow => 'Update now';

  @override
  String get pantryGroupByTooltip => 'Group by';

  @override
  String get pantryGroupByLocation => 'Group by location';

  @override
  String get pantryGroupByCategory => 'Group by category';

  @override
  String get pantryGroupByStore => 'Group by store';

  @override
  String get pantryEmptyTitle => 'Your pantry is empty';

  @override
  String get pantryEmptySubtitle => 'Tap + to add your first item';

  @override
  String pantryExpiringBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items expiring soon or expired',
      one: '$count item expiring soon or expired',
    );
    return '$_temp0';
  }

  @override
  String pantryNoMatches(String query) {
    return 'No items match \"$query\"';
  }

  @override
  String get pantrySearchHint => 'Search pantry…';

  @override
  String get pantryAddItemFab => 'Add item';

  @override
  String get pantryExpiresToday => 'Expires today';

  @override
  String get pantryExpiresTomorrow => 'Expires tomorrow';

  @override
  String pantryExpiresInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Expires in $days days',
      one: 'Expires in $days day',
    );
    return '$_temp0';
  }

  @override
  String pantryExpiredDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Expired $days days ago',
      one: 'Expired $days day ago',
    );
    return '$_temp0';
  }

  @override
  String get pantryMoreTooltip => 'More';

  @override
  String get pantryAddToShoppingList => 'Add to shopping list';

  @override
  String get pantryMoveToShoppingList =>
      'Remove from pantry & add to shopping list';

  @override
  String get pantryViewPhoto => 'View photo';

  @override
  String get addItemTitleAdd => 'Add item';

  @override
  String get addItemTitleEdit => 'Edit item';

  @override
  String get addItemNewLocationTitle => 'New location';

  @override
  String get addItemNewLocationHint => 'e.g. Garage shelf';

  @override
  String get addItemTakePhoto => 'Take a photo';

  @override
  String get addItemChooseFromGallery => 'Choose from gallery';

  @override
  String get addItemCameraPermissionPhoto =>
      'Camera permission is needed to take a photo';

  @override
  String get addItemCameraPermissionScan =>
      'Camera permission is needed to scan';

  @override
  String addItemPhotoUploadFailed(String error) {
    return 'Photo upload failed: $error';
  }

  @override
  String get addItemIdentifyFailed =>
      'Couldn\'t identify the food — enter it manually';

  @override
  String addItemIdentified(String name, int percent) {
    return 'Identified: $name ($percent% sure)';
  }

  @override
  String addItemPhotoIdError(String error) {
    return 'Photo ID failed: $error. You can still add it manually.';
  }

  @override
  String get addItemBarcodeUnreadable =>
      'Couldn\'t read the barcode — fill the frame, hold steady in good light, or enter it manually';

  @override
  String addItemNoProductFound(String code) {
    return 'No product found for $code — enter details manually';
  }

  @override
  String addItemProductFound(String name) {
    return 'Found: $name';
  }

  @override
  String addItemLookupError(String error) {
    return 'Lookup failed: $error. You can still add it manually.';
  }

  @override
  String get addItemNoSavedStores =>
      'No saved stores yet. Type a store name below and you\'ll be asked to add it to the list.';

  @override
  String get addItemPickStore => 'Pick a store';

  @override
  String get addItemPickStoreTooltip => 'Pick from saved stores';

  @override
  String get addItemLookingUp => 'Looking up product…';

  @override
  String get addItemScanBarcode => 'Scan barcode';

  @override
  String addItemScanned(String code) {
    return 'Scanned: $code (rescan)';
  }

  @override
  String get addItemIdentifying => 'Identifying…';

  @override
  String get addItemIdentifyByPhoto => 'Identify by photo';

  @override
  String get addItemNameLabel => 'Item name *';

  @override
  String get addItemNameRequired => 'Enter a name';

  @override
  String get addItemQuantityLabel => 'Quantity';

  @override
  String get addItemQuantityInvalid => 'Invalid';

  @override
  String get addItemUnitLabel => 'Unit';

  @override
  String get addItemFoodTypeLabel => 'Food type';

  @override
  String get addItemLocationLabel => 'Location';

  @override
  String get addItemAddLocation => 'Add location…';

  @override
  String get addItemStoreLabel => 'Store (optional)';

  @override
  String get addItemStoreHint => 'e.g. Costco, Walmart, Trader Joe\'s';

  @override
  String get addItemExpiryLabel => 'Expiry date (optional)';

  @override
  String addItemExpiresOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Expires: $dateString';
  }

  @override
  String get addItemNotesLabel => 'Notes (optional)';

  @override
  String get addItemPhotoAttached => 'Photo attached';

  @override
  String get addItemRemovePhoto => 'Remove photo';

  @override
  String get addItemUploading => 'Uploading…';

  @override
  String get addItemAddPhoto => 'Add photo';

  @override
  String get addItemReplacePhoto => 'Replace photo';

  @override
  String get addItemSaveChanges => 'Save changes';

  @override
  String get addItemAddToPantry => 'Add to pantry';

  @override
  String get qtySheetTitle => 'Quantity';

  @override
  String get qtyMoveTitle => 'How many to move?';

  @override
  String qtyMoveAvailable(String amount) {
    return 'You have $amount. The rest stays in your pantry.';
  }

  @override
  String get qtyMoveAll => 'Move all to shopping list';

  @override
  String qtyMoveAmount(String amount) {
    return 'Move $amount to shopping list';
  }

  @override
  String get plannerToday => 'Today';

  @override
  String get plannerTomorrow => 'Tomorrow';

  @override
  String get plannerYesterday => 'Yesterday';

  @override
  String get plannerFormatMonth => 'Month';

  @override
  String get plannerFormatTwoWeeks => '2 weeks';

  @override
  String get plannerFormatWeek => 'Week';

  @override
  String get plannerAddMeal => 'Add meal';

  @override
  String get plannerNothingPlanned => 'Nothing planned for this day';

  @override
  String get plannerMoveTooltip => 'Move to another day';

  @override
  String get plannerOpenRecipeTooltip => 'Open recipe';

  @override
  String get plannerRecipeGone => 'That recipe is no longer saved';

  @override
  String plannerSwapped(String a, String b) {
    return 'Swapped \"$a\" with \"$b\"';
  }

  @override
  String plannerMoved(String title, String day) {
    return 'Moved \"$title\" to $day';
  }

  @override
  String plannerAddedMeals(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count meals to the planner',
      one: 'Added 1 meal to the planner',
    );
    return '$_temp0';
  }

  @override
  String get mealPlanTitle => 'Plan a meal';

  @override
  String get mealEditTitle => 'Edit meal';

  @override
  String get mealFieldLabel => 'Meal';

  @override
  String get mealFieldHint => 'e.g. Tacos';

  @override
  String get mealChooseSavedRecipe => 'Choose a saved recipe';

  @override
  String get mealPickRecipe => 'Pick a recipe';

  @override
  String get mealNoSavedRecipes =>
      'No saved recipes yet — add some in the Recipes tab';

  @override
  String get mealEnterOrPick => 'Enter a meal or pick a recipe';

  @override
  String get mealNotesLabel => 'Notes (optional)';

  @override
  String get mealNotesHint => 'e.g. double the recipe, use leftovers';

  @override
  String get mealSaveChanges => 'Save changes';

  @override
  String get mealAddToPlan => 'Add to plan';

  @override
  String mealMoveTitle(String title) {
    return 'Move \"$title\" to…';
  }

  @override
  String mealMoveSwapHint(String mealType) {
    return 'If that day already has a $mealType planned, the two swap places.';
  }

  @override
  String get mealMoveConfirm => 'Move here';

  @override
  String get rouletteTitle => 'Meal roulette';

  @override
  String get rouletteTooltip => 'Meal roulette (auto-fill)';

  @override
  String get rouletteSubtitle =>
      'Auto-fill empty days with a random pick from meals you have planned before.';

  @override
  String get rouletteFillNext => 'Fill the next';

  @override
  String rouletteDayUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return '$_temp0';
  }

  @override
  String get rouletteWhichMeals => 'Fill which meals?';

  @override
  String get rouletteTypeJoiner => ' or ';

  @override
  String rouletteNoHistory(String types) {
    return 'No $types meals in your planner yet — plan a few first so the roulette has something to draw from.';
  }

  @override
  String get rouletteNothingToFill =>
      'Those days are already planned for the meals you picked — nothing to fill.';

  @override
  String rouletteToAdd(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count to add',
      one: '1 to add',
    );
    return '$_temp0';
  }

  @override
  String get rouletteRoll => 'Roll';

  @override
  String get rouletteReRoll => 'Re-roll';

  @override
  String get rouletteAddToPlanner => 'Add to planner';

  @override
  String get recipeAddByLinkTitle => 'Add recipe by link';

  @override
  String get recipeAddByLinkHint => 'Paste a recipe URL';

  @override
  String get recipeAddByLinkTooltip => 'Add by link';

  @override
  String get recipeLinkNeedsHttp => 'Enter a full link starting with http';

  @override
  String get recipeSavingLink => 'Saving link…';

  @override
  String recipeSaved(String name) {
    return 'Saved \"$name\"';
  }

  @override
  String recipeLinkSaveFailed(String message) {
    return 'Could not save link: $message';
  }

  @override
  String get recipeWrite => 'Write a recipe';

  @override
  String get recipeEmptyTitle => 'No saved recipes yet';

  @override
  String get recipeEmptyHint => 'Tap \"Find recipes\" to search the web';

  @override
  String recipeRemoved(String name) {
    return 'Removed $name';
  }

  @override
  String recipeShoppingNote(String name) {
    return 'for $name';
  }

  @override
  String recipeAddedToShopping(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count items to your shopping list',
      one: 'Added 1 item to your shopping list',
    );
    return '$_temp0';
  }

  @override
  String get recipeOpenOriginalTooltip => 'Open original in browser';

  @override
  String get recipeEditTooltip => 'Edit';

  @override
  String recipeMinutes(int count) {
    return '$count min';
  }

  @override
  String get recipeLoadFailed =>
      'Couldn\'t load this recipe — check your connection and retry.';

  @override
  String get recipeNoStructuredData =>
      'Couldn\'t read a recipe from this page. Some sites don\'t share their recipe data — open it in your browser to view it.';

  @override
  String get recipeAiTranslated =>
      'Read by AI from the page — check the quantities against the original.';

  @override
  String get recipeReadingPage => 'Reading the recipe…';

  @override
  String get recipeOpenInBrowser => 'Open in browser';

  @override
  String get recipeIngredients => 'Ingredients';

  @override
  String recipeHaveCount(int have, int total) {
    return 'Have $have/$total';
  }

  @override
  String recipeAddMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $count missing to shopping list',
      one: 'Add 1 missing to shopping list',
    );
    return '$_temp0';
  }

  @override
  String get recipeAddAllIngredients => 'Add ALL ingredients to shopping list';

  @override
  String get recipeInstructions => 'Instructions';

  @override
  String get recipeOnListTooltip => 'On shopping list — tap to add again';

  @override
  String get recipeAddToShoppingTooltip => 'Add to shopping list';

  @override
  String get recipeNutritionTitle => 'Nutrition (per serving)';

  @override
  String get recipeCalories => 'Calories';

  @override
  String get recipeProtein => 'Protein';

  @override
  String get recipeCarbs => 'Carbs';

  @override
  String get recipeFat => 'Fat';

  @override
  String get recipeManualEditTitle => 'Edit recipe';

  @override
  String get recipeManualNeedName => 'Give the recipe a name';

  @override
  String get recipeManualNameLabel => 'Recipe name *';

  @override
  String get recipeManualServingsLabel => 'Servings (optional)';

  @override
  String get recipeManualIngredientsLabel => 'Ingredients (one per line)';

  @override
  String get recipeManualStepsLabel => 'Steps (one per line)';

  @override
  String get recipeManualSave => 'Save recipe';

  @override
  String get findRecipesTitle => 'Find recipes';

  @override
  String get findRecipesSearchHint => 'Search a dish, or paste a recipe link';

  @override
  String get findRecipesSearchButton => 'Search';

  @override
  String get findRecipesFromPantry => 'What can I make from my pantry?';

  @override
  String get findRecipesNoResults => 'No recipes found — try different terms';

  @override
  String get findRecipesPantryEmpty =>
      'Your pantry is empty — add some items first';

  @override
  String get findRecipesNoLink => 'No web link for this recipe';

  @override
  String get findRecipesOpenFailed => 'Could not open the link';

  @override
  String findRecipesLookupFailed(String message) {
    return 'Lookup failed: $message';
  }

  @override
  String get findRecipesEmptyHint =>
      'Search for a dish, or tap \"What can I make\"\nfor ideas from what you have.';

  @override
  String get findRecipesHaveAll => 'You have everything!';

  @override
  String findRecipesMissingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Missing $count ingredients',
      one: 'Missing 1 ingredient',
    );
    return '$_temp0';
  }

  @override
  String get shoppingReorderTooltip => 'Reorder previous items';

  @override
  String get shoppingMoveToPantryTooltip => 'Move checked to pantry';

  @override
  String get shoppingClearCheckedTooltip => 'Clear checked items';

  @override
  String shoppingClearedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Cleared $count checked items',
      one: 'Cleared 1 checked item',
    );
    return '$_temp0';
  }

  @override
  String get shoppingEmptyTitle => 'Your shopping list is empty';

  @override
  String get shoppingEmptyHint => 'Tap + to add something to buy';

  @override
  String shoppingDupPantryTitle(String name) {
    return '\"$name\" is already in your pantry';
  }

  @override
  String get shoppingDupPantryBody =>
      'Add its quantity to the existing item, or skip it?';

  @override
  String get shoppingAddQuantity => 'Add quantity';

  @override
  String shoppingPantryUpdated(String summary) {
    return 'Pantry updated — $summary';
  }

  @override
  String shoppingSummaryAdded(int count) {
    return '$count added';
  }

  @override
  String shoppingSummaryMerged(int count) {
    return '$count merged';
  }

  @override
  String shoppingSummarySkipped(int count) {
    return '$count skipped';
  }

  @override
  String get shoppingSummarySeparator => ', ';

  @override
  String get shoppingAddTitle => 'Add to shopping list';

  @override
  String get shoppingEditTitle => 'Edit item';

  @override
  String get shoppingItemLabel => 'Item *';

  @override
  String get shoppingTakePhoto => 'Take a photo';

  @override
  String get shoppingChooseFromGallery => 'Choose from gallery';

  @override
  String get shoppingCameraPermissionNeeded =>
      'Camera permission is needed to take a photo';

  @override
  String get shoppingIdentifying => 'Identifying…';

  @override
  String get shoppingTakePhotoToIdentify => 'Take a photo to identify';

  @override
  String get shoppingCouldNotIdentify =>
      'Couldn\'t identify the item — enter it manually';

  @override
  String shoppingIdentified(String name, int percent) {
    return 'Identified: $name ($percent% sure)';
  }

  @override
  String shoppingPhotoIdFailed(String message) {
    return 'Photo ID failed: $message. You can still add it manually.';
  }

  @override
  String get shoppingStoreOptional => 'Store (optional)';

  @override
  String get shoppingPickFromSavedStores => 'Pick from saved stores';

  @override
  String get shoppingQuantity => 'Quantity';

  @override
  String get shoppingNoteOptional => 'Note (optional) e.g. \"the big box\"';

  @override
  String shoppingNoMatches(String query) {
    return 'No items match \"$query\"';
  }

  @override
  String shoppingDupListTitle(String name) {
    return '\"$name\" is already on your shopping list';
  }

  @override
  String get shoppingDupListBody => 'Skip it, or add it anyway?';

  @override
  String get shoppingAddAnyway => 'Add anyway';

  @override
  String shoppingAddedToList(String name) {
    return 'Added \"$name\" to shopping list';
  }

  @override
  String shoppingMovedToList(String name) {
    return 'Moved \"$name\" to shopping list';
  }

  @override
  String shoppingMovedQtyToList(String quantity, String name) {
    return 'Moved $quantity of \"$name\" to shopping list';
  }

  @override
  String get reorderTitle => 'Reorder';

  @override
  String get reorderSearchHint => 'Search items…';

  @override
  String get reorderEmpty =>
      'Nothing to reorder yet.\nItems you add to your list will show up here.';

  @override
  String reorderItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get reorderForgetItem => 'Forget this item';

  @override
  String reorderAdded(String name) {
    return 'Added \"$name\" to your list';
  }

  @override
  String get runningLowTitle => 'Running low?';

  @override
  String get runningLowSearchHint => 'Find an item to add to the list…';

  @override
  String get runningLowPantryEmpty => 'Your pantry is empty';

  @override
  String runningLowAddToList(String name) {
    return 'Add \"$name\" to shopping list';
  }

  @override
  String get imageLoadFailed => 'Could not load image';

  @override
  String get plannerTitle => 'Meal planner';
}
