import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_info.dart';

class OpenFoodFactsService {
  final http.Client _client;
  OpenFoodFactsService([http.Client? client]) : _client = client ?? http.Client();

  // Open Food Facts asks apps to send a descriptive User-Agent with contact info.
  static const _userAgent = 'Stashpot/1.0 (userpick05@gmail.com)';
  static const _timeout = Duration(seconds: 10);

  /// Looks up a product by barcode. Returns null if not found.
  /// Throws on network/timeout so the caller can show a retry message.
  ///
  /// [languageCode] is the app's active language. For non-English we also ask for
  /// the localized name field (e.g. `product_name_zh`) and prefer it, so a Chinese
  /// user gets a Chinese product name when the database has one. Note Open Food
  /// Facts' coverage of Chinese products is thin — many barcodes simply won't be
  /// found, which is why the caller falls back to the photo identifier.
  Future<ProductInfo?> lookup(String barcode, {String languageCode = 'en'}) async {
    final localized =
        languageCode != 'en' ? ',product_name_$languageCode' : '';
    // tags_lc is pinned to en so `categories_tags` keep their `en:` prefixes —
    // ProductInfo.categoryFromTags matches English substrings, and letting them
    // come back localized would silently file every scan under "other".
    final uri = Uri.parse(
      'https://world.openfoodfacts.org/api/v2/product/$barcode.json'
      '?lc=$languageCode&tags_lc=en'
      '&fields=product_name$localized,brands,image_url,categories_tags,quantity',
    );

    final resp = await _client
        .get(uri, headers: {'User-Agent': _userAgent})
        .timeout(_timeout);

    if (resp.statusCode == 404) return null;
    if (resp.statusCode != 200) {
      throw Exception('Lookup failed (HTTP ${resp.statusCode})');
    }

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    // status 1 = found, 0 = not found
    if (json['status'] != 1 || json['product'] == null) return null;

    final p = json['product'] as Map<String, dynamic>;
    final tags = (p['categories_tags'] as List?)?.cast<String>() ?? const [];

    // Prefer the localized name when the database has one, else the generic.
    String? pickName() {
      for (final key in ['product_name_$languageCode', 'product_name']) {
        final v = (p[key] as String?)?.trim();
        if (v != null && v.isNotEmpty) return v;
      }
      return null;
    }

    return ProductInfo(
      barcode: barcode,
      name: pickName(),
      brand: (p['brands'] as String?)?.split(',').first.trim(),
      imageUrl: p['image_url'] as String?,
      quantity: p['quantity'] as String?,
      category: ProductInfo.categoryFromTags(tags),
    );
  }
}
