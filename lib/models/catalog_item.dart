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

  static String idFor(String name) => name.toLowerCase().trim();

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
