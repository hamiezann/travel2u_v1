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
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var data = snapshot.data!;
        var role = data['role'];

        if (role == 'staff') {
          return const SDashboardPage();
        } else {
          return CDashboardPage();
        }
      },
    );
  }
}
