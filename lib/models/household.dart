import 'package:cloud_firestore/cloud_firestore.dart';

class Household {
  final String id;
  final String name;
  final List<String> memberUids;
  final String createdBy;
  final DateTime createdAt;

  const Household({
    required this.id,
    required this.name,
    required this.memberUids,
    required this.createdBy,
    required this.createdAt,
  });

  factory Household.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Household(
      id: doc.id,
      name: d['name'] as String,
      memberUids: List<String>.from(d['memberUids'] as List),
      createdBy: d['createdBy'] as String,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'memberUids': memberUids,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
