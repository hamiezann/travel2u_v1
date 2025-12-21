import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BasicService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String?> getUserId() async {
    final userId = _auth.currentUser?.uid;
    return userId;
  }

  Future<String?> getUserRole(String? userId) async {
    if (userId == null) return null;

    final snapshot = await _db.collection('users').doc(userId).get();
    return snapshot.data()?['role'] as String?;
  }

  Future<bool> isPackageBookedByUser(String? packageId, String? userId) async {
    final querySnapshot =
        await _db
            .collection('bookings')
            .where('packageId', isEqualTo: packageId)
            .where('userId', isEqualTo: userId)
            .where('status', isEqualTo: 'booked')
            .limit(1)
            .get();

    return querySnapshot.docs.isNotEmpty;
  }
}
