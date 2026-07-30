import 'inventory_item.dart';

/// Where a reviewed row is headed once confirmed.
enum ImportDestination { shopping, pantry }

/// One product read out of a shopping-app screenshot, before the user has
/// confirmed it. Mutable on purpose: the review screen lets the user fix a
/// misread name, correct a quantity, or send an individual row somewhere else.
class ScannedItem {
  String name;
  String? note;
  double quantity;
  ItemCategory category;

  /// The row was clipped by the edge of a screenshot, so the reading is a best
  /// effort — surfaced in the UI so the user knows to check it. Cleared once
  /// they've edited the row, since at that point they HAVE checked it.
  bool partial;

  /// No count was visible for this row (typically cut off below the fold), so
  /// the quantity fell back to 1. Worth flagging: a silently-wrong quantity is
  /// the kind of thing nobody notices, unlike a wrong name.
  bool quantityAssumed;

  /// Unchecked rows are skipped entirely on confirm.
  bool selected;

  /// Per-row override of the screen's master destination. Null = follow it.
  ImportDestination? destination;

  /// Document id, minted once when this row is first written. Keeping it means
  /// retrying after a partial failure overwrites the same document instead of
  /// creating a second copy of everything that already landed.
  String? docId;

  /// Another selected row reads as the same product. The model is told never to
  /// do this (a product in two overlapping screenshots is ONE line), so it means
  /// its de-duplication missed — worth showing rather than silently summing.
  bool duplicateInScan = false;

  ScannedItem({
    required this.name,
    this.note,
    this.quantity = 1,
    this.category = ItemCategory.other,
    this.partial = false,
    this.quantityAssumed = false,
    this.selected = true,
    this.destination,
  });

  /// Lenient by design — the model drifts off the requested shape occasionally,
  /// and losing a whole scan over one odd field would be worse than a row the
  /// user has to fix. Returns null only when there's no usable name.
  static ScannedItem? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final name = (raw['name'] ?? '').toString().trim();
    if (name.isEmpty) return null;

    final note = (raw['note'] ?? '').toString().trim();
    final qty = _asDouble(raw['quantity']);
    return ScannedItem(
      name: name,
      note: note.isEmpty || note.toLowerCase() == 'null' ? null : note,
      // A zero or negative count is a misread, not an instruction to add none.
      quantity: (qty == null || qty <= 0) ? 1 : qty,
      category: _categoryFrom(raw['category']),
      // Lenient on purpose: these two are SAFETY flags, so a model that answers
      // "true" as a string must still raise the warning. Failing closed here
      // would silently drop the very signal the user is meant to check.
      partial: _asBool(raw['partial']),
      // Treat a missing count as assumed, so the UI flags it either way.
      quantityAssumed: _asBool(raw['quantityAssumed']) || qty == null,
    );
  }

  /// Identity used to decide "these two are the same product". Name AND note
  /// together, matching how the shopping-to-pantry move has always worked, so
  /// two sizes of one thing stay separate items.
  ///
  /// This drives coalescing: rows sharing a key are written to ONE document with
  /// their quantities summed, rather than racing each other in the same batch.
  String get productKey =>
      '${name.trim().toLowerCase()}|${(note ?? '').trim().toLowerCase()}';

  /// Where an imported item belongs, so a 25-item grocery run doesn't pile
  /// everything into one location for the user to sort by hand. Only the
  /// unambiguous cases move; anything else keeps the default.
  String get suggestedLocation => switch (category) {
        ItemCategory.frozen => 'freezer',
        ItemCategory.dairy || ItemCategory.meat => 'fridge',
        _ => kDefaultLocationKey,
      };

  static bool _asBool(dynamic v) {
    if (v is bool) return v;
    final s = v?.toString().toLowerCase().trim();
    return s == 'true' || s == 'yes' || s == '1';
  }

  static double? _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    final m = RegExp(r'\d+(?:\.\d+)?').firstMatch(v?.toString() ?? '');
    return m == null ? null : double.tryParse(m.group(0)!);
  }

  static ItemCategory _categoryFrom(dynamic v) {
    final target = v?.toString().toLowerCase().trim();
    return ItemCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == target,
      orElse: () => ItemCategory.other,
    );
  }
}

/// The result of reading one batch of screenshots.
class ScanResult {
  /// The retailer, when the screenshots make it identifiable (an mPerks badge
  /// means Meijer, and so on). Pre-fills the store on every imported row.
  final String? store;
  final List<ScannedItem> items;

  const ScanResult({this.store, this.items = const []});

  bool get isEmpty => items.isEmpty;
}
