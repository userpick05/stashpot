import 'package:cloud_firestore/cloud_firestore.dart';

class PlannedMeal {
  final String id;
  final DateTime date; // the day (local midnight)
  final String title;
  final String mealType; // Breakfast / Lunch / Dinner / Snack
  final String? recipeId; // linked saved recipe, if any
  final String? notes;
  final DateTime addedAt;
  final String addedBy;

  const PlannedMeal({
    required this.id,
    required this.date,
    required this.title,
    required this.mealType,
    this.recipeId,
    this.notes,
    required this.addedAt,
    required this.addedBy,
  });

  // Sort key within a day.
  static const mealOrder = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
  int get mealRank {
    final i = mealOrder.indexOf(mealType);
    return i < 0 ? mealOrder.length : i;
  }

  factory PlannedMeal.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PlannedMeal(
      id: doc.id,
      date: (d['date'] as Timestamp).toDate(),
      title: d['title'] as String,
      mealType: d['mealType'] as String? ?? 'Dinner',
      recipeId: d['recipeId'] as String?,
      notes: d['notes'] as String?,
      addedAt: (d['addedAt'] as Timestamp).toDate(),
      addedBy: d['addedBy'] as String,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
        'title': title,
        'mealType': mealType,
        if (recipeId != null) 'recipeId': recipeId,
        if (notes != null) 'notes': notes,
        'addedAt': Timestamp.fromDate(addedAt),
        'addedBy': addedBy,
      };
}
