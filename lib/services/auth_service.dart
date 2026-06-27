import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Future<UserCredential> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user!.updateDisplayName(displayName);
    // Create the user doc in Firestore (no householdId yet)
    final user = AppUser(
      uid: cred.user!.uid,
      email: email,
      displayName: displayName,
      createdAt: DateTime.now(),
    );
    await _db.collection('users').doc(cred.user!.uid).set(user.toFirestore());
    return cred;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<void> signOut() => _auth.signOut();

  User? get currentUser => _auth.currentUser;
}
