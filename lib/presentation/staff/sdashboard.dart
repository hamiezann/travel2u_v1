import 'package:flutter/material.dart';
import 'package:travel2u_v1/core/services/auth_service.dart';
import 'package:travel2u_v1/presentation/staff/manage_activity_page.dart';
import 'package:travel2u_v1/presentation/staff/manage_system_user_page.dart';
import 'package:travel2u_v1/presentation/staff/manage_taxonomy_page.dart';
import 'package:travel2u_v1/presentation/staff/manage_travel_page.dart';
import 'package:travel2u_v1/presentation/widgets/custom_message_popup.dart';
import 'package:travel2u_v1/presentation/widgets/profile_page.dart';

class SDashboardPage extends StatelessWidget {
  final String? userId;
  final String? email;
  final String? name;
  final String? role;
  const SDashboardPage({
    super.key,
    this.userId,
    this.name,
    this.email,
    this.role,
  });

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MessagePopup.show(
        context,
        message: "Hi ${name ?? (role == 'staff' ? 'Staff' : 'Admin')}",
        type: MessageType.success,
        position: PopupPosition.top,
        title: 'Welcome',
      );
    });
    return Scaffold(
      appBar: AppBar(
        title: Text(role == 'staff' ? 'Staff Dashboard' : 'Admin Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (role == "staff") ...[
            IconButton(
              icon: const Icon(Icons.person_outline_rounded),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              },
            ),
          ],
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // logout dialog
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
                            await authService.logout();
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
      body: Container(
        decoration: BoxDecoration(color: Colors.blue),
        child: SafeArea(
          child: Column(
            children: [
              // Header Sectio
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.work_outline,
                        size: 48,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Welcome Back!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your travel services',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),

              // Menu Cards
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.blue, Colors.orange.shade50],
                      stops: const [0.0, 0.5],
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Manage Travel Packages Card
                        _buildMenuCard(
                          context: context,
                          icon: Icons.flight_takeoff,
                          title: 'Manage Travel Packages',
                          description: 'Create, edit, and manage packages',
                          color: Colors.blue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ManageTravelPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Manage Activities Card
                        _buildMenuCard(
                          context: context,
                          icon: Icons.local_activity,
                          title: 'Manage Bookings & Activities',
                          description: 'Handle bookings and activities',
                          color: Colors.green,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ManageActivityPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildMenuCard(
                          context: context,
                          icon: Icons.people_alt_outlined,
                          title:
                              role == 'staff'
                                  ? 'Manage Customer'
                                  : 'Manage Staff & Customer',
                          description: 'Manage system user',
                          color: Colors.yellow,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => ManageUserPage(
                                      userId: userId,
                                      role: role,
                                    ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildMenuCard(
                          context: context,
                          icon: Icons.category,
                          title: 'Manage Taxonomies',
                          description: 'Handle tags used in travel packages',
                          color: Colors.pink,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ManageTaxonomyPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 20, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
