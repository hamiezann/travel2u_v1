import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:travel2u_v1/core/services/auth_service.dart';
import 'package:travel2u_v1/presentation/auth/change_email_password_page.dart';
import 'package:travel2u_v1/presentation/customer/booking_list_page.dart';
import 'package:travel2u_v1/presentation/customer/itinerary_list_page.dart';
import 'package:travel2u_v1/presentation/customer/travel_package_list_page.dart';
import 'package:travel2u_v1/presentation/widgets/custom_message_popup.dart';
import 'package:travel2u_v1/presentation/widgets/profile_page.dart';

class CDashboardPage extends StatefulWidget {
  final String? userId;
  final String? name;
  final String? email;
  final String? role;
  // const CDashboardPage({super.key});
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

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
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
  }

  /// Securely returns a page depending on auth status
  Widget _getPage(int index) {
    if (index == 0) {
      return PackagesPage();
    }

    // MyTrips and Itineraries require login
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
    if (index == 2) return ItinerariesPage();

    return PackagesPage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'IPLANUGO',
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
        backgroundColor: Color(0xFF0064D2),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (isLoggedIn) ...[
            PopupMenuButton<int>(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person_outline_rounded, size: 22),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              offset: const Offset(0, 50),
              itemBuilder:
                  (context) => const [
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
                          Icons.security_outlined,
                          color: Colors.blue,
                        ),
                        title: Text('Change Authentication'),
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
                    MaterialPageRoute(
                      builder: (_) => ChangeAuthenticationPage(),
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
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.logout_rounded, size: 22),
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
        margin: const EdgeInsets.all(18),
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
                  position: PopupPosition.bottom,
                );
                return;
              }
              setState(() => _selectedIndex = index);
            },
            backgroundColor: Colors.blue.shade50,
            selectedItemColor: Colors.blue.shade900,
            unselectedItemColor: Colors.blue.shade300,
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
              BottomNavigationBarItem(
                icon: Icon(Icons.map),
                label: 'Itineraries',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
