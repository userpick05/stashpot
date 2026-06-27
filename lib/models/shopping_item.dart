import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingItem {
  final String id;
  final String name;
  final String? store;
  final double quantity;
  final String? note; // free-text detail e.g. "the big box"
  final bool checked;
  final DateTime addedAt;
  final String addedBy;

  const ShoppingItem({
    required this.id,
    required this.name,
    this.store,
    this.quantity = 1,
    this.note,
    required this.checked,
    required this.addedAt,
    required this.addedBy,
  });

  // "2" not "2.0"; "1.5" stays "1.5"
  String get quantityLabel =>
      quantity % 1 == 0 ? quantity.toInt().toString() : quantity.toString();

  factory ShoppingItem.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ShoppingItem(
      id: doc.id,
      name: d['name'] as String,
      store: d['store'] as String?,
      quantity: (d['quantity'] as num?)?.toDouble() ?? 1,
      note: d['note'] as String?,
      checked: d['checked'] as bool? ?? false,
      addedAt: (d['addedAt'] as Timestamp).toDate(),
      addedBy: d['addedBy'] as String,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        if (store != null) 'store': store,
        'quantity': quantity,
        if (note != null) 'note': note,
        'checked': checked,
        'addedAt': Timestamp.fromDate(addedAt),
        'addedBy': addedBy,
      };
}
