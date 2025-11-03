import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:travel2u_v1/core/utils/route.dart';
import 'package:travel2u_v1/presentation/customer/cdashboard.dart';
import 'presentation/auth/login.dart';
import 'presentation/auth/role_redirect.dart';

class TravelApp extends StatelessWidget {
  const TravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IPLANUGO',
      theme: ThemeData(primarySwatch: Colors.teal),
      debugShowCheckedModeBanner: false,
      // initialRoute: AppRoute.login,
      routes: AppRoute.routes,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData) {
            return const RoleRedirect();
          } else {
            // return const LoginPage();
            return const CDashboardPage();
          }
        },
      ),
    );
  }
}
