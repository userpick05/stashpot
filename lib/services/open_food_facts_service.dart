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
  Future<ProductInfo?> lookup(String barcode) async {
    final uri = Uri.parse(
      'https://world.openfoodfacts.org/api/v2/product/$barcode.json'
      '?fields=product_name,brands,image_url,categories_tags,quantity',
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

    return ProductInfo(
      barcode: barcode,
      name: (p['product_name'] as String?)?.trim().isEmpty ?? true
          ? null
          : (p['product_name'] as String).trim(),
      brand: (p['brands'] as String?)?.split(',').first.trim(),
      imageUrl: p['image_url'] as String?,
      quantity: p['quantity'] as String?,
      category: ProductInfo.categoryFromTags(tags),
    );
  }
}
