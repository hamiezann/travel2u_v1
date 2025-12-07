import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<User?> register(String email, String password, String role) async {
    UserCredential cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _db.collection('users').doc(cred.user!.uid).set({
      'email': email,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
    });
    return cred.user;
  }

  Future<User?> login(String email, String password) async {
    UserCredential cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _db
        .collection('users')
        .where('isActive', isEqualTo: true)
        .where('email', isEqualTo: email)
        .get()
        .then((snapshot) {
          if (snapshot.docs.isEmpty) {
            throw FirebaseAuthException(
              code: 'user-inactive',
              message: 'This user account is inactive.',
            );
          }
          return;
        });
    String? token = await FirebaseMessaging.instance.getToken();

    await FirebaseFirestore.instance
        .collection("users")
        .doc(cred.user?.uid)
        .update({"fcmToken": token});
    return cred.user;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
