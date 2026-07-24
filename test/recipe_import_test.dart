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

  group('splitNumbered', () {
    // xiachufang publishes every instruction as one comma-joined string with
    // the numbers inline. Parsed as a single step, the recipe rendered as one
    // wall of text — and the resulting 1-vs-12 step count made the translator
    // discard a perfectly good translation, leaving the whole recipe Chinese.
    test('splits a run-on numbered instruction string', () {
      final steps = RecipeImportService.splitNumbered(
          '0.大合照,1.胡萝卜不好熟，所以先焯水过凉水控干备用,2.热锅温油鸡丁炒制九成熟,3.盛出备用');
      expect(steps, hasLength(4));
      expect(steps.first, '0.大合照');
      expect(steps.last, '3.盛出备用');
    });

    test('splits an English run-on string too', () {
      expect(
          RecipeImportService.splitNumbered(
              '1. Chop the onion, 2. Fry until golden, 3. Add stock'),
          hasLength(3));
    });

    test('leaves ordinary prose alone', () {
      const prose = 'Preheat the oven to 200C and line a tray with baking paper.';
      expect(RecipeImportService.splitNumbered(prose), [prose]);
    });

    test('does not split on decimals or quantities', () {
      const line = 'Simmer for 1.5 hours, stirring every 20 minutes.';
      expect(RecipeImportService.splitNumbered(line), [line]);
    });
  });

  test('ignores samples too short to judge', () {
    expect(RecipeImportService.needsTranslation('Soup', 'en'), isFalse);
    expect(RecipeImportService.needsTranslation('', 'zh'), isFalse);
  });
}
