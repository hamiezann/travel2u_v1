import 'package:flutter/material.dart';
import 'package:travel2u_v1/core/services/auth_service.dart';
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

  final List<Widget> _pages = [
    PackagesPage(),
    MyTripsPage(),
    ItinerariesPage(),
  ];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    // Run after the first frame is rendered
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IPLANUGO'),
        backgroundColor: Colors.blue.shade900,

        // foregroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await _authService.logout();
                            if (context.mounted) {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/login',
                                (route) => false,
                              );
                            }
                          },
                          child: const Text(
                            'Logout',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      extendBody: true,
      body: _pages[_selectedIndex],
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
            onTap: (index) => setState(() => _selectedIndex = index),
            // backgroundColor: Colors.transparent,
            backgroundColor: Colors.blue.shade50,
            elevation: 0,
            selectedItemColor: Colors.blue.shade900,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedItemColor: Colors.blue.shade300,
            type: BottomNavigationBarType.fixed,
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
