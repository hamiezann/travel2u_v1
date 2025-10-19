import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchTravelPackages();
  }

  Future<void> _fetchTravelPackages() async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore.collection('travel_packages').get();
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
      // display snackbar with error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching travel packages: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Travel Packages"),
        backgroundColor: Colors.teal,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add-travel-package');
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal, Colors.white],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                // replace with actual content (e.g., list of travel packages)
                child: ListView.builder(
                  itemCount: travelPackages.length,
                  itemBuilder: (context, index) {
                    String key = travelPackages.keys.elementAt(index);
                    var package = travelPackages[key];
                    // return card for each travel package with button to update and delete
                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text(package['name'] ?? 'No Name'),
                        subtitle: Text(
                          package['description'] ?? 'No Description',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/update-travel-package',
                                  arguments: {'id': key, 'data': package},
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                // confirm deletion
                                final bool?
                                confirmDelete = await showDialog<bool>(
                                  context: context,
                                  builder: (BuildContext dialogContext) {
                                    return AlertDialog(
                                      title: const Text('Confirm Deletion'),
                                      content: const Text(
                                        'Are you sure you want to delete this travel package?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(
                                                dialogContext,
                                              ).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            await _firestore
                                                .collection('travel_packages')
                                                .doc(key)
                                                .delete();
                                            Navigator.of(
                                              dialogContext,
                                            ).pop(true);
                                          },
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (confirmDelete == true) {
                                  setState(() {
                                    travelPackages.remove(key);
                                  });
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Travel package deleted'),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
