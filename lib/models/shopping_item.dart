import 'package:cloud_firestore/cloud_firestore.dart';
import 'inventory_item.dart';

/// An item on the shopping list.
///
/// It carries the SAME fields as an [InventoryItem] (category, unit, location,
/// expiry, photo, barcode) — all optional — so a "card" can move between the
/// shopping list and the pantry without losing anything. Only [checked] is
/// shopping-list-specific. The extra fields default to empty/unset, so a plain
/// quick-add still works and old documents read fine.
class ShoppingItem {
  final String id;
  final String name;
  final String? store;
  final double quantity;
  final String? note; // free-text detail e.g. "the big box"
  final bool checked;

  // Carried so nothing is lost moving to/from the pantry.
  final ItemCategory category;
  final String unit;
  final String? location; // optional on the shopping side; null = not set
  final DateTime? expiryDate;
  final String? imageUrl;
  final String? barcode;

  final DateTime addedAt;
  final String addedBy;

  const ShoppingItem({
    required this.id,
    required this.name,
    this.store,
    this.quantity = 1,
    this.note,
    required this.checked,
    this.category = ItemCategory.other,
    this.unit = 'item',
    this.location,
    this.expiryDate,
    this.imageUrl,
    this.barcode,
    required this.addedAt,
    required this.addedBy,
  });

  // "2" not "2.0"; "1.5" stays "1.5"
  String get quantityLabel =>
      quantity % 1 == 0 ? quantity.toInt().toString() : quantity.toString();

  ShoppingItem copyWith({
    String? name,
    String? store,
    double? quantity,
    String? note,
    bool? checked,
    ItemCategory? category,
    String? unit,
    String? location,
    DateTime? expiryDate,
    String? imageUrl,
    String? barcode,
  }) =>
      ShoppingItem(
        id: id,
        name: name ?? this.name,
        store: store ?? this.store,
        quantity: quantity ?? this.quantity,
        note: note ?? this.note,
        checked: checked ?? this.checked,
        category: category ?? this.category,
        unit: unit ?? this.unit,
        location: location ?? this.location,
        expiryDate: expiryDate ?? this.expiryDate,
        imageUrl: imageUrl ?? this.imageUrl,
        barcode: barcode ?? this.barcode,
        addedAt: addedAt,
        addedBy: addedBy,
      );

  factory ShoppingItem.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ShoppingItem(
      id: doc.id,
      name: d['name'] as String,
      store: d['store'] as String?,
      quantity: (d['quantity'] as num?)?.toDouble() ?? 1,
      note: d['note'] as String?,
      checked: d['checked'] as bool? ?? false,
      category: ItemCategory.values.firstWhere(
        (c) => c.name == (d['category'] as String?),
        orElse: () => ItemCategory.other,
      ),
      unit: d['unit'] as String? ?? 'item',
      location: (d['location'] as String?)?.trim().isNotEmpty == true
          ? (d['location'] as String).trim()
          : null,
      expiryDate: (d['expiryDate'] as Timestamp?)?.toDate(),
      imageUrl: d['imageUrl'] as String?,
      barcode: d['barcode'] as String?,
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
        // Only write the extras when they carry meaning, keeping docs lean.
        if (category != ItemCategory.other) 'category': category.name,
        if (unit != 'item') 'unit': unit,
        if (location != null) 'location': location,
        if (expiryDate != null) 'expiryDate': Timestamp.fromDate(expiryDate!),
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (barcode != null) 'barcode': barcode,
        'addedAt': Timestamp.fromDate(addedAt),
        'addedBy': addedBy,
      };

  /// Build a shopping card from a pantry item — carries everything across.
  factory ShoppingItem.fromInventory(
    InventoryItem item, {
    required String id,
    required double quantity,
    required String addedBy,
    DateTime? addedAt,
  }) =>
      ShoppingItem(
        id: id,
        name: item.name,
        store: item.store,
        quantity: quantity,
        note: item.notes,
        checked: false,
        category: item.category,
        unit: item.unit,
        location: item.location,
        expiryDate: item.expiryDate,
        imageUrl: item.imageUrl,
        barcode: item.barcode,
        addedAt: addedAt ?? DateTime.now(),
        addedBy: addedBy,
      );

  /// Build a pantry item from this shopping card — the reverse move, lossless.
  /// [id] is the new pantry doc id; category/location fall back sensibly when
  /// this card never had them set.
  InventoryItem toInventory({
    required String id,
    required String addedBy,
    ItemCategory? categoryFallback,
    DateTime? addedAt,
  }) =>
      InventoryItem(
        id: id,
        name: name,
        barcode: barcode,
        imageUrl: imageUrl,
        category: category != ItemCategory.other
            ? category
            : (categoryFallback ?? ItemCategory.other),
        quantity: quantity,
        unit: unit,
        expiryDate: expiryDate,
        location: location ?? kDefaultLocationKey,
        store: store,
        notes: note,
        addedAt: addedAt ?? DateTime.now(),
        addedBy: addedBy,
      );
}
