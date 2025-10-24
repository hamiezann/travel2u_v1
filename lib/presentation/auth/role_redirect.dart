import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:travel2u_v1/presentation/customer/cdashboard.dart';
import 'package:travel2u_v1/presentation/staff/sdashboard.dart';

class RoleRedirect extends StatelessWidget {
  const RoleRedirect({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder(
      future:
          FirebaseFirestore.instance.collection('users').doc(user!.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('User data not found.'));
        }
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final role = data['role'];
        final name = data['userName'];
        final email = data['email'];

        if (role == 'staff' || role == 'manager') {
          return SDashboardPage(
            userId: user.uid,
            name: name,
            email: email,
            role: role,
          );
        } else {
          return CDashboardPage(
            userId: user.uid,
            name: name,
            email: email,
            role: role,
          );
        }
      },
    );
  }
}
