import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String? householdId;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.householdId,
    required this.createdAt,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: d['email'] as String,
      displayName: d['displayName'] as String,
      householdId: d['householdId'] as String?,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'displayName': displayName,
        if (householdId != null) 'householdId': householdId,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
