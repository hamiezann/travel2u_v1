import 'package:flutter/material.dart';
import 'package:travel2u_v1/core/services/auth_service.dart';
import 'package:travel2u_v1/presentation/customer/booking_list_page.dart';
import 'package:travel2u_v1/presentation/customer/itinerary_list_page.dart';
import 'package:travel2u_v1/presentation/customer/travel_package_list_page.dart';

class CDashboardPage extends StatefulWidget {
  const CDashboardPage({super.key});

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IPLANUGO'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        actions: [
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
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
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
            backgroundColor: Colors.blue.shade900,
            elevation: 0,
            selectedItemColor: Colors.white,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedItemColor: Colors.grey,
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
