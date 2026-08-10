import 'package:cloud_firestore/cloud_firestore.dart';

/// A previously-added shopping item, remembered for quick reordering.
/// Document id is the normalized (lowercased) name so re-adds de-duplicate.
class CatalogItem {
  final String id;
  final String name;
  final String? store;
  final double quantity;
  final String? note;
  final int timesAdded;
  final DateTime? lastAddedAt;

  const CatalogItem({
    required this.id,
    required this.name,
    this.store,
    this.quantity = 1,
    this.note,
    this.timesAdded = 1,
    this.lastAddedAt,
  });

  /// A Firestore-safe document id derived from the name, so re-adds of the same
  /// item de-duplicate. The name itself is stored untouched in the `name` field
  /// and is what's ever displayed — this is only the key.
  ///
  /// Firestore document ids can't contain '/' (it's the path separator), can't
  /// be '.' or '..', and can't match `__…__`. A name like "sourdough/Italian
  /// bread" hit the first rule, which threw and made the whole add look like it
  /// failed. Fold those cases into something legal.
  static String idFor(String name) {
    var id = name
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[/\\]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    // '.', '..' and anything matching __…__ are reserved. Prefix with a token
    // that can't itself re-trigger a rule (a leading '_' would keep matching
    // the __…__ pattern).
    if (id == '.' || id == '..' || RegExp(r'^__.*__$').hasMatch(id)) {
      id = 'item-$id';
    }
    return id;
  }

  factory CatalogItem.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CatalogItem(
      id: doc.id,
      name: d['name'] as String,
      store: d['store'] as String?,
      quantity: (d['quantity'] as num?)?.toDouble() ?? 1,
      note: d['note'] as String?,
      timesAdded: (d['timesAdded'] as num?)?.toInt() ?? 1,
      lastAddedAt: (d['lastAddedAt'] as Timestamp?)?.toDate(),
    );
  }
}
