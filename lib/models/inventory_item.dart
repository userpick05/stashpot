import 'package:cloud_firestore/cloud_firestore.dart';

/// The four built-in storage locations, stored as these exact string keys
/// (matches pre-1.2.0 data, which saved the old enum's `.name`). Households can
/// add their own custom locations on top of these; a custom location's key is
/// simply its display name.
const List<String> kBuiltInLocationKeys = ['fridge', 'freezer', 'pantry', 'other'];

const String kDefaultLocationKey = 'pantry';

/// Human label for a location key. Built-ins get a nice label; custom locations
/// use their name as-is.
String locationLabel(String key) => switch (key) {
      'fridge' => 'Fridge',
      'freezer' => 'Freezer',
      'pantry' => 'Pantry',
      'other' => 'Other',
      _ => key,
    };

enum ItemCategory {
  fruit,
  vegetable,
  meat,
  dairy,
  bakery,
  pantry, // dry goods
  frozen,
  beverages,
  snacks,
  household,
  personalCare,
  produce, // legacy (old data) — not offered in the picker
  other,
}

/// Categories offered when adding/editing an item (legacy "produce" excluded).
const List<ItemCategory> kPickableCategories = [
  ItemCategory.fruit,
  ItemCategory.vegetable,
  ItemCategory.meat,
  ItemCategory.dairy,
  ItemCategory.bakery,
  ItemCategory.pantry,
  ItemCategory.frozen,
  ItemCategory.beverages,
  ItemCategory.snacks,
  ItemCategory.household,
  ItemCategory.personalCare,
  ItemCategory.other,
];

extension ItemCategoryLabel on ItemCategory {
  String get label => switch (this) {
        ItemCategory.fruit => 'Fruit',
        ItemCategory.vegetable => 'Vegetables',
        ItemCategory.meat => 'Meat & Fish',
        ItemCategory.dairy => 'Dairy & Eggs',
        ItemCategory.bakery => 'Bakery',
        ItemCategory.pantry => 'Dry Goods',
        ItemCategory.frozen => 'Frozen',
        ItemCategory.beverages => 'Beverages',
        ItemCategory.snacks => 'Snacks',
        ItemCategory.household => 'Household',
        ItemCategory.personalCare => 'Personal Care',
        ItemCategory.produce => 'Produce',
        ItemCategory.other => 'Other',
      };
}

class InventoryItem {
  final String id;
  final String name;
  final String? barcode;
  final String? imageUrl;
  final ItemCategory category;
  final double quantity;
  final String unit;
  final DateTime? expiryDate;
  final String location; // built-in key or a custom location name
  final String? store; // where it's bought — used to group shopping lists
  final String? notes;
  final DateTime addedAt;
  final String addedBy;

  const InventoryItem({
    required this.id,
    required this.name,
    this.barcode,
    this.imageUrl,
    required this.category,
    required this.quantity,
    required this.unit,
    this.expiryDate,
    required this.location,
    this.store,
    this.notes,
    required this.addedAt,
    required this.addedBy,
  });

  factory InventoryItem.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return InventoryItem(
      id: doc.id,
      name: d['name'] as String,
      barcode: d['barcode'] as String?,
      imageUrl: d['imageUrl'] as String?,
      category: ItemCategory.values.firstWhere(
        (c) => c.name == (d['category'] as String?),
        orElse: () => ItemCategory.other,
      ),
      quantity: (d['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: d['unit'] as String? ?? 'item',
      expiryDate: (d['expiryDate'] as Timestamp?)?.toDate(),
      location: (d['location'] as String?)?.trim().isNotEmpty == true
          ? (d['location'] as String).trim()
          : kDefaultLocationKey,
      store: d['store'] as String?,
      notes: d['notes'] as String?,
      addedAt: (d['addedAt'] as Timestamp).toDate(),
      addedBy: d['addedBy'] as String,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        if (barcode != null) 'barcode': barcode,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'category': category.name,
        'quantity': quantity,
        'unit': unit,
        if (expiryDate != null) 'expiryDate': Timestamp.fromDate(expiryDate!),
        'location': location,
        if (store != null) 'store': store,
        if (notes != null) 'notes': notes,
        'addedAt': Timestamp.fromDate(addedAt),
        'addedBy': addedBy,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  InventoryItem copyWith({double? quantity, String? location}) => InventoryItem(
        id: id,
        name: name,
        barcode: barcode,
        imageUrl: imageUrl,
        category: category,
        quantity: quantity ?? this.quantity,
        unit: unit,
        expiryDate: expiryDate,
        location: location ?? this.location,
        store: store,
        notes: notes,
        addedAt: addedAt,
        addedBy: addedBy,
      );

  // Days until expiry: negative = already expired
  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    return expiryDate!.difference(DateTime.now()).inDays;
  }

  bool get isExpired => daysUntilExpiry != null && daysUntilExpiry! < 0;
  bool get expiresSoon => daysUntilExpiry != null && daysUntilExpiry! >= 0 && daysUntilExpiry! <= 3;
  bool get expiresThisWeek => daysUntilExpiry != null && daysUntilExpiry! > 3 && daysUntilExpiry! <= 7;
}
