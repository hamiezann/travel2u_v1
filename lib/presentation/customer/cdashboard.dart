import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:travel2u_v1/core/services/auth_service.dart';
import 'package:travel2u_v1/presentation/auth/change_email_password_page.dart';
import 'package:travel2u_v1/presentation/customer/booking_list_page.dart';
import 'package:travel2u_v1/presentation/customer/notification_list_page.dart';
import 'package:travel2u_v1/presentation/customer/review_listing_page.dart';
import 'package:travel2u_v1/presentation/customer/travel_package_list_page.dart';
import 'package:travel2u_v1/presentation/customer/wishlist_page.dart';
import 'package:travel2u_v1/presentation/widgets/custom_message_popup.dart';
import 'package:travel2u_v1/presentation/widgets/notification_badge_widget.dart';
import 'package:travel2u_v1/presentation/widgets/profile_page.dart';

class CDashboardPage extends StatefulWidget {
  final String? userId;
  final String? name;
  final String? email;
  final String? role;
  const CDashboardPage({
    super.key,
    this.userId,
    this.name,
    this.email,
    this.role,
  });

  @override
  State<CDashboardPage> createState() => _CDashboardPageState();
}

class _CDashboardPageState extends State<CDashboardPage> {
  final _authService = AuthService();
  int _selectedIndex = 0;
  bool isLoggedIn = false;
  Map<String, dynamic> _profile = {};
  late final StreamSubscription<User?> _authListener;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _fetchProfile();
    setState(() {
      isLoggedIn = user != null;
    });

    if (isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        MessagePopup.show(
          context,
          message: "Hi ${widget.name ?? 'Customer'}",
          type: MessageType.success,
          position: PopupPosition.top,
          title: 'Welcome',
        );
      });
    }
    _authListener = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return; // <-- IMPORTANT CHECK
      setState(() {
        isLoggedIn = user != null;
      });
    });
  }

  @override
  void dispose() {
    _authListener.cancel(); // <-- CANCEL LISTENER
    super.dispose();
  }

  Widget _getPage(int index) {
    if (index == 0) {
      return PackagesPage();
    }
    if (!isLoggedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 70, color: Colors.grey),
              const SizedBox(height: 20),
              const Text(
                "Login Required",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "You need to log in to view this section.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade900,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Go to Login"),
              ),
            ],
          ),
        ),
      );
    }

    if (index == 1) return MyTripsPage();
    // if (index == 2) return ItinerariesPage();
    return PackagesPage();
  }

  Future<void> _fetchProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

    if (doc.exists) {
      setState(() {
        _profile = doc.data()!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            isLoggedIn
                ? Builder(
                  builder: (context) {
                    final user = FirebaseAuth.instance.currentUser;

                    // If user = null (logged out), show fallback
                    if (user == null) {
                      return const Text(
                        "IPLANUGO",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      );
                    }

                    return StreamBuilder<DocumentSnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Text("Loading...");
                        }

                        final data =
                            snapshot.data!.data() as Map<String, dynamic>? ??
                            {};

                        return Row(
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.white,
                              backgroundImage:
                                  data['imageUrl'] != null
                                      ? NetworkImage(data['imageUrl'])
                                      : null,
                              child:
                                  data['imageUrl'] == null
                                      ? Text(
                                        (data['firstName'] ?? "U")[0]
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      )
                                      : null,
                            ),

                            const SizedBox(width: 12),

                            // Greeting text
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Hello, how are you?",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  data['firstName'] ?? "User",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    );
                  },
                )
                : const Text(
                  'IPLANUGO',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),

        backgroundColor: Color(0xFF0064D2),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (isLoggedIn) ...[
            PopupMenuButton<int>(
              color: Colors.white,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  // color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.settings_outlined,
                  size: 22,
                  color: Colors.blueGrey,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              offset: const Offset(0, 50),
              itemBuilder:
                  (context) => [
                    PopupMenuItem<int>(
                      value: 1,
                      child: ListTile(
                        leading: Icon(
                          Icons.account_circle_outlined,
                          color: Colors.blue,
                        ),
                        title: Text('My Profile'),
                      ),
                    ),
                    PopupMenuDivider(),
                    PopupMenuItem<int>(
                      value: 2,
                      child: ListTile(
                        leading: Icon(
                          Icons.shopping_cart_outlined,
                          color: Colors.blue,
                        ),
                        title: Text('My Wishlist'),
                      ),
                    ),
                    PopupMenuDivider(),
                    PopupMenuItem<int>(
                      value: 3,
                      child: ListTile(
                        leading: Icon(
                          Icons.star_half_rounded,
                          color: Colors.blue,
                        ),
                        title: Text('My Review'),
                      ),
                    ),
                    PopupMenuDivider(),
                    PopupMenuItem<int>(
                      value: 4,
                      child: ListTile(
                        leading: Icon(
                          Icons.security_outlined,
                          color: Colors.blue,
                        ),
                        title: Text('Change Authentication'),
                      ),
                    ),
                    PopupMenuDivider(),
                    // PopupMenuItem<int>(
                    //   value: 5,
                    //   child: ListTile(
                    //     // leading: Icon(
                    //     //   Icons.notifications_outlined,
                    //     //   color: Colors.blue,
                    //     // ),
                    //     title: Text('My Notifications'),
                    //   ),
                    // ),
                    PopupMenuItem<int>(
                      value: 5,
                      child: ListTile(
                        contentPadding: EdgeInsets.all(0),
                        leading: NotificationIcon(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationListPage(),
                              ),
                            );
                          },
                        ),
                        title: const Text('My Notifications'),
                      ),
                    ),
                  ],
              onSelected: (value) {
                if (value == 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProfilePage()),
                  );
                } else if (value == 2) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => WishlistPage()),
                  );
                } else if (value == 3) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReviewListingPage(uid: widget.userId!),
                    ),
                  );
                } else if (value == 4) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeAuthenticationPage(),
                    ),
                  );
                } else if (value == 5) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationListPage(),
                    ),
                  );
                }
              },
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  size: 22,
                  color: Colors.blueGrey,
                ),
              ),
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text(
                          'Logout',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              await _authService.logout();
                              if (context.mounted) {
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/login',
                                  (r) => false,
                                );
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.blue.shade900,
                            ),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                );
              },
            ),
            const SizedBox(width: 12),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.login_rounded, size: 22),
              onPressed: () => Navigator.pushNamed(context, '/login'),
            ),
            const SizedBox(width: 12),
          ],
        ],
      ),
      extendBody: true,
      body: _getPage(_selectedIndex),
      bottomNavigationBar: Container(
        width: double.minPositive,
        margin: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              // prevent switching to locked sections
              if (!isLoggedIn && index != 0) {
                MessagePopup.show(
                  context,
                  title: "Login Required",
                  message: "Please log in to access this section.",
                  type: MessageType.warning,
                  position: PopupPosition.top,
                );
                return;
              }
              setState(() => _selectedIndex = index);
            },
            // backgroundColor: Colors.blue.shade50,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.blue.shade200,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.explore),
                label: 'Packages',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.card_travel),
                label: 'My Trips',
              ),
              // BottomNavigationBarItem(
              //   icon: Icon(Icons.map),
              //   label: 'Itineraries',
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
