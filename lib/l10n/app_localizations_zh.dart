// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Stashpot';

  @override
  String get appTagline => '你的家庭食品櫃，隨時同步';

  @override
  String get navHome => '首頁';

  @override
  String get navPantry => '食品櫃';

  @override
  String get navShopping => '購物清單';

  @override
  String get navRecipes => '食譜';

  @override
  String get navPlanner => '菜單規劃';

  @override
  String get commonSave => '儲存';

  @override
  String get commonSaving => '儲存中…';

  @override
  String get commonAdd => '新增';

  @override
  String get commonCancel => '取消';

  @override
  String get commonDelete => '刪除';

  @override
  String get commonRename => '重新命名';

  @override
  String get commonUndo => '復原';

  @override
  String get commonSkip => '略過';

  @override
  String get commonClose => '關閉';

  @override
  String get commonLater => '稍後';

  @override
  String get commonRetry => '重試';

  @override
  String get commonDone => '完成';

  @override
  String commonError(String message) {
    return '錯誤：$message';
  }

  @override
  String get categoryFruit => '水果';

  @override
  String get categoryVegetable => '蔬菜';

  @override
  String get categoryMeat => '肉類與海鮮';

  @override
  String get categoryDairy => '乳製品與蛋';

  @override
  String get categoryBakery => '烘焙麵包';

  @override
  String get categoryPantry => '乾貨';

  @override
  String get categoryFrozen => '冷凍食品';

  @override
  String get categoryBeverages => '飲料';

  @override
  String get categorySnacks => '零食';

  @override
  String get categoryHousehold => '家用品';

  @override
  String get categoryPersonalCare => '個人護理';

  @override
  String get categoryProduce => '生鮮蔬果';

  @override
  String get categoryOther => '其他';

  @override
  String get locationFridge => '冰箱冷藏';

  @override
  String get locationFreezer => '冷凍庫';

  @override
  String get locationPantry => '食品櫃';

  @override
  String get locationOther => '其他';

  @override
  String get mealBreakfast => '早餐';

  @override
  String get mealLunch => '午餐';

  @override
  String get mealDinner => '晚餐';

  @override
  String get mealSnack => '點心';

  @override
  String get unitItem => '個';

  @override
  String get unitG => '公克';

  @override
  String get unitKg => '公斤';

  @override
  String get unitMl => '毫升';

  @override
  String get unitL => '公升';

  @override
  String get unitOz => '盎司';

  @override
  String get unitLb => '磅';

  @override
  String get unitCup => '杯';

  @override
  String get unitBunch => '把';

  @override
  String get noStoreGroup => '其他／未指定商店';

  @override
  String get settingsTitle => '設定';

  @override
  String settingsVersion(String version) {
    return '版本 $version';
  }

  @override
  String get settingsInviteFriends => '邀請親友';

  @override
  String get settingsInviteSubtitle => '分享你的家庭邀請碼';

  @override
  String get settingsPantryLocations => '存放位置';

  @override
  String get settingsPantryLocationsSubtitle => '新增或編輯你自己的存放位置';

  @override
  String get settingsSignOut => '登出';

  @override
  String get settingsLanguage => '語言';

  @override
  String get settingsLanguageSubtitle => '選擇應用程式語言';

  @override
  String get languageSystem => '跟隨系統';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChineseTraditional => '繁體中文';

  @override
  String addItemBarcodeNotFoundTitle(String code) {
    return '找不到條碼 $code 的商品';
  }

  @override
  String get addItemBarcodeNotFoundBody =>
      '本地與進口商品經常沒有收錄在條碼資料庫中。你可以改用拍攝包裝的方式來辨識。';

  @override
  String get addItemTakePhotoInstead => '改用拍照辨識';

  @override
  String get addItemEnterManually => '手動輸入';

  @override
  String get homeGreetingMorning => '早安';

  @override
  String get homeGreetingAfternoon => '午安';

  @override
  String get homeGreetingEvening => '晚安';

  @override
  String homeGreetingNamed(String greeting, String name) {
    return '$greeting，$name';
  }

  @override
  String get homeStatExpiring => '即將到期';

  @override
  String get homeRunningLow => '快用完了嗎？';

  @override
  String get homeRunningLowSubtitle => '找出項目並加入購物清單';

  @override
  String get homeWhatsForDinner => '晚餐吃什麼';

  @override
  String get homeRecipeOfTheDay => '每日精選食譜';

  @override
  String get homeToday => '今天';

  @override
  String get homeTomorrow => '明天';

  @override
  String get homeNothingPlanned => '尚未規劃';

  @override
  String get homeQuickActions => '快速操作';

  @override
  String get homeFindRecipes => '尋找食譜';

  @override
  String get homePlanAMeal => '安排餐點';

  @override
  String get homeShoppingList => '購物清單';

  @override
  String get homeAddToPantry => '加入食品櫃';

  @override
  String get homeAddItem => '新增項目';

  @override
  String get homeScan => '掃描條碼';

  @override
  String get homePhoto => '拍照';

  @override
  String get locationsBuiltIn => '內建位置';

  @override
  String get locationsYours => '你的位置';

  @override
  String get locationsEmpty => '尚未建立自訂位置。點選 + 新增一個。';

  @override
  String get locationsAdd => '新增位置';

  @override
  String get locationsNew => '新增存放位置';

  @override
  String get locationsRename => '重新命名存放位置';

  @override
  String get locationsHint => '例如：車庫層架';

  @override
  String locationsRemoved(String name) {
    return '已移除位置「$name」';
  }

  @override
  String get authEmail => '電子郵件';

  @override
  String get authPassword => '密碼';

  @override
  String get authEmailInvalid => '請輸入有效的電子郵件';

  @override
  String get authPasswordTooShort => '密碼至少需 6 個字元';

  @override
  String get authPasswordMin => '至少 6 個字元';

  @override
  String get authSignIn => '登入';

  @override
  String get authNoAccountRegister => '還沒有帳號？註冊';

  @override
  String get authCreateAccount => '建立帳號';

  @override
  String get authYourName => '你的名字';

  @override
  String get authNameRequired => '請輸入你的名字';

  @override
  String get authHaveAccountSignIn => '已經有帳號了？登入';

  @override
  String get authHouseholdNameRequired => '請輸入家庭名稱';

  @override
  String get authInviteCodeRequired => '請輸入邀請碼';

  @override
  String get authSetUpHousehold => '設定你的家庭';

  @override
  String get authSetUpHouseholdSubtitle => '建立一個新的家庭，或加入另一半已建立的家庭。';

  @override
  String get authStartNewHousehold => '建立新的家庭';

  @override
  String get authHouseholdNameLabel => '家庭名稱（例如「陳家」）';

  @override
  String get authCreateHousehold => '建立家庭';

  @override
  String get authOr => '或';

  @override
  String get authJoinExisting => '加入既有的家庭';

  @override
  String get authJoinExistingSubtitle => '請建立家庭的人分享他們的邀請碼。';

  @override
  String get authInviteCodeLabel => '邀請碼';

  @override
  String get authJoinHousehold => '加入家庭';

  @override
  String get inviteTitle => '邀請你的夥伴';

  @override
  String get inviteBody => '分享這組代碼，讓對方加入你的食品櫃。對方先註冊自己的帳號，再到「加入既有的家庭」輸入這組代碼。';

  @override
  String get inviteCopyCode => '複製邀請碼';

  @override
  String get inviteCopied => '已複製邀請碼';

  @override
  String swipeRemoved(String label) {
    return '已移除 $label';
  }

  @override
  String get updateAvailable => '有可用更新';

  @override
  String get updateStarting => '開始下載…';

  @override
  String updateDownloadingPercent(String percent) {
    return '下載中… $percent%';
  }

  @override
  String get updateNow => '立即更新';

  @override
  String get pantryGroupByTooltip => '分組方式';

  @override
  String get pantryGroupByLocation => '依存放位置分組';

  @override
  String get pantryGroupByCategory => '依分類分組';

  @override
  String get pantryGroupByStore => '依商店分組';

  @override
  String get pantryEmptyTitle => '你的食品櫃是空的';

  @override
  String get pantryEmptySubtitle => '點按 + 新增第一項物品';

  @override
  String pantryExpiringBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 項物品即將到期或已過期',
    );
    return '$_temp0';
  }

  @override
  String pantryNoMatches(String query) {
    return '找不到符合「$query」的項目';
  }

  @override
  String get pantrySearchHint => '搜尋食品櫃…';

  @override
  String get pantryAddItemFab => '新增項目';

  @override
  String get pantryExpiresToday => '今天到期';

  @override
  String get pantryExpiresTomorrow => '明天到期';

  @override
  String pantryExpiresInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days 天後到期',
    );
    return '$_temp0';
  }

  @override
  String pantryExpiredDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '已過期 $days 天',
    );
    return '$_temp0';
  }

  @override
  String get pantryMoreTooltip => '更多';

  @override
  String get pantryAddToShoppingList => '加入購物清單';

  @override
  String get pantryMoveToShoppingList => '從食品櫃移除並加入購物清單';

  @override
  String get pantryViewPhoto => '檢視照片';

  @override
  String get addItemTitleAdd => '新增項目';

  @override
  String get addItemTitleEdit => '編輯項目';

  @override
  String get addItemNewLocationTitle => '新增存放位置';

  @override
  String get addItemNewLocationHint => '例如：車庫層架';

  @override
  String get addItemTakePhoto => '拍照';

  @override
  String get addItemChooseFromGallery => '從相簿選擇';

  @override
  String get addItemCameraPermissionPhoto => '需要相機權限才能拍照';

  @override
  String get addItemCameraPermissionScan => '需要相機權限才能掃描';

  @override
  String addItemPhotoUploadFailed(String error) {
    return '照片上傳失敗：$error';
  }

  @override
  String get addItemIdentifyFailed => '無法辨識這項食品，請手動輸入';

  @override
  String addItemIdentified(String name, int percent) {
    return '已辨識：$name（$percent% 確信）';
  }

  @override
  String addItemPhotoIdError(String error) {
    return '照片辨識失敗：$error。你仍可手動新增。';
  }

  @override
  String get addItemBarcodeUnreadable => '無法讀取條碼，請讓條碼填滿畫面、在光線充足處保持穩定，或手動輸入';

  @override
  String addItemNoProductFound(String code) {
    return '找不到條碼 $code 對應的商品，請手動輸入詳細資料';
  }

  @override
  String addItemProductFound(String name) {
    return '已找到：$name';
  }

  @override
  String addItemLookupError(String error) {
    return '查詢失敗：$error。你仍可手動新增。';
  }

  @override
  String get addItemNoSavedStores => '尚未儲存任何商店。在下方輸入商店名稱，系統會請你將它加入清單。';

  @override
  String get addItemPickStore => '選擇商店';

  @override
  String get addItemPickStoreTooltip => '從已儲存的商店選擇';

  @override
  String get addItemLookingUp => '正在查詢商品…';

  @override
  String get addItemScanBarcode => '掃描條碼';

  @override
  String addItemScanned(String code) {
    return '已掃描：$code（重新掃描）';
  }

  @override
  String get addItemIdentifying => '辨識中…';

  @override
  String get addItemIdentifyByPhoto => '用照片辨識';

  @override
  String get addItemNameLabel => '物品名稱 *';

  @override
  String get addItemNameRequired => '請輸入名稱';

  @override
  String get addItemQuantityLabel => '數量';

  @override
  String get addItemQuantityInvalid => '無效';

  @override
  String get addItemUnitLabel => '單位';

  @override
  String get addItemFoodTypeLabel => '食品分類';

  @override
  String get addItemLocationLabel => '存放位置';

  @override
  String get addItemAddLocation => '新增存放位置…';

  @override
  String get addItemStoreLabel => '商店（選填）';

  @override
  String get addItemStoreHint => '例如：好市多、家樂福、全聯';

  @override
  String get addItemExpiryLabel => '到期日（選填）';

  @override
  String addItemExpiresOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '到期日：$dateString';
  }

  @override
  String get addItemNotesLabel => '備註（選填）';

  @override
  String get addItemPhotoAttached => '已附加照片';

  @override
  String get addItemRemovePhoto => '移除照片';

  @override
  String get addItemUploading => '上傳中…';

  @override
  String get addItemAddPhoto => '新增照片';

  @override
  String get addItemReplacePhoto => '更換照片';

  @override
  String get addItemSaveChanges => '儲存變更';

  @override
  String get addItemAddToPantry => '加入食品櫃';

  @override
  String get qtySheetTitle => '數量';

  @override
  String get qtyMoveTitle => '要移動多少？';

  @override
  String qtyMoveAvailable(String amount) {
    return '你目前有 $amount。其餘會留在食品櫃。';
  }

  @override
  String get qtyMoveAll => '全部移到購物清單';

  @override
  String qtyMoveAmount(String amount) {
    return '移動 $amount 到購物清單';
  }

  @override
  String get plannerToday => '今天';

  @override
  String get plannerTomorrow => '明天';

  @override
  String get plannerYesterday => '昨天';

  @override
  String get plannerFormatMonth => '月';

  @override
  String get plannerFormatTwoWeeks => '兩週';

  @override
  String get plannerFormatWeek => '週';

  @override
  String get plannerAddMeal => '新增餐點';

  @override
  String get plannerNothingPlanned => '這一天還沒有安排餐點';

  @override
  String get plannerMoveTooltip => '移動到其他日期';

  @override
  String get plannerOpenRecipeTooltip => '開啟食譜';

  @override
  String get plannerRecipeGone => '這道食譜已不在收藏中';

  @override
  String plannerSwapped(String a, String b) {
    return '已將「$a」與「$b」對調';
  }

  @override
  String plannerMoved(String title, String day) {
    return '已將「$title」移動到 $day';
  }

  @override
  String plannerAddedMeals(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已新增 $count 份餐點到菜單規劃',
    );
    return '$_temp0';
  }

  @override
  String get mealPlanTitle => '安排餐點';

  @override
  String get mealEditTitle => '編輯餐點';

  @override
  String get mealFieldLabel => '餐點';

  @override
  String get mealFieldHint => '例如：塔可餅';

  @override
  String get mealChooseSavedRecipe => '選擇已收藏的食譜';

  @override
  String get mealPickRecipe => '選擇食譜';

  @override
  String get mealNoSavedRecipes => '尚未收藏任何食譜 — 請先到「食譜」分頁新增';

  @override
  String get mealEnterOrPick => '請輸入餐點名稱或選擇食譜';

  @override
  String get mealNotesLabel => '備註（選填）';

  @override
  String get mealNotesHint => '例如：份量加倍、使用剩菜';

  @override
  String get mealSaveChanges => '儲存變更';

  @override
  String get mealAddToPlan => '加入菜單';

  @override
  String mealMoveTitle(String title) {
    return '將「$title」移動到…';
  }

  @override
  String mealMoveSwapHint(String mealType) {
    return '若該日已安排$mealType，兩者會互換位置。';
  }

  @override
  String get mealMoveConfirm => '移動到這裡';

  @override
  String get rouletteTitle => '隨機菜單';

  @override
  String get rouletteTooltip => '隨機菜單（自動填入）';

  @override
  String get rouletteSubtitle => '從你以前安排過的餐點中隨機挑選，自動填滿空白的日子。';

  @override
  String get rouletteFillNext => '填入接下來';

  @override
  String rouletteDayUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '天',
    );
    return '$_temp0';
  }

  @override
  String get rouletteWhichMeals => '要填入哪幾餐？';

  @override
  String get rouletteTypeJoiner => '或';

  @override
  String rouletteNoHistory(String types) {
    return '你的菜單規劃裡還沒有$types的紀錄 — 請先安排幾次，隨機菜單才有東西可以挑選。';
  }

  @override
  String get rouletteNothingToFill => '你選的餐別在那幾天都已經安排好了 — 沒有空位可以填入。';

  @override
  String rouletteToAdd(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '將新增 $count 項',
    );
    return '$_temp0';
  }

  @override
  String get rouletteRoll => '開始隨機';

  @override
  String get rouletteReRoll => '重新隨機';

  @override
  String get rouletteAddToPlanner => '加入菜單規劃';

  @override
  String get recipeAddByLinkTitle => '以連結新增食譜';

  @override
  String get recipeAddByLinkHint => '貼上食譜網址';

  @override
  String get recipeAddByLinkTooltip => '以連結新增';

  @override
  String get recipeLinkNeedsHttp => '請輸入以 http 開頭的完整連結';

  @override
  String get recipeSavingLink => '正在儲存連結…';

  @override
  String recipeSaved(String name) {
    return '已收藏「$name」';
  }

  @override
  String recipeLinkSaveFailed(String message) {
    return '無法儲存連結：$message';
  }

  @override
  String get recipeWrite => '撰寫食譜';

  @override
  String get recipeEmptyTitle => '尚未收藏任何食譜';

  @override
  String get recipeEmptyHint => '點選「尋找食譜」即可搜尋網路上的食譜';

  @override
  String recipeRemoved(String name) {
    return '已刪除 $name';
  }

  @override
  String recipeShoppingNote(String name) {
    return '用於 $name';
  }

  @override
  String recipeAddedToShopping(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已將 $count 項食材加入購物清單',
    );
    return '$_temp0';
  }

  @override
  String get recipeOpenOriginalTooltip => '用瀏覽器開啟原始頁面';

  @override
  String get recipeEditTooltip => '編輯';

  @override
  String recipeMinutes(int count) {
    return '$count 分鐘';
  }

  @override
  String get recipeLoadFailed => '無法載入這道食譜 — 請檢查網路連線後重試。';

  @override
  String get recipeNoStructuredData => '無法從這個頁面讀取食譜內容。有些網站不提供食譜資料 — 請用瀏覽器開啟查看。';

  @override
  String get recipeAiTranslated => '本食譜由 AI 讀取／翻譯 — 份量請對照原文再確認。';

  @override
  String get recipeReadingPage => '正在讀取食譜…';

  @override
  String get recipeOpenInBrowser => '用瀏覽器開啟';

  @override
  String get recipeIngredients => '食材';

  @override
  String recipeHaveCount(int have, int total) {
    return '已有 $have/$total';
  }

  @override
  String recipeAddMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '將缺少的 $count 項加入購物清單',
    );
    return '$_temp0';
  }

  @override
  String get recipeAddAllIngredients => '將所有食材加入購物清單';

  @override
  String get recipeInstructions => '作法';

  @override
  String get recipeOnListTooltip => '已在購物清單中 — 點選可再加入一次';

  @override
  String get recipeAddToShoppingTooltip => '加入購物清單';

  @override
  String get recipeNutritionTitle => '營養成分（每份）';

  @override
  String get recipeCalories => '熱量';

  @override
  String get recipeProtein => '蛋白質';

  @override
  String get recipeCarbs => '碳水';

  @override
  String get recipeFat => '脂肪';

  @override
  String get recipeManualEditTitle => '編輯食譜';

  @override
  String get recipeManualNeedName => '請為食譜取個名稱';

  @override
  String get recipeManualNameLabel => '食譜名稱 *';

  @override
  String get recipeManualServingsLabel => '份數（選填）';

  @override
  String get recipeManualIngredientsLabel => '食材（每行一項）';

  @override
  String get recipeManualStepsLabel => '步驟（每行一項）';

  @override
  String get recipeManualSave => '儲存食譜';

  @override
  String get findRecipesTitle => '尋找食譜';

  @override
  String get findRecipesSearchHint => '搜尋料理名稱，或貼上食譜連結';

  @override
  String get findRecipesSearchButton => '搜尋';

  @override
  String get findRecipesFromPantry => '用食品櫃裡的食材能做什麼？';

  @override
  String get findRecipesNoResults => '找不到食譜 — 請換個關鍵字試試';

  @override
  String get findRecipesPantryEmpty => '你的食品櫃是空的 — 請先新增一些項目';

  @override
  String get findRecipesNoLink => '這道食譜沒有網頁連結';

  @override
  String get findRecipesOpenFailed => '無法開啟連結';

  @override
  String findRecipesLookupFailed(String message) {
    return '查詢失敗：$message';
  }

  @override
  String get findRecipesEmptyHint => '搜尋料理名稱，或點選「用食品櫃裡的食材能做什麼」\n從你現有的食材找靈感。';

  @override
  String get findRecipesHaveAll => '你的食材都齊全了！';

  @override
  String findRecipesMissingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '缺少 $count 項食材',
    );
    return '$_temp0';
  }

  @override
  String get shoppingReorderTooltip => '再次購買先前的項目';

  @override
  String get shoppingMoveToPantryTooltip => '把已勾選的移入食品櫃';

  @override
  String get shoppingClearCheckedTooltip => '清除已勾選的項目';

  @override
  String shoppingClearedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已清除 $count 個已勾選的項目',
    );
    return '$_temp0';
  }

  @override
  String get shoppingEmptyTitle => '你的購物清單是空的';

  @override
  String get shoppingEmptyHint => '點一下 + 新增想買的東西';

  @override
  String shoppingDupPantryTitle(String name) {
    return '「$name」已在食品櫃中';
  }

  @override
  String get shoppingDupPantryBody => '要把數量加到現有項目上，還是略過？';

  @override
  String get shoppingAddQuantity => '加上數量';

  @override
  String shoppingPantryUpdated(String summary) {
    return '食品櫃已更新 — $summary';
  }

  @override
  String shoppingSummaryAdded(int count) {
    return '新增 $count 項';
  }

  @override
  String shoppingSummaryMerged(int count) {
    return '合併 $count 項';
  }

  @override
  String shoppingSummarySkipped(int count) {
    return '略過 $count 項';
  }

  @override
  String get shoppingSummarySeparator => '、';

  @override
  String get shoppingAddTitle => '加入購物清單';

  @override
  String get shoppingEditTitle => '編輯項目';

  @override
  String get shoppingItemLabel => '項目 *';

  @override
  String get shoppingTakePhoto => '拍照';

  @override
  String get shoppingChooseFromGallery => '從相簿選擇';

  @override
  String get shoppingCameraPermissionNeeded => '需要相機權限才能拍照';

  @override
  String get shoppingIdentifying => '辨識中…';

  @override
  String get shoppingTakePhotoToIdentify => '拍照辨識';

  @override
  String get shoppingCouldNotIdentify => '無法辨識這個項目 — 請手動輸入';

  @override
  String shoppingIdentified(String name, int percent) {
    return '已辨識：$name（$percent% 確信）';
  }

  @override
  String shoppingPhotoIdFailed(String message) {
    return '拍照辨識失敗：$message。你仍然可以手動新增。';
  }

  @override
  String get shoppingStoreOptional => '商店（選填）';

  @override
  String get shoppingPickFromSavedStores => '從已儲存的商店選擇';

  @override
  String get shoppingQuantity => '數量';

  @override
  String get shoppingNoteOptional => '備註（選填），例如「大盒裝」';

  @override
  String shoppingNoMatches(String query) {
    return '找不到符合「$query」的項目';
  }

  @override
  String shoppingDupListTitle(String name) {
    return '「$name」已在購物清單中';
  }

  @override
  String get shoppingDupListBody => '要略過，還是仍要新增？';

  @override
  String get shoppingAddAnyway => '仍要新增';

  @override
  String shoppingAddedToList(String name) {
    return '已將「$name」加入購物清單';
  }

  @override
  String shoppingMovedToList(String name) {
    return '已將「$name」移到購物清單';
  }

  @override
  String shoppingMovedQtyToList(String quantity, String name) {
    return '已將「$name」$quantity 移到購物清單';
  }

  @override
  String get reorderTitle => '再次購買';

  @override
  String get reorderSearchHint => '搜尋項目…';

  @override
  String get reorderEmpty => '目前還沒有可以再次購買的項目。\n你加入清單的項目會出現在這裡。';

  @override
  String reorderItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 項',
    );
    return '$_temp0';
  }

  @override
  String get reorderForgetItem => '忘記這個項目';

  @override
  String reorderAdded(String name) {
    return '已將「$name」加入清單';
  }

  @override
  String get runningLowTitle => '快用完了嗎？';

  @override
  String get runningLowSearchHint => '搜尋要加入清單的項目…';

  @override
  String get runningLowPantryEmpty => '你的食品櫃是空的';

  @override
  String runningLowAddToList(String name) {
    return '將「$name」加入購物清單';
  }

  @override
  String get imageLoadFailed => '無法載入圖片';

  @override
  String get plannerTitle => '菜單規劃';
}
