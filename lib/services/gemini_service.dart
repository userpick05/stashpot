import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/food_id_result.dart';

class GeminiService {
  // Injected at build time via --dart-define-from-file=secrets.json
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _model = 'gemini-2.5-flash';
  static const _timeout = Duration(seconds: 30);

  final http.Client _client;
  GeminiService([http.Client? client]) : _client = client ?? http.Client();

  bool get isConfigured => _apiKey.isNotEmpty;

  /// Builds the identify prompt for the user's language. Gemini is multimodal and
  /// reads Chinese packaging natively — we just have to tell it which language to
  /// answer in, and give it store hints that make sense in that market.
  ///
  /// IMPORTANT: "category" stays an English enum value (it's parsed back into
  /// [ItemCategory]), and the not-found sentinel stays the literal English
  /// "Unknown" (the UI checks for that exact string).
  static String _promptFor(String languageCode) {
    final isZh = languageCode == 'zh';

    final languageRule = isZh
        ? 'Write "name" and "details" in TRADITIONAL CHINESE (繁體中文) — never Simplified, '
            'and never English (except a brand that is genuinely written in Latin letters on '
            'the package, e.g. "Pocari Sweat"). Translate/transcribe what you read into '
            'natural Traditional Chinese a Taiwanese shopper would use.'
        : 'Write "name" and "details" in English.';

    final nameExamples = isZh
        ? '(e.g. "統一 布丁", "光泉 low fat 鮮乳", "花王 洗碗精")'
        : '(e.g. "Tillamook Sharp Cheddar", "Clorox Disinfecting Wipes", "Bounty Paper Towels")';

    final genericExample = isZh ? '(e.g. "香蕉")' : '(e.g. "Bananas")';

    final storeRule = isZh
        ? 'the store this is sold at IF a store brand is clearly visible '
            '(e.g. 好市多 Kirkland->好市多, 全聯 美廚->全聯, 家樂福->家樂福, 7-SELECT->7-ELEVEN, '
            'FamilyMart Collection->全家); otherwise empty string'
        : 'the store this is sold at IF a store-brand is clearly visible '
            '(Kirkland->Costco, Great Value->Walmart, 365->Whole Foods, Trader Joe\'s->Trader Joe\'s, '
            'Member\'s Mark->Sam\'s Club, Up & Up->Target); otherwise empty string';

    final detailsExample = isZh
        ? '(e.g. "75 入", "500 毫升", "檸檬香")'
        : '(e.g. "75 ct", "32 oz", "Lemon scent")';

    return '''
You are a home inventory assistant. This inventory holds BOTH food and household/non-food
products (cleaning supplies, paper goods, toiletries, etc.). Identify the single main
product in this photo as specifically as possible.

Read any visible text on the packaging, in ANY script (Latin, Chinese, Japanese, Korean).
$languageRule
If a brand and product name are legible, include them in "name" $nameExamples.
If you cannot read a brand, give the best generic name $genericExample.

Respond ONLY with JSON of this exact shape:
{
  "name": specific product name including brand if visible,
  "category": one of ["fruit","vegetable","meat","dairy","bakery","pantry","frozen","beverages","snacks","household","personalcare","other"],
  "details": short extra info visible on the package such as size, count, weight, variety, or flavor $detailsExample; empty string if none,
  "store": $storeRule,
  "confidence": number between 0 and 1
}

The "category" value MUST be one of the English words listed above — do not translate it.
Category guidance: "meat" includes fish/seafood; "dairy" includes eggs; "pantry" = dry goods
(rice, pasta, flour, canned, sauces, spices); "bakery" = bread/baked goods; "household" =
cleaning/laundry/paper goods; "personalcare" = toiletries, health, hygiene, medicine.
If no product is visible, set "confidence" to 0 and set "name" to the exact ASCII
token Unknown. That token is a fixed sentinel the app matches on — it is the ONE
value that must stay English, even when you are answering in another language.''';
  }

  /// Generic JSON generation. Sends [prompt] (and an optional JPEG image) to
  /// Gemini and returns the parsed JSON object. Throws on network/timeout/HTTP.
  Future<Map<String, dynamic>?> generateJson({
    required String prompt,
    Uint8List? imageJpeg,
  }) async {
    if (!isConfigured) {
      throw Exception(
          'Gemini API key not set. Rebuild with --dart-define-from-file=secrets.json');
    }

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey',
    );

    final parts = <Map<String, dynamic>>[
      {'text': prompt},
      if (imageJpeg != null)
        {
          'inline_data': {
            'mime_type': 'image/jpeg',
            'data': base64Encode(imageJpeg),
          }
        },
    ];

    final body = jsonEncode({
      'contents': [
        {'parts': parts}
      ],
      'generationConfig': {'responseMimeType': 'application/json'},
    });

    final resp = await _client
        .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(_timeout);

    if (resp.statusCode != 200) {
      throw Exception('Gemini error (HTTP ${resp.statusCode})');
    }

    final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    final candidates = decoded['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return null;

    final text = candidates[0]['content']?['parts']?[0]?['text'] as String?;
    if (text == null || text.isEmpty) return null;

    return jsonDecode(text) as Map<String, dynamic>;
  }

  /// Identifies the food in [imageBytes] (JPEG). Throws on network/timeout.
  ///
  /// [languageCode] is the app's active language (e.g. 'en', 'zh') — the result's
  /// name/details come back in that language, so a Chinese user photographing
  /// Chinese packaging gets a Chinese item name.
  Future<FoodIdResult?> identifyFood(
    Uint8List imageBytes, {
    String languageCode = 'en',
  }) async {
    final parsed = await generateJson(
      prompt: _promptFor(languageCode),
      imageJpeg: imageBytes,
    );
    if (parsed == null) return null;
    return FoodIdResult.fromJson(parsed);
  }
}
