import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ManageUserPage extends StatefulWidget {
  final String? userId;
  final String? role;
  const ManageUserPage({super.key, this.userId, required this.role});

  @override
  State<ManageUserPage> createState() => _ManageUserPageState();
}

class _ManageUserPageState extends State<ManageUserPage>
    with SingleTickerProviderStateMixin {
  final Map<String, dynamic> staffList = {};
  final Map<String, dynamic> customerList = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;

  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    if (widget.role == 'manager') {
      _tabController = TabController(length: 2, vsync: this);
    }
    _fetchUserLists();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  // Fetch all users depending on role
  Future<void> _fetchUserLists() async {
    staffList.clear();
    customerList.clear();

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.role == 'manager') {
        // Fetch staff
        QuerySnapshot staffSnapshot =
            await _firestore
                .collection('users')
                .where('role', isEqualTo: 'staff')
                .get();

        // Fetch customers
        QuerySnapshot customerSnapshot =
            await _firestore
                .collection('users')
                .where('role', isEqualTo: 'customer')
                .get();

        setState(() {
          for (var doc in staffSnapshot.docs) {
            staffList[doc.id] = doc.data();
          }
          for (var doc in customerSnapshot.docs) {
            customerList[doc.id] = doc.data();
          }
          _isLoading = false;
        });
      } else {
        // Staff sees customers only
        QuerySnapshot customerSnapshot =
            await _firestore
                .collection('users')
                .where('role', isEqualTo: 'customer')
                .get();

        setState(() {
          for (var doc in customerSnapshot.docs) {
            customerList[doc.id] = doc.data();
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Error fetching users: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.blue.shade900,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _deleteUser(String userId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 8),
                const Text('Confirm Deletion'),
              ],
            ),
            content: Text('Are you sure you want to delete "$name"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('users').doc(userId).delete();
        setState(() {
          staffList.remove(userId);
          customerList.remove(userId);
        });
        _showSnackBar('User deleted successfully');
      } catch (e) {
        _showSnackBar('Error deleting user: $e', isError: true);
      }
    }
  }

  void _openUserForm({String? userId, Map<String, dynamic>? userData}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(
      text: userData?['userName'] ?? '',
    );
    final emailController = TextEditingController(
      text: userData?['email'] ?? '',
    );
    final phoneController = TextEditingController(
      text: userData?['phone'] ?? '',
    );
    String role = userData?['role'] ?? 'customer';

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  userId == null ? Icons.person_add : Icons.edit,
                  color: Colors.blue.shade900,
                ),
                const SizedBox(width: 8),
                Text(userId == null ? 'Add User' : 'Edit User'),
              ],
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email is required';
                        }
                        if (!value.contains('@')) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    if (widget.role == 'manager') const SizedBox(height: 16),
                    if (widget.role == 'manager')
                      DropdownButtonFormField<String>(
                        value: role,
                        decoration: InputDecoration(
                          labelText: 'Role',
                          prefixIcon: const Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'staff',
                            child: Text('Staff'),
                          ),
                          DropdownMenuItem(
                            value: 'customer',
                            child: Text('Customer'),
                          ),
                        ],
                        onChanged: (val) => role = val!,
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) {
                    return;
                  }

                  final defaultPassword = '123456';
                  final email = emailController.text.trim();
                  final name = nameController.text.trim();
                  final phone = phoneController.text.trim();

                  final data = {
                    'userName': name,
                    'email': email,
                    'phone': phone,
                    'role': role,
                    'updatedAt': FieldValue.serverTimestamp(),
                  };

                  try {
                    if (userId == null) {
                      UserCredential userCred = await FirebaseAuth.instance
                          .createUserWithEmailAndPassword(
                            email: email,
                            password: defaultPassword,
                          );
                      final newUserId = userCred.user!.uid;

                      final newDoc = _firestore
                          .collection('users')
                          .doc(newUserId);
                      await newDoc.set({
                        ...data,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                    } else {
                      await _firestore
                          .collection('users')
                          .doc(userId)
                          .update(data);
                    }
                    if (mounted) {
                      Navigator.pop(context);
                      _fetchUserLists();
                      _showSnackBar(
                        userId == null
                            ? 'User added successfully'
                            : 'User updated successfully',
                      );
                    }
                  } catch (e) {
                    _showSnackBar('Error saving user: $e', isError: true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade900,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Manage Users',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade900,
        elevation: 0,
        bottom:
            widget.role == 'manager'
                ? TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(
                      icon: const Icon(Icons.badge),
                      text: 'Staff (${staffList.length})',
                    ),
                    Tab(
                      icon: const Icon(Icons.people),
                      text: 'Customers (${customerList.length})',
                    ),
                  ],
                )
                : null,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openUserForm(),
        label: Text(
          widget.role == 'manager' ? 'Add User' : 'Add Customer',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade900,
        icon: const Icon(Icons.add, color: Colors.white),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : widget.role == 'manager'
              ? TabBarView(
                controller: _tabController,
                children: [
                  _buildUserList(staffList, 'staff'),
                  _buildUserList(customerList, 'customer'),
                ],
              )
              : _buildUserList(customerList, 'customer'),
    );
  }

  Widget _buildUserList(Map<String, dynamic> userList, String userType) {
    if (userList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              userType == 'staff' ? Icons.badge_outlined : Icons.people_outline,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${userType}s found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add a ${userType}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchUserLists,
      color: Colors.blue.shade900,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: userList.length,
        itemBuilder: (context, index) {
          final userId = userList.keys.elementAt(index);
          final userData = userList[userId];
          return _buildUserCard(userId, userData);
        },
      ),
    );
  }

  Widget _buildUserCard(String userId, Map<String, dynamic> userData) {
    final role = userData['role'];
    final isStaff = role == 'staff';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: Colors.blue.shade900.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openUserForm(userId: userId, userData: userData),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isStaff ? Colors.blue.shade100 : Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isStaff ? Icons.badge : Icons.person,
                  color: isStaff ? Colors.blue.shade900 : Colors.green.shade900,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userData['userName'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            userData['email'] ?? 'No email',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (userData['phone'] != null &&
                        userData['phone'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              userData['phone'],
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isStaff
                                ? Colors.blue.shade50
                                : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color:
                              isStaff
                                  ? Colors.blue.shade200
                                  : Colors.green.shade200,
                        ),
                      ),
                      child: Text(
                        isStaff ? 'STAFF' : 'CUSTOMER',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color:
                              isStaff
                                  ? Colors.blue.shade900
                                  : Colors.green.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Action Buttons
              Column(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      color: Colors.blue.shade700,
                    ),
                    onPressed:
                        () => _openUserForm(userId: userId, userData: userData),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.red.shade700,
                    ),
                    onPressed:
                        () => _deleteUser(
                          userId,
                          userData['userName'] ?? 'Unknown',
                        ),
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
