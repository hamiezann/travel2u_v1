import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BasicService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String?> getUserId() async {
    final userId = _auth.currentUser?.uid;
    return userId;
  }

  // Future<String?> getUserRole(String userId) async {
  //   final snapshot = await _db.collection('users').doc(userId).get();
  //   if (snapshot.exists) {
  //     final userRole = snapshot.data()?['role'] as String?;
  //     return userRole;
  //   } else {
  //     return null;
  //   }
  // }

  Future<String?> getUserRole(String? userId) async {
    if (userId == null) return null;

    final snapshot = await _db.collection('users').doc(userId).get();
    return snapshot.data()?['role'] as String?;
  }
}
