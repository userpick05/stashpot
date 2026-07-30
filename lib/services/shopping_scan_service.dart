import 'dart:typed_data';

import '../models/inventory_item.dart';
import '../models/scanned_item.dart';
import 'gemini_service.dart';

/// Reads a shopping list, cart or order out of screenshots taken in another
/// shopping app (Meijer, Instacart, Walmart, a Taiwanese grocery app, …).
///
/// All the screenshots go to Gemini in ONE request rather than one call each.
/// That's the whole trick: a long list needs several scroll positions, those
/// positions overlap, and only a model seeing them together can tell "the same
/// milk photographed twice" from "two cartons of milk".
///
/// The prompt below was tuned against real Meijer cart screenshots — two
/// overlapping scroll positions, one product deliberately in both. Behaviour
/// verified before shipping: 5 lines not 7, the duplicated product keeps its
/// own quantity instead of doubling, order of images doesn't matter, and the
/// same image twice doesn't inflate anything.
class ShoppingScanService {
  final GeminiService _gemini;
  ShoppingScanService(this._gemini);

  /// More than this and the request gets slow and expensive for little gain.
  static const maxImages = 5;

  // kPickableCategories, not ItemCategory.values: the latter still carries the
  // legacy `produce` value that the category picker deliberately hides, so
  // offering it would import items into a category the user can't select.
  static final _categories =
      kPickableCategories.map((c) => c.name).join(', ');

  bool get isConfigured => _gemini.isConfigured;

  static String _promptFor(String languageCode) {
    final language =
        languageCode == 'zh' ? 'TRADITIONAL CHINESE (繁體中文)' : 'English';
    return '''These are screenshots of a shopping list, cart or order from a grocery
or shopping app. Extract the products the user has on the list.

The screenshots may be SCROLLED views of the SAME list, taken at different
positions, and they MAY OVERLAP. They are not necessarily in order.

Return ONLY JSON of this shape:
{"store": string|null,
 "items": [{"name": string, "note": string|null, "quantity": number,
            "category": string, "partial": boolean,
            "quantityAssumed": boolean}]}

Rules:
1. DEDUPLICATE across the screenshots. A product that appears in more than one
   screenshot is ONE entry in the output. NEVER add its quantities together —
   it is the same line seen twice, not two purchases. When the same product is
   visible more than once, trust the instance you can read most completely.
2. "quantity" = the count of that product the app shows for that line, often a
   small number in a circle or stepper, or "Qty 2" / "x2". It is NOT the package
   size and NOT any price. If a line shows no count at all, or its count is cut
   off by the edge of the screenshot and not visible in any other screenshot,
   use 1 and set "quantityAssumed": true. Set it false whenever you actually
   read the count. Getting this flag right matters: the user is shown these rows
   to check, and a silently-wrong quantity is worse than one marked uncertain.
3. "name" = the product name WITHOUT its size or pack count.
4. "note" = the size / weight / volume / pack count you removed from the name,
   verbatim (e.g. "59 oz", "12 oz., 6 Count Pack"). null if the line has none.
5. "category" = exactly one of these English values: $_categories.
   These are fixed tokens the app parses — never translate them.
6. IGNORE all app and phone chrome: the status bar, clock and battery, menus,
   the cart or item COUNT in a header, store/pickup/delivery banners, every
   price and "/ea", savings, coupon and promo rows or badges, "add a backup /
   substitute"-style buttons, subtotals, totals, checkout buttons, tab bars and
   navigation bars. None of these are products.
7. If a line is cut off at the top or bottom edge so you cannot read it fully,
   AND it is not fully visible in another screenshot, include it with
   "partial": true and your best reading. Never invent a name or quantity.
   Set "partial": false for every line whose NAME you can read completely.
8. "store" = the RETAILER name if you can identify it from branding or a
   loyalty programme (e.g. an "mPerks" badge means Meijer). Not the branch,
   city or pickup location. null if unclear.
9. Write "name" and "note" in $language, translating if the screenshots are
   in another language. Keep sizes and numbers exactly as shown.
10. If the screenshots contain no shopping list or products at all, return
   {"store": null, "items": []}. Never invent products to fill the list.
''';
  }

  /// Reads [imageBytes] (up to [maxImages]; extras are ignored) and returns
  /// what it found. Throws on network/timeout/HTTP so the caller can show a
  /// retry; returns an empty result when the screenshots hold no list.
  Future<ScanResult> scan(
    List<Uint8List> imageBytes, {
    String languageCode = 'en',
  }) async {
    if (imageBytes.isEmpty) return const ScanResult();

    final parsed = await _gemini.generateJson(
      prompt: _promptFor(languageCode),
      images: imageBytes
          .take(maxImages)
          .map(InlineImage.detect)
          .toList(growable: false),
    );
    if (parsed == null) return const ScanResult();

    final rawItems = parsed['items'];
    final items = <ScannedItem>[
      if (rawItems is List)
        for (final raw in rawItems) ?ScannedItem.tryParse(raw),
    ];

    final store = (parsed['store'] ?? '').toString().trim();
    return ScanResult(
      store: store.isEmpty || store.toLowerCase() == 'null' ? null : store,
      items: items,
    );
  }
}
