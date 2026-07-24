import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Stashpot'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Your home pantry, always in sync'**
  String get appTagline;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navPantry.
  ///
  /// In en, this message translates to:
  /// **'Pantry'**
  String get navPantry;

  /// No description provided for @navShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get navShopping;

  /// No description provided for @navRecipes.
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get navRecipes;

  /// No description provided for @navPlanner.
  ///
  /// In en, this message translates to:
  /// **'Planner'**
  String get navPlanner;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get commonSaving;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get commonRename;

  /// No description provided for @commonUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get commonUndo;

  /// No description provided for @commonSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get commonSkip;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get commonLater;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String commonError(String message);

  /// No description provided for @categoryFruit.
  ///
  /// In en, this message translates to:
  /// **'Fruit'**
  String get categoryFruit;

  /// No description provided for @categoryVegetable.
  ///
  /// In en, this message translates to:
  /// **'Vegetables'**
  String get categoryVegetable;

  /// No description provided for @categoryMeat.
  ///
  /// In en, this message translates to:
  /// **'Meat & Fish'**
  String get categoryMeat;

  /// No description provided for @categoryDairy.
  ///
  /// In en, this message translates to:
  /// **'Dairy & Eggs'**
  String get categoryDairy;

  /// No description provided for @categoryBakery.
  ///
  /// In en, this message translates to:
  /// **'Bakery'**
  String get categoryBakery;

  /// No description provided for @categoryPantry.
  ///
  /// In en, this message translates to:
  /// **'Dry Goods'**
  String get categoryPantry;

  /// No description provided for @categoryFrozen.
  ///
  /// In en, this message translates to:
  /// **'Frozen'**
  String get categoryFrozen;

  /// No description provided for @categoryBeverages.
  ///
  /// In en, this message translates to:
  /// **'Beverages'**
  String get categoryBeverages;

  /// No description provided for @categorySnacks.
  ///
  /// In en, this message translates to:
  /// **'Snacks'**
  String get categorySnacks;

  /// No description provided for @categoryHousehold.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get categoryHousehold;

  /// No description provided for @categoryPersonalCare.
  ///
  /// In en, this message translates to:
  /// **'Personal Care'**
  String get categoryPersonalCare;

  /// No description provided for @categoryProduce.
  ///
  /// In en, this message translates to:
  /// **'Produce'**
  String get categoryProduce;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @locationFridge.
  ///
  /// In en, this message translates to:
  /// **'Fridge'**
  String get locationFridge;

  /// No description provided for @locationFreezer.
  ///
  /// In en, this message translates to:
  /// **'Freezer'**
  String get locationFreezer;

  /// No description provided for @locationPantry.
  ///
  /// In en, this message translates to:
  /// **'Pantry'**
  String get locationPantry;

  /// No description provided for @locationOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get locationOther;

  /// No description provided for @mealBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get mealBreakfast;

  /// No description provided for @mealLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get mealLunch;

  /// No description provided for @mealDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get mealDinner;

  /// No description provided for @mealSnack.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get mealSnack;

  /// No description provided for @unitItem.
  ///
  /// In en, this message translates to:
  /// **'item'**
  String get unitItem;

  /// No description provided for @unitG.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get unitG;

  /// No description provided for @unitKg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get unitKg;

  /// No description provided for @unitMl.
  ///
  /// In en, this message translates to:
  /// **'ml'**
  String get unitMl;

  /// No description provided for @unitL.
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get unitL;

  /// No description provided for @unitOz.
  ///
  /// In en, this message translates to:
  /// **'oz'**
  String get unitOz;

  /// No description provided for @unitLb.
  ///
  /// In en, this message translates to:
  /// **'lb'**
  String get unitLb;

  /// No description provided for @unitCup.
  ///
  /// In en, this message translates to:
  /// **'cup'**
  String get unitCup;

  /// No description provided for @unitBunch.
  ///
  /// In en, this message translates to:
  /// **'bunch'**
  String get unitBunch;

  /// No description provided for @noStoreGroup.
  ///
  /// In en, this message translates to:
  /// **'Other / no store'**
  String get noStoreGroup;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsVersion(String version);

  /// No description provided for @settingsInviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite friends'**
  String get settingsInviteFriends;

  /// No description provided for @settingsInviteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share your household invite code'**
  String get settingsInviteSubtitle;

  /// No description provided for @settingsPantryLocations.
  ///
  /// In en, this message translates to:
  /// **'Pantry locations'**
  String get settingsPantryLocations;

  /// No description provided for @settingsPantryLocationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add or edit your own storage locations'**
  String get settingsPantryLocationsSubtitle;

  /// No description provided for @settingsSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsSignOut;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the app language'**
  String get settingsLanguageSubtitle;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageChineseTraditional.
  ///
  /// In en, this message translates to:
  /// **'繁體中文'**
  String get languageChineseTraditional;

  /// No description provided for @addItemBarcodeNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'No product found for {code}'**
  String addItemBarcodeNotFoundTitle(String code);

  /// No description provided for @addItemBarcodeNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'Local and imported products often aren\'t in the barcode database. You can identify it from a photo of the packaging instead.'**
  String get addItemBarcodeNotFoundBody;

  /// No description provided for @addItemTakePhotoInstead.
  ///
  /// In en, this message translates to:
  /// **'Take a photo instead'**
  String get addItemTakePhotoInstead;

  /// No description provided for @addItemEnterManually.
  ///
  /// In en, this message translates to:
  /// **'Enter manually'**
  String get addItemEnterManually;

  /// No description provided for @homeGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get homeGreetingMorning;

  /// No description provided for @homeGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get homeGreetingAfternoon;

  /// No description provided for @homeGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get homeGreetingEvening;

  /// No description provided for @homeGreetingNamed.
  ///
  /// In en, this message translates to:
  /// **'{greeting}, {name}'**
  String homeGreetingNamed(String greeting, String name);

  /// No description provided for @homeStatExpiring.
  ///
  /// In en, this message translates to:
  /// **'Expiring'**
  String get homeStatExpiring;

  /// No description provided for @homeRunningLow.
  ///
  /// In en, this message translates to:
  /// **'Running low?'**
  String get homeRunningLow;

  /// No description provided for @homeRunningLowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find an item and add it to the shopping list'**
  String get homeRunningLowSubtitle;

  /// No description provided for @homeWhatsForDinner.
  ///
  /// In en, this message translates to:
  /// **'What\'s for dinner'**
  String get homeWhatsForDinner;

  /// No description provided for @homeRecipeOfTheDay.
  ///
  /// In en, this message translates to:
  /// **'Recipe of the day'**
  String get homeRecipeOfTheDay;

  /// No description provided for @homeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get homeToday;

  /// No description provided for @homeTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get homeTomorrow;

  /// No description provided for @homeNothingPlanned.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned'**
  String get homeNothingPlanned;

  /// No description provided for @homeQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get homeQuickActions;

  /// No description provided for @homeFindRecipes.
  ///
  /// In en, this message translates to:
  /// **'Find recipes'**
  String get homeFindRecipes;

  /// No description provided for @homePlanAMeal.
  ///
  /// In en, this message translates to:
  /// **'Plan a meal'**
  String get homePlanAMeal;

  /// No description provided for @homeShoppingList.
  ///
  /// In en, this message translates to:
  /// **'Shopping list'**
  String get homeShoppingList;

  /// No description provided for @homeAddToPantry.
  ///
  /// In en, this message translates to:
  /// **'Add to pantry'**
  String get homeAddToPantry;

  /// No description provided for @homeAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get homeAddItem;

  /// No description provided for @homeScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get homeScan;

  /// No description provided for @homePhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get homePhoto;

  /// No description provided for @locationsBuiltIn.
  ///
  /// In en, this message translates to:
  /// **'Built-in'**
  String get locationsBuiltIn;

  /// No description provided for @locationsYours.
  ///
  /// In en, this message translates to:
  /// **'Your locations'**
  String get locationsYours;

  /// No description provided for @locationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No custom locations yet. Tap + to add one.'**
  String get locationsEmpty;

  /// No description provided for @locationsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add location'**
  String get locationsAdd;

  /// No description provided for @locationsNew.
  ///
  /// In en, this message translates to:
  /// **'New location'**
  String get locationsNew;

  /// No description provided for @locationsRename.
  ///
  /// In en, this message translates to:
  /// **'Rename location'**
  String get locationsRename;

  /// No description provided for @locationsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Garage shelf'**
  String get locationsHint;

  /// No description provided for @locationsRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed location \"{name}\"'**
  String locationsRemoved(String name);

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get authEmailInvalid;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be 6+ characters'**
  String get authPasswordTooShort;

  /// No description provided for @authPasswordMin.
  ///
  /// In en, this message translates to:
  /// **'Minimum 6 characters'**
  String get authPasswordMin;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authNoAccountRegister.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get authNoAccountRegister;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccount;

  /// No description provided for @authYourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get authYourName;

  /// No description provided for @authNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get authNameRequired;

  /// No description provided for @authHaveAccountSignIn.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get authHaveAccountSignIn;

  /// No description provided for @authHouseholdNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a household name'**
  String get authHouseholdNameRequired;

  /// No description provided for @authInviteCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an invite code'**
  String get authInviteCodeRequired;

  /// No description provided for @authSetUpHousehold.
  ///
  /// In en, this message translates to:
  /// **'Set up your household'**
  String get authSetUpHousehold;

  /// No description provided for @authSetUpHouseholdSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a new household or join your partner\'s existing one.'**
  String get authSetUpHouseholdSubtitle;

  /// No description provided for @authStartNewHousehold.
  ///
  /// In en, this message translates to:
  /// **'Start a new household'**
  String get authStartNewHousehold;

  /// No description provided for @authHouseholdNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Household name (e.g. \"The Smiths\")'**
  String get authHouseholdNameLabel;

  /// No description provided for @authCreateHousehold.
  ///
  /// In en, this message translates to:
  /// **'Create household'**
  String get authCreateHousehold;

  /// No description provided for @authOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get authOr;

  /// No description provided for @authJoinExisting.
  ///
  /// In en, this message translates to:
  /// **'Join an existing household'**
  String get authJoinExisting;

  /// No description provided for @authJoinExistingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ask the person who set it up to share their invite code.'**
  String get authJoinExistingSubtitle;

  /// No description provided for @authInviteCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get authInviteCodeLabel;

  /// No description provided for @authJoinHousehold.
  ///
  /// In en, this message translates to:
  /// **'Join household'**
  String get authJoinHousehold;

  /// No description provided for @inviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite your partner'**
  String get inviteTitle;

  /// No description provided for @inviteBody.
  ///
  /// In en, this message translates to:
  /// **'Share this code so they can join your pantry. They register their own account, then enter it under \"Join an existing household\".'**
  String get inviteBody;

  /// No description provided for @inviteCopyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get inviteCopyCode;

  /// No description provided for @inviteCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite code copied'**
  String get inviteCopied;

  /// No description provided for @swipeRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed {label}'**
  String swipeRemoved(String label);

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailable;

  /// No description provided for @updateStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting download…'**
  String get updateStarting;

  /// No description provided for @updateDownloadingPercent.
  ///
  /// In en, this message translates to:
  /// **'Downloading… {percent}%'**
  String updateDownloadingPercent(String percent);

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get updateNow;

  /// No description provided for @pantryGroupByTooltip.
  ///
  /// In en, this message translates to:
  /// **'Group by'**
  String get pantryGroupByTooltip;

  /// No description provided for @pantryGroupByLocation.
  ///
  /// In en, this message translates to:
  /// **'Group by location'**
  String get pantryGroupByLocation;

  /// No description provided for @pantryGroupByCategory.
  ///
  /// In en, this message translates to:
  /// **'Group by category'**
  String get pantryGroupByCategory;

  /// No description provided for @pantryGroupByStore.
  ///
  /// In en, this message translates to:
  /// **'Group by store'**
  String get pantryGroupByStore;

  /// No description provided for @pantryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your pantry is empty'**
  String get pantryEmptyTitle;

  /// No description provided for @pantryEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first item'**
  String get pantryEmptySubtitle;

  /// No description provided for @pantryExpiringBanner.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} item expiring soon or expired} other{{count} items expiring soon or expired}}'**
  String pantryExpiringBanner(int count);

  /// No description provided for @pantryNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No items match \"{query}\"'**
  String pantryNoMatches(String query);

  /// No description provided for @pantrySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search pantry…'**
  String get pantrySearchHint;

  /// No description provided for @pantryAddItemFab.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get pantryAddItemFab;

  /// No description provided for @pantryExpiresToday.
  ///
  /// In en, this message translates to:
  /// **'Expires today'**
  String get pantryExpiresToday;

  /// No description provided for @pantryExpiresTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Expires tomorrow'**
  String get pantryExpiresTomorrow;

  /// No description provided for @pantryExpiresInDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{Expires in {days} day} other{Expires in {days} days}}'**
  String pantryExpiresInDays(int days);

  /// No description provided for @pantryExpiredDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{Expired {days} day ago} other{Expired {days} days ago}}'**
  String pantryExpiredDaysAgo(int days);

  /// No description provided for @pantryMoreTooltip.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get pantryMoreTooltip;

  /// No description provided for @pantryAddToShoppingList.
  ///
  /// In en, this message translates to:
  /// **'Add to shopping list'**
  String get pantryAddToShoppingList;

  /// No description provided for @pantryMoveToShoppingList.
  ///
  /// In en, this message translates to:
  /// **'Remove from pantry & add to shopping list'**
  String get pantryMoveToShoppingList;

  /// No description provided for @pantryViewPhoto.
  ///
  /// In en, this message translates to:
  /// **'View photo'**
  String get pantryViewPhoto;

  /// No description provided for @addItemTitleAdd.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItemTitleAdd;

  /// No description provided for @addItemTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get addItemTitleEdit;

  /// No description provided for @addItemNewLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'New location'**
  String get addItemNewLocationTitle;

  /// No description provided for @addItemNewLocationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Garage shelf'**
  String get addItemNewLocationHint;

  /// No description provided for @addItemTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get addItemTakePhoto;

  /// No description provided for @addItemChooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get addItemChooseFromGallery;

  /// No description provided for @addItemCameraPermissionPhoto.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is needed to take a photo'**
  String get addItemCameraPermissionPhoto;

  /// No description provided for @addItemCameraPermissionScan.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is needed to scan'**
  String get addItemCameraPermissionScan;

  /// No description provided for @addItemPhotoUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Photo upload failed: {error}'**
  String addItemPhotoUploadFailed(String error);

  /// No description provided for @addItemIdentifyFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t identify the food — enter it manually'**
  String get addItemIdentifyFailed;

  /// No description provided for @addItemIdentified.
  ///
  /// In en, this message translates to:
  /// **'Identified: {name} ({percent}% sure)'**
  String addItemIdentified(String name, int percent);

  /// No description provided for @addItemPhotoIdError.
  ///
  /// In en, this message translates to:
  /// **'Photo ID failed: {error}. You can still add it manually.'**
  String addItemPhotoIdError(String error);

  /// No description provided for @addItemBarcodeUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the barcode — fill the frame, hold steady in good light, or enter it manually'**
  String get addItemBarcodeUnreadable;

  /// No description provided for @addItemNoProductFound.
  ///
  /// In en, this message translates to:
  /// **'No product found for {code} — enter details manually'**
  String addItemNoProductFound(String code);

  /// No description provided for @addItemProductFound.
  ///
  /// In en, this message translates to:
  /// **'Found: {name}'**
  String addItemProductFound(String name);

  /// No description provided for @addItemLookupError.
  ///
  /// In en, this message translates to:
  /// **'Lookup failed: {error}. You can still add it manually.'**
  String addItemLookupError(String error);

  /// No description provided for @addItemNoSavedStores.
  ///
  /// In en, this message translates to:
  /// **'No saved stores yet. Type a store name below and you\'ll be asked to add it to the list.'**
  String get addItemNoSavedStores;

  /// No description provided for @addItemPickStore.
  ///
  /// In en, this message translates to:
  /// **'Pick a store'**
  String get addItemPickStore;

  /// No description provided for @addItemPickStoreTooltip.
  ///
  /// In en, this message translates to:
  /// **'Pick from saved stores'**
  String get addItemPickStoreTooltip;

  /// No description provided for @addItemLookingUp.
  ///
  /// In en, this message translates to:
  /// **'Looking up product…'**
  String get addItemLookingUp;

  /// No description provided for @addItemScanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode'**
  String get addItemScanBarcode;

  /// No description provided for @addItemScanned.
  ///
  /// In en, this message translates to:
  /// **'Scanned: {code} (rescan)'**
  String addItemScanned(String code);

  /// No description provided for @addItemIdentifying.
  ///
  /// In en, this message translates to:
  /// **'Identifying…'**
  String get addItemIdentifying;

  /// No description provided for @addItemIdentifyByPhoto.
  ///
  /// In en, this message translates to:
  /// **'Identify by photo'**
  String get addItemIdentifyByPhoto;

  /// No description provided for @addItemNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Item name *'**
  String get addItemNameLabel;

  /// No description provided for @addItemNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get addItemNameRequired;

  /// No description provided for @addItemQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get addItemQuantityLabel;

  /// No description provided for @addItemQuantityInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get addItemQuantityInvalid;

  /// No description provided for @addItemUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get addItemUnitLabel;

  /// No description provided for @addItemFoodTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Food type'**
  String get addItemFoodTypeLabel;

  /// No description provided for @addItemLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get addItemLocationLabel;

  /// No description provided for @addItemAddLocation.
  ///
  /// In en, this message translates to:
  /// **'Add location…'**
  String get addItemAddLocation;

  /// No description provided for @addItemStoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Store (optional)'**
  String get addItemStoreLabel;

  /// No description provided for @addItemStoreHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Costco, Walmart, Trader Joe\'s'**
  String get addItemStoreHint;

  /// No description provided for @addItemExpiryLabel.
  ///
  /// In en, this message translates to:
  /// **'Expiry date (optional)'**
  String get addItemExpiryLabel;

  /// No description provided for @addItemExpiresOn.
  ///
  /// In en, this message translates to:
  /// **'Expires: {date}'**
  String addItemExpiresOn(DateTime date);

  /// No description provided for @addItemNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get addItemNotesLabel;

  /// No description provided for @addItemPhotoAttached.
  ///
  /// In en, this message translates to:
  /// **'Photo attached'**
  String get addItemPhotoAttached;

  /// No description provided for @addItemRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get addItemRemovePhoto;

  /// No description provided for @addItemUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get addItemUploading;

  /// No description provided for @addItemAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addItemAddPhoto;

  /// No description provided for @addItemReplacePhoto.
  ///
  /// In en, this message translates to:
  /// **'Replace photo'**
  String get addItemReplacePhoto;

  /// No description provided for @addItemSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get addItemSaveChanges;

  /// No description provided for @addItemAddToPantry.
  ///
  /// In en, this message translates to:
  /// **'Add to pantry'**
  String get addItemAddToPantry;

  /// No description provided for @qtySheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get qtySheetTitle;

  /// No description provided for @qtyMoveTitle.
  ///
  /// In en, this message translates to:
  /// **'How many to move?'**
  String get qtyMoveTitle;

  /// No description provided for @qtyMoveAvailable.
  ///
  /// In en, this message translates to:
  /// **'You have {amount}. The rest stays in your pantry.'**
  String qtyMoveAvailable(String amount);

  /// No description provided for @qtyMoveAll.
  ///
  /// In en, this message translates to:
  /// **'Move all to shopping list'**
  String get qtyMoveAll;

  /// No description provided for @qtyMoveAmount.
  ///
  /// In en, this message translates to:
  /// **'Move {amount} to shopping list'**
  String qtyMoveAmount(String amount);

  /// No description provided for @plannerToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get plannerToday;

  /// No description provided for @plannerTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get plannerTomorrow;

  /// No description provided for @plannerYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get plannerYesterday;

  /// No description provided for @plannerFormatMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get plannerFormatMonth;

  /// No description provided for @plannerFormatTwoWeeks.
  ///
  /// In en, this message translates to:
  /// **'2 weeks'**
  String get plannerFormatTwoWeeks;

  /// No description provided for @plannerFormatWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get plannerFormatWeek;

  /// No description provided for @plannerAddMeal.
  ///
  /// In en, this message translates to:
  /// **'Add meal'**
  String get plannerAddMeal;

  /// No description provided for @plannerNothingPlanned.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned for this day'**
  String get plannerNothingPlanned;

  /// No description provided for @plannerMoveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Move to another day'**
  String get plannerMoveTooltip;

  /// No description provided for @plannerOpenRecipeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open recipe'**
  String get plannerOpenRecipeTooltip;

  /// No description provided for @plannerRecipeGone.
  ///
  /// In en, this message translates to:
  /// **'That recipe is no longer saved'**
  String get plannerRecipeGone;

  /// No description provided for @plannerSwapped.
  ///
  /// In en, this message translates to:
  /// **'Swapped \"{a}\" with \"{b}\"'**
  String plannerSwapped(String a, String b);

  /// No description provided for @plannerMoved.
  ///
  /// In en, this message translates to:
  /// **'Moved \"{title}\" to {day}'**
  String plannerMoved(String title, String day);

  /// No description provided for @plannerAddedMeals.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Added 1 meal to the planner} other{Added {count} meals to the planner}}'**
  String plannerAddedMeals(int count);

  /// No description provided for @mealPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan a meal'**
  String get mealPlanTitle;

  /// No description provided for @mealEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit meal'**
  String get mealEditTitle;

  /// No description provided for @mealFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Meal'**
  String get mealFieldLabel;

  /// No description provided for @mealFieldHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Tacos'**
  String get mealFieldHint;

  /// No description provided for @mealChooseSavedRecipe.
  ///
  /// In en, this message translates to:
  /// **'Choose a saved recipe'**
  String get mealChooseSavedRecipe;

  /// No description provided for @mealPickRecipe.
  ///
  /// In en, this message translates to:
  /// **'Pick a recipe'**
  String get mealPickRecipe;

  /// No description provided for @mealNoSavedRecipes.
  ///
  /// In en, this message translates to:
  /// **'No saved recipes yet — add some in the Recipes tab'**
  String get mealNoSavedRecipes;

  /// No description provided for @mealEnterOrPick.
  ///
  /// In en, this message translates to:
  /// **'Enter a meal or pick a recipe'**
  String get mealEnterOrPick;

  /// No description provided for @mealNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get mealNotesLabel;

  /// No description provided for @mealNotesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. double the recipe, use leftovers'**
  String get mealNotesHint;

  /// No description provided for @mealSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get mealSaveChanges;

  /// No description provided for @mealAddToPlan.
  ///
  /// In en, this message translates to:
  /// **'Add to plan'**
  String get mealAddToPlan;

  /// No description provided for @mealMoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Move \"{title}\" to…'**
  String mealMoveTitle(String title);

  /// No description provided for @mealMoveSwapHint.
  ///
  /// In en, this message translates to:
  /// **'If that day already has a {mealType} planned, the two swap places.'**
  String mealMoveSwapHint(String mealType);

  /// No description provided for @mealMoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Move here'**
  String get mealMoveConfirm;

  /// No description provided for @rouletteTitle.
  ///
  /// In en, this message translates to:
  /// **'Meal roulette'**
  String get rouletteTitle;

  /// No description provided for @rouletteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Meal roulette (auto-fill)'**
  String get rouletteTooltip;

  /// No description provided for @rouletteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-fill empty days with a random pick from meals you have planned before.'**
  String get rouletteSubtitle;

  /// No description provided for @rouletteFillNext.
  ///
  /// In en, this message translates to:
  /// **'Fill the next'**
  String get rouletteFillNext;

  /// No description provided for @rouletteDayUnit.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{day} other{days}}'**
  String rouletteDayUnit(int count);

  /// No description provided for @rouletteWhichMeals.
  ///
  /// In en, this message translates to:
  /// **'Fill which meals?'**
  String get rouletteWhichMeals;

  /// No description provided for @rouletteTypeJoiner.
  ///
  /// In en, this message translates to:
  /// **' or '**
  String get rouletteTypeJoiner;

  /// No description provided for @rouletteNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No {types} meals in your planner yet — plan a few first so the roulette has something to draw from.'**
  String rouletteNoHistory(String types);

  /// No description provided for @rouletteNothingToFill.
  ///
  /// In en, this message translates to:
  /// **'Those days are already planned for the meals you picked — nothing to fill.'**
  String get rouletteNothingToFill;

  /// No description provided for @rouletteToAdd.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 to add} other{{count} to add}}'**
  String rouletteToAdd(int count);

  /// No description provided for @rouletteRoll.
  ///
  /// In en, this message translates to:
  /// **'Roll'**
  String get rouletteRoll;

  /// No description provided for @rouletteReRoll.
  ///
  /// In en, this message translates to:
  /// **'Re-roll'**
  String get rouletteReRoll;

  /// No description provided for @rouletteAddToPlanner.
  ///
  /// In en, this message translates to:
  /// **'Add to planner'**
  String get rouletteAddToPlanner;

  /// No description provided for @recipeAddByLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Add recipe by link'**
  String get recipeAddByLinkTitle;

  /// No description provided for @recipeAddByLinkHint.
  ///
  /// In en, this message translates to:
  /// **'Paste a recipe URL'**
  String get recipeAddByLinkHint;

  /// No description provided for @recipeAddByLinkTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add by link'**
  String get recipeAddByLinkTooltip;

  /// No description provided for @recipeLinkNeedsHttp.
  ///
  /// In en, this message translates to:
  /// **'Enter a full link starting with http'**
  String get recipeLinkNeedsHttp;

  /// No description provided for @recipeSavingLink.
  ///
  /// In en, this message translates to:
  /// **'Saving link…'**
  String get recipeSavingLink;

  /// No description provided for @recipeSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved \"{name}\"'**
  String recipeSaved(String name);

  /// No description provided for @recipeLinkSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save link: {message}'**
  String recipeLinkSaveFailed(String message);

  /// No description provided for @recipeWrite.
  ///
  /// In en, this message translates to:
  /// **'Write a recipe'**
  String get recipeWrite;

  /// No description provided for @recipeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No saved recipes yet'**
  String get recipeEmptyTitle;

  /// No description provided for @recipeEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Find recipes\" to search the web'**
  String get recipeEmptyHint;

  /// No description provided for @recipeRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed {name}'**
  String recipeRemoved(String name);

  /// No description provided for @recipeShoppingNote.
  ///
  /// In en, this message translates to:
  /// **'for {name}'**
  String recipeShoppingNote(String name);

  /// No description provided for @recipeAddedToShopping.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Added 1 item to your shopping list} other{Added {count} items to your shopping list}}'**
  String recipeAddedToShopping(int count);

  /// No description provided for @recipeOpenOriginalTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open original in browser'**
  String get recipeOpenOriginalTooltip;

  /// No description provided for @recipeEditTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get recipeEditTooltip;

  /// No description provided for @recipeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String recipeMinutes(int count);

  /// No description provided for @recipeLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this recipe — check your connection and retry.'**
  String get recipeLoadFailed;

  /// No description provided for @recipeNoStructuredData.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read a recipe from this page. Some sites don\'t share their recipe data — open it in your browser to view it.'**
  String get recipeNoStructuredData;

  /// Shown above an imported recipe whose text was machine-translated or read out of the page by AI.
  ///
  /// In en, this message translates to:
  /// **'Read by AI from the page — check the quantities against the original.'**
  String get recipeAiTranslated;

  /// Under the spinner while a recipe page is fetched and, if needed, translated.
  ///
  /// In en, this message translates to:
  /// **'Reading the recipe…'**
  String get recipeReadingPage;

  /// No description provided for @recipeOpenInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get recipeOpenInBrowser;

  /// No description provided for @recipeIngredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get recipeIngredients;

  /// No description provided for @recipeHaveCount.
  ///
  /// In en, this message translates to:
  /// **'Have {have}/{total}'**
  String recipeHaveCount(int have, int total);

  /// No description provided for @recipeAddMissing.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Add 1 missing to shopping list} other{Add {count} missing to shopping list}}'**
  String recipeAddMissing(int count);

  /// No description provided for @recipeAddAllIngredients.
  ///
  /// In en, this message translates to:
  /// **'Add ALL ingredients to shopping list'**
  String get recipeAddAllIngredients;

  /// No description provided for @recipeInstructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get recipeInstructions;

  /// No description provided for @recipeOnListTooltip.
  ///
  /// In en, this message translates to:
  /// **'On shopping list — tap to add again'**
  String get recipeOnListTooltip;

  /// No description provided for @recipeAddToShoppingTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add to shopping list'**
  String get recipeAddToShoppingTooltip;

  /// No description provided for @recipeNutritionTitle.
  ///
  /// In en, this message translates to:
  /// **'Nutrition (per serving)'**
  String get recipeNutritionTitle;

  /// No description provided for @recipeCalories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get recipeCalories;

  /// No description provided for @recipeProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get recipeProtein;

  /// No description provided for @recipeCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get recipeCarbs;

  /// No description provided for @recipeFat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get recipeFat;

  /// No description provided for @recipeManualEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit recipe'**
  String get recipeManualEditTitle;

  /// No description provided for @recipeManualNeedName.
  ///
  /// In en, this message translates to:
  /// **'Give the recipe a name'**
  String get recipeManualNeedName;

  /// No description provided for @recipeManualNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Recipe name *'**
  String get recipeManualNameLabel;

  /// No description provided for @recipeManualServingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Servings (optional)'**
  String get recipeManualServingsLabel;

  /// No description provided for @recipeManualIngredientsLabel.
  ///
  /// In en, this message translates to:
  /// **'Ingredients (one per line)'**
  String get recipeManualIngredientsLabel;

  /// No description provided for @recipeManualStepsLabel.
  ///
  /// In en, this message translates to:
  /// **'Steps (one per line)'**
  String get recipeManualStepsLabel;

  /// No description provided for @recipeManualSave.
  ///
  /// In en, this message translates to:
  /// **'Save recipe'**
  String get recipeManualSave;

  /// No description provided for @findRecipesTitle.
  ///
  /// In en, this message translates to:
  /// **'Find recipes'**
  String get findRecipesTitle;

  /// No description provided for @findRecipesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search a dish, or paste a recipe link'**
  String get findRecipesSearchHint;

  /// No description provided for @findRecipesSearchButton.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get findRecipesSearchButton;

  /// No description provided for @findRecipesFromPantry.
  ///
  /// In en, this message translates to:
  /// **'What can I make from my pantry?'**
  String get findRecipesFromPantry;

  /// No description provided for @findRecipesNoResults.
  ///
  /// In en, this message translates to:
  /// **'No recipes found — try different terms'**
  String get findRecipesNoResults;

  /// No description provided for @findRecipesPantryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your pantry is empty — add some items first'**
  String get findRecipesPantryEmpty;

  /// No description provided for @findRecipesNoLink.
  ///
  /// In en, this message translates to:
  /// **'No web link for this recipe'**
  String get findRecipesNoLink;

  /// No description provided for @findRecipesOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link'**
  String get findRecipesOpenFailed;

  /// No description provided for @findRecipesLookupFailed.
  ///
  /// In en, this message translates to:
  /// **'Lookup failed: {message}'**
  String findRecipesLookupFailed(String message);

  /// No description provided for @findRecipesEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a dish, or tap \"What can I make\"\nfor ideas from what you have.'**
  String get findRecipesEmptyHint;

  /// No description provided for @findRecipesHaveAll.
  ///
  /// In en, this message translates to:
  /// **'You have everything!'**
  String get findRecipesHaveAll;

  /// No description provided for @findRecipesMissingCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Missing 1 ingredient} other{Missing {count} ingredients}}'**
  String findRecipesMissingCount(int count);

  /// No description provided for @shoppingReorderTooltip.
  ///
  /// In en, this message translates to:
  /// **'Reorder previous items'**
  String get shoppingReorderTooltip;

  /// No description provided for @shoppingMoveToPantryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Move checked to pantry'**
  String get shoppingMoveToPantryTooltip;

  /// No description provided for @shoppingClearCheckedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear checked items'**
  String get shoppingClearCheckedTooltip;

  /// No description provided for @shoppingClearedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Cleared 1 checked item} other{Cleared {count} checked items}}'**
  String shoppingClearedCount(int count);

  /// No description provided for @shoppingEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your shopping list is empty'**
  String get shoppingEmptyTitle;

  /// No description provided for @shoppingEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add something to buy'**
  String get shoppingEmptyHint;

  /// No description provided for @shoppingDupPantryTitle.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" is already in your pantry'**
  String shoppingDupPantryTitle(String name);

  /// No description provided for @shoppingDupPantryBody.
  ///
  /// In en, this message translates to:
  /// **'Add its quantity to the existing item, or skip it?'**
  String get shoppingDupPantryBody;

  /// No description provided for @shoppingAddQuantity.
  ///
  /// In en, this message translates to:
  /// **'Add quantity'**
  String get shoppingAddQuantity;

  /// No description provided for @shoppingPantryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Pantry updated — {summary}'**
  String shoppingPantryUpdated(String summary);

  /// No description provided for @shoppingSummaryAdded.
  ///
  /// In en, this message translates to:
  /// **'{count} added'**
  String shoppingSummaryAdded(int count);

  /// No description provided for @shoppingSummaryMerged.
  ///
  /// In en, this message translates to:
  /// **'{count} merged'**
  String shoppingSummaryMerged(int count);

  /// No description provided for @shoppingSummarySkipped.
  ///
  /// In en, this message translates to:
  /// **'{count} skipped'**
  String shoppingSummarySkipped(int count);

  /// No description provided for @shoppingSummarySeparator.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get shoppingSummarySeparator;

  /// No description provided for @shoppingAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to shopping list'**
  String get shoppingAddTitle;

  /// No description provided for @shoppingEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get shoppingEditTitle;

  /// No description provided for @shoppingItemLabel.
  ///
  /// In en, this message translates to:
  /// **'Item *'**
  String get shoppingItemLabel;

  /// No description provided for @shoppingTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get shoppingTakePhoto;

  /// No description provided for @shoppingChooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get shoppingChooseFromGallery;

  /// No description provided for @shoppingCameraPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is needed to take a photo'**
  String get shoppingCameraPermissionNeeded;

  /// No description provided for @shoppingIdentifying.
  ///
  /// In en, this message translates to:
  /// **'Identifying…'**
  String get shoppingIdentifying;

  /// No description provided for @shoppingTakePhotoToIdentify.
  ///
  /// In en, this message translates to:
  /// **'Take a photo to identify'**
  String get shoppingTakePhotoToIdentify;

  /// No description provided for @shoppingCouldNotIdentify.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t identify the item — enter it manually'**
  String get shoppingCouldNotIdentify;

  /// No description provided for @shoppingIdentified.
  ///
  /// In en, this message translates to:
  /// **'Identified: {name} ({percent}% sure)'**
  String shoppingIdentified(String name, int percent);

  /// No description provided for @shoppingPhotoIdFailed.
  ///
  /// In en, this message translates to:
  /// **'Photo ID failed: {message}. You can still add it manually.'**
  String shoppingPhotoIdFailed(String message);

  /// No description provided for @shoppingStoreOptional.
  ///
  /// In en, this message translates to:
  /// **'Store (optional)'**
  String get shoppingStoreOptional;

  /// No description provided for @shoppingPickFromSavedStores.
  ///
  /// In en, this message translates to:
  /// **'Pick from saved stores'**
  String get shoppingPickFromSavedStores;

  /// No description provided for @shoppingQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get shoppingQuantity;

  /// No description provided for @shoppingNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional) e.g. \"the big box\"'**
  String get shoppingNoteOptional;

  /// No description provided for @shoppingNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No items match \"{query}\"'**
  String shoppingNoMatches(String query);

  /// No description provided for @shoppingDupListTitle.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" is already on your shopping list'**
  String shoppingDupListTitle(String name);

  /// No description provided for @shoppingDupListBody.
  ///
  /// In en, this message translates to:
  /// **'Skip it, or add it anyway?'**
  String get shoppingDupListBody;

  /// No description provided for @shoppingAddAnyway.
  ///
  /// In en, this message translates to:
  /// **'Add anyway'**
  String get shoppingAddAnyway;

  /// No description provided for @shoppingAddedToList.
  ///
  /// In en, this message translates to:
  /// **'Added \"{name}\" to shopping list'**
  String shoppingAddedToList(String name);

  /// No description provided for @shoppingMovedToList.
  ///
  /// In en, this message translates to:
  /// **'Moved \"{name}\" to shopping list'**
  String shoppingMovedToList(String name);

  /// No description provided for @shoppingMovedQtyToList.
  ///
  /// In en, this message translates to:
  /// **'Moved {quantity} of \"{name}\" to shopping list'**
  String shoppingMovedQtyToList(String quantity, String name);

  /// No description provided for @reorderTitle.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get reorderTitle;

  /// No description provided for @reorderSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search items…'**
  String get reorderSearchHint;

  /// No description provided for @reorderEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to reorder yet.\nItems you add to your list will show up here.'**
  String get reorderEmpty;

  /// No description provided for @reorderItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String reorderItemCount(int count);

  /// No description provided for @reorderForgetItem.
  ///
  /// In en, this message translates to:
  /// **'Forget this item'**
  String get reorderForgetItem;

  /// No description provided for @reorderAdded.
  ///
  /// In en, this message translates to:
  /// **'Added \"{name}\" to your list'**
  String reorderAdded(String name);

  /// No description provided for @runningLowTitle.
  ///
  /// In en, this message translates to:
  /// **'Running low?'**
  String get runningLowTitle;

  /// No description provided for @runningLowSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Find an item to add to the list…'**
  String get runningLowSearchHint;

  /// No description provided for @runningLowPantryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your pantry is empty'**
  String get runningLowPantryEmpty;

  /// No description provided for @runningLowAddToList.
  ///
  /// In en, this message translates to:
  /// **'Add \"{name}\" to shopping list'**
  String runningLowAddToList(String name);

  /// No description provided for @imageLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load image'**
  String get imageLoadFailed;

  /// No description provided for @plannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Meal planner'**
  String get plannerTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
