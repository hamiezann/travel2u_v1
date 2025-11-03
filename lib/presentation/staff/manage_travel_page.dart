import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class ManageTravelPage extends StatefulWidget {
  const ManageTravelPage({super.key});

  @override
  _ManageTravelPageState createState() => _ManageTravelPageState();
}

class _ManageTravelPageState extends State<ManageTravelPage> {
  // list of packages
  final Map<String, dynamic> travelPackages = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = true;

  static const _staffColor = Colors.teal;

  @override
  void initState() {
    super.initState();
    _fetchTravelPackages();
  }

  // Reload data function (used for initial load and after deletion)
  Future<void> _fetchTravelPackages() async {
    final user = FirebaseAuth.instance.currentUser;
    travelPackages.clear();
    try {
      QuerySnapshot querySnapshot =
          await _firestore
              .collection('travel_packages')
              .where('creatorId', isEqualTo: user?.uid)
              .get();
      setState(() {
        for (var doc in querySnapshot.docs) {
          travelPackages[doc.id] = doc.data();
        }
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching travel packages: $e')),
      );
    }
  }

  Future<void> _handleDelete(String key, String packageName) async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text(
            'Are you sure you want to delete the package: "$packageName"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              // Use ElevatedButton for the destructive action
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        // Delete from Firestore
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Travel package deleted successfully!'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting package: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Package Inventory",
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
        label: const Text('New Package', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : travelPackages.isEmpty
              ? _buildEmptyState()
              : Container(
                decoration: BoxDecoration(color: _staffColor.shade50),
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
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: _staffColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            "No Travel Packages Found",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Tap '+' to add your first package.",
            style: TextStyle(fontSize: 16, color: Colors.grey),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    packageName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'RM $price',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            Text(
              '${package['destination'] ?? 'No Destination'} • ${package['duration'] ?? 'N/A'} days',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),

            const Divider(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/update-travel-package',
                      arguments: {'id': key}, // Pass ID only
                    ).then((_) => _fetchTravelPackages());
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _staffColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _handleDelete(key, packageName),
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
