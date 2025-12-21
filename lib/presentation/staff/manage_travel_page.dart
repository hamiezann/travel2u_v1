import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:travel2u_v1/core/models/travel_package.dart';
import 'package:travel2u_v1/presentation/customer/package_detail_page.dart';
import 'package:travel2u_v1/presentation/widgets/custom_message_popup.dart';

class ManageTravelPage extends StatefulWidget {
  const ManageTravelPage({super.key});

  @override
  _ManageTravelPageState createState() => _ManageTravelPageState();
}

class _ManageTravelPageState extends State<ManageTravelPage> {
  final Map<String, dynamic> travelPackages = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = true;
  String userId = '';
  String userRole = 'staff';
  static const _staffColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _fetchTravelPackages();
  }

  Future<void> _fetchTravelPackages() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    userId = user.uid;
    travelPackages.clear();
    setState(() => isLoading = true);

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      userRole = userDoc.data()?['role'] ?? 'staff';
      QuerySnapshot querySnapshot;
      querySnapshot = await _firestore.collection('travel_packages').get();
      final docs = querySnapshot.docs.toList();

      docs.sort((a, b) {
        final aOwned = a['creatorId'] == userId;
        final bOwned = b['creatorId'] == userId;

        if (aOwned && !bOwned) return -1;
        if (!aOwned && bOwned) return 1;
        return 0; // keep relative order otherwise
      });
      // if (role == 'manager') {
      //   querySnapshot = await _firestore.collection('travel_packages').get();
      // } else {
      //   querySnapshot =
      //       await _firestore
      //           .collection('travel_packages')
      //           .where('creatorId', isEqualTo: user.uid)
      //           .get();
      // }

      for (var doc in docs) {
        travelPackages[doc.id] = doc.data();
      }
    } catch (e) {
      if (mounted) {
        MessagePopup.show(
          context,
          message: "Error fetchin gpackages: $e",
          type: MessageType.error,
          position: PopupPosition.top,
          duration: const Duration(seconds: 4),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleDelete(String key, String packageName) async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('Delete Package?'),
          content: Text(
            'Are you sure you want to delete "$packageName"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        final package = travelPackages[key];
        final imageUrl = package['imageUrl'];
        if (imageUrl != null && imageUrl.isNotEmpty) {
          try {
            final ref = FirebaseStorage.instance.refFromURL(imageUrl);
            await ref.delete();
          } catch (e) {
            debugPrint('⚠️ Error deleting image: $e');
          }
        }
        await _firestore.collection('travel_packages').doc(key).delete();
        setState(() {
          travelPackages.remove(key);
        });
        if (mounted) {
          MessagePopup.show(
            context,
            message: "Package deleted succesfully",
            type: MessageType.success,
            position: PopupPosition.top,
            duration: const Duration(seconds: 2),
          );
        }
      } catch (e) {
        if (mounted) {
          MessagePopup.show(
            context,
            message: "Error deleting package: $e",
            type: MessageType.error,
            position: PopupPosition.top,
            duration: const Duration(seconds: 4),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Travel Packages",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: _staffColor,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/add-travel-package',
          ).then((_) => _fetchTravelPackages());
        },
        backgroundColor: _staffColor,
        label: const Text('Add Package', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : travelPackages.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                onRefresh: _fetchTravelPackages,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: travelPackages.length,
                  itemBuilder: (context, index) {
                    String key = travelPackages.keys.elementAt(index);
                    var package = travelPackages[key];
                    return _buildPackageCard(context, key, package);
                  },
                ),
              ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.luggage_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "No Packages Yet",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Create your first travel package",
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(
    BuildContext context,
    String key,
    Map<String, dynamic> package,
  ) {
    final price = (package['price'] as num?)?.toStringAsFixed(2) ?? 'N/A';
    final packageName = package['name'] ?? 'Untitled Package';
    final destination = package['destination'] ?? 'No Destination';
    final duration = package['duration'] ?? 'N/A';
    final imageUrl = package['imageUrl'];
    bool canEdit = package['creatorId'] == userId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Image Header (if available)
          if (imageUrl != null && imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Image.network(
                imageUrl,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildImagePlaceholder();
                },
              ),
            )
          else
            _buildImagePlaceholder(),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Package Name and Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        packageName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _staffColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'RM $price',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _staffColor.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Destination and Duration
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        destination,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '$duration days',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    (canEdit || userRole == 'manager')
                        ? Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/update-travel-package',
                                arguments: {'id': key},
                              ).then((_) => _fetchTravelPackages());
                            },
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text(
                              'Edit',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: _staffColor,
                              side: BorderSide(color: _staffColor, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        )
                        : Container(),
                    const SizedBox(width: 8),

                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => PackageDetailPage(
                                    package: TravelPackage.fromJson(package),
                                  ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: const Text(
                          'View',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.blue.shade700,
                          side: BorderSide(
                            color: Colors.blue.shade700,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _handleDelete(key, packageName),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text(
                          'Delete',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.red.shade600,
                          side: BorderSide(
                            color: Colors.red.shade600,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _staffColor.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: _staffColor.withOpacity(0.3),
        ),
      ),
    );
  }
}
