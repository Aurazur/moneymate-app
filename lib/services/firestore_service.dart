import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveUserProfile({
    required String displayName,
    required String defaultCurrency,
    required double monthlyBudget,
    required bool darkMode,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');

    await _db.collection('users').doc(user.uid).set({
      'displayName': displayName,
      'defaultCurrency': defaultCurrency,
      'monthlyBudget': monthlyBudget,
      'darkMode': darkMode,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return doc.data();
  }
}
