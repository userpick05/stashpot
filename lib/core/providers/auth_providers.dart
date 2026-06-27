import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

final authServiceProvider = Provider<AuthService>((_) => AuthService());

final firestoreServiceProvider = Provider<FirestoreService>((_) => FirestoreService());

// Raw Firebase auth state
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Current user's Firestore doc (streams live updates)
final appUserProvider = StreamProvider<AppUser?>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((s) => s.exists ? AppUser.fromFirestore(s) : null);
});

// Derived: household ID the current user belongs to
final householdIdProvider = Provider<String?>((ref) {
  return ref.watch(appUserProvider).valueOrNull?.householdId;
});
