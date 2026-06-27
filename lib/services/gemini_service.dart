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

  static const _prompt = '''
You are a home inventory assistant. This inventory holds BOTH food and household/non-food
products (cleaning supplies, paper goods, toiletries, etc.). Identify the single main
product in this photo as specifically as possible.

Read any visible text on the packaging. If a brand and product name are legible, include
them in "name" (e.g. "Tillamook Sharp Cheddar", "Clorox Disinfecting Wipes", "Bounty Paper Towels").
If you cannot read a brand, give the best generic name (e.g. "Bananas").

Respond ONLY with JSON of this exact shape:
{
  "name": specific product name including brand if visible,
  "category": one of ["fruit","vegetable","meat","dairy","bakery","pantry","frozen","beverages","snacks","household","personalcare","other"],
  "details": short extra info visible on the package such as size, count, weight, variety, or flavor (e.g. "75 ct", "32 oz", "Lemon scent"); empty string if none,
  "store": the store this is sold at IF a store-brand is clearly visible (Kirkland->Costco, Great Value->Walmart, 365->Whole Foods, Trader Joe's->Trader Joe's, Member's Mark->Sam's Club, Up & Up->Target); otherwise empty string,
  "confidence": number between 0 and 1
}

Category guidance: "meat" includes fish/seafood; "dairy" includes eggs; "pantry" = dry goods
(rice, pasta, flour, canned, sauces, spices); "bakery" = bread/baked goods; "household" =
cleaning/laundry/paper goods; "personalcare" = toiletries, health, hygiene, medicine.
If no product is visible, use name "Unknown" and confidence 0.''';

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
  Future<FoodIdResult?> identifyFood(Uint8List imageBytes) async {
    final parsed = await generateJson(prompt: _prompt, imageJpeg: imageBytes);
    if (parsed == null) return null;
    return FoodIdResult.fromJson(parsed);
  }
}
