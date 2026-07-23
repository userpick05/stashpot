import 'package:flutter_test/flutter_test.dart';
import 'package:stashpot/services/recipe_import_service.dart';

/// The language heuristic decides whether to spend a paid AI call, so its
/// thresholds are worth pinning down. Density, not presence: English recipe
/// blogs routinely sprinkle in Han characters.
void main() {
  const englishRecipe =
      'Chicken Alfredo 1 lb chicken breast 2 cups heavy cream 8 oz fettuccine';
  const englishWithSomeChinese =
      'Char Siu 叉燒 Pork 2 lbs pork shoulder 2 tbsp soy sauce 醬油 1 tbsp honey';
  const chineseRecipe = '宮保雞丁 雞胸肉 300 公克 乾辣椒 10 根 花生 50 公克 醬油 2 大匙';

  group('needsTranslation → English app', () {
    test('leaves an English recipe alone (no API call)', () {
      expect(RecipeImportService.needsTranslation(englishRecipe, 'en'), isFalse);
    });

    test('leaves an English recipe with a few Han characters alone', () {
      expect(RecipeImportService.needsTranslation(englishWithSomeChinese, 'en'),
          isFalse);
    });

    test('translates a Chinese recipe', () {
      expect(RecipeImportService.needsTranslation(chineseRecipe, 'en'), isTrue);
    });

    test('translates other non-Latin scripts too', () {
      expect(
          RecipeImportService.needsTranslation(
              '김치찌개 돼지고기 300그램 김치 두부 대파 고춧가루', 'en'),
          isTrue);
      expect(
          RecipeImportService.needsTranslation(
              'カレーライス 玉ねぎ にんじん じゃがいも 牛肉 カレールー', 'en'),
          isTrue);
    });
  });

  group('needsTranslation → Chinese app', () {
    test('translates an English recipe', () {
      expect(RecipeImportService.needsTranslation(englishRecipe, 'zh'), isTrue);
    });

    test('leaves a Chinese recipe alone', () {
      expect(
          RecipeImportService.needsTranslation(chineseRecipe, 'zh'), isFalse);
    });

    test('translates an English recipe that name-drops a Chinese dish', () {
      // The zh reader should still get this in Chinese — an English page with
      // a couple of Han characters in the title is still an English page.
      expect(RecipeImportService.needsTranslation(englishWithSomeChinese, 'zh'),
          isTrue);
    });

    test('leaves a mostly-Chinese recipe with Latin brand names alone', () {
      expect(
          RecipeImportService.needsTranslation(
              '牛肉麵 牛肋條 600 公克 Costco 蔥 2 根 薑 3 片 米酒 2 大匙', 'zh'),
          isFalse);
    });
  });

  test('ignores samples too short to judge', () {
    expect(RecipeImportService.needsTranslation('Soup', 'en'), isFalse);
    expect(RecipeImportService.needsTranslation('', 'zh'), isFalse);
  });
}
