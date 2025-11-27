import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:travel2u_v1/core/services/basic_service.dart';
import 'package:travel2u_v1/presentation/staff/chat_page.dart';
import 'package:travel2u_v1/presentation/staff/editItinerary.dart';

class ManageActivityPage extends StatefulWidget {
  const ManageActivityPage({super.key});

  @override
  State<ManageActivityPage> createState() => _ManageActivityPageState();
}

class _ManageActivityPageState extends State<ManageActivityPage> {
  String _filter = "all";
  final _basicService = BasicService();
  String userId = '';
  String role = '';
  List<String> _staffPackageIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _fetcthUserInfo();
    if (role == 'staff') {
      await _fetchStaffPackageIds();
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetcthUserInfo() async {
    final id = await _basicService.getUserId();
    if (id != null) {
      final userole = await _basicService.getUserRole(id);
      if (mounted) {
        setState(() {
          userId = id;
          role = userole ?? '';
        });
      }
    }
  }

  Future<void> _fetchStaffPackageIds() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('travel_packages')
              .where('creatorId', isEqualTo: userId)
              .get();

      setState(() {
        _staffPackageIds = querySnapshot.docs.map((doc) => doc.id).toList();
      });
    } catch (e) {
      print("Error fetching staff package IDs: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    Query bookingsQuery = FirebaseFirestore.instance.collection('bookings');
    if (role == "staff") {
      if (_staffPackageIds.isNotEmpty) {
        bookingsQuery = bookingsQuery.where(
          'packageId',
          whereIn: _staffPackageIds,
        );
      }
    } else {
      bookingsQuery.where('packageId', isEqualTo: '__NO_MATCH__');
    }

    if (_filter != "all") {
      bookingsQuery = bookingsQuery.where("status", isEqualTo: _filter);
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Manage Bookings",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body:
          (_isLoading)
              ? Center(child: CircularProgressIndicator())
              : (role == 'staff' && _staffPackageIds.isEmpty)
              ? _buildNoBooking()
              : Column(
                children: [
                  // Filter Chips Section
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip("All", "all"),
                          const SizedBox(width: 8),
                          _buildFilterChip("Booked", "booked"),
                          const SizedBox(width: 8),
                          _buildFilterChip("Pending", "pending"),
                          const SizedBox(width: 8),
                          _buildFilterChip("Completed", "completed"),
                          const SizedBox(width: 8),
                          _buildFilterChip("Cancelled", "cancelled"),
                        ],
                      ),
                    ),
                  ),

                  // Bookings List
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream:
                          bookingsQuery
                              .orderBy("createdAt", descending: true)
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final bookings = snapshot.data!.docs;

                        if (bookings.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "No bookings found",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: bookings.length,
                          itemBuilder: (context, index) {
                            final bookingDoc = bookings[index];
                            final data =
                                bookingDoc.data() as Map<String, dynamic>;

                            final mainUser = data["mainUser"] ?? {};
                            final travelers = List.from(
                              data["travelers"] ?? [],
                            );
                            final avoidPreference = List.from(
                              mainUser["avoidPreference"] ?? [],
                            );
                            final foodPreference = List.from(
                              mainUser["foodPreference"] ?? [],
                            );
                            final preferredActivities = List.from(
                              mainUser["preferredActivities"] ?? [],
                            );

                            DateTime? travelDate;
                            try {
                              final rawDate = data["travelDate"];
                              if (rawDate != null) {
                                if (rawDate is Timestamp) {
                                  travelDate = rawDate.toDate();
                                } else if (rawDate is String) {
                                  travelDate = DateTime.tryParse(rawDate);
                                }
                              }
                            } catch (_) {
                              travelDate = null;
                            }

                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  // Header with Package Name and Status
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(data["status"]),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        topRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data["packageName"] ??
                                              "Unknown Package",
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Status: ${(data["status"] ?? "-").toUpperCase()}",
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Content
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Client Info
                                        _buildInfoRow(
                                          Icons.person,
                                          mainUser["name"] ?? "-",
                                        ),
                                        const SizedBox(height: 8),
                                        _buildInfoRow(
                                          Icons.email,
                                          mainUser["email"] ?? "-",
                                        ),
                                        const SizedBox(height: 8),
                                        _buildInfoRow(
                                          Icons.phone,
                                          mainUser["phone"] ?? "-",
                                        ),
                                        const SizedBox(height: 8),
                                        _buildInfoRow(
                                          Icons.groups,
                                          "${mainUser["numTravelers"] ?? travelers.length} Travelers",
                                        ),
                                        if (travelDate != null) ...[
                                          const SizedBox(height: 8),
                                          _buildInfoRow(
                                            Icons.calendar_today,
                                            "${travelDate.toLocal()}".split(
                                              " ",
                                            )[0],
                                          ),
                                        ],

                                        const SizedBox(height: 16),

                                        // Preferences Summary
                                        if (foodPreference.isNotEmpty ||
                                            avoidPreference.isNotEmpty ||
                                            preferredActivities.isNotEmpty) ...[
                                          const Text(
                                            "Preferences",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          if (foodPreference.isNotEmpty)
                                            _buildPreferenceChips(
                                              "Food",
                                              foodPreference,
                                            ),
                                          if (avoidPreference.isNotEmpty)
                                            _buildPreferenceChips(
                                              "Avoid",
                                              avoidPreference,
                                            ),
                                          if (preferredActivities.isNotEmpty)
                                            _buildPreferenceChips(
                                              "Activities",
                                              preferredActivities,
                                            ),
                                          const SizedBox(height: 16),
                                        ],

                                        // Action Buttons
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                icon: const Icon(
                                                  Icons.chat_bubble_outline,
                                                  size: 14,
                                                ),
                                                label: const Text("Chat"),
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (_) => ChatPage(
                                                            bookingId:
                                                                bookingDoc.id,
                                                            clientName:
                                                                mainUser["name"] ??
                                                                "-",
                                                          ),
                                                    ),
                                                  );
                                                },
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.teal,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                icon: const Icon(
                                                  Icons.edit_outlined,
                                                  size: 14,
                                                ),
                                                label: const Text("Edit"),
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (
                                                            _,
                                                          ) => EditItineraryPage(
                                                            itineraryId:
                                                                data["itineraryId"],
                                                          ),
                                                    ),
                                                  );
                                                },
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.blue,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                // icon: const Icon(
                                                //   Icons.update,
                                                //   size: 12,
                                                // ),
                                                label: const Text(
                                                  "Status",
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                onPressed:
                                                    () => _updateStatus(
                                                      context,
                                                      bookingDoc.id,
                                                      data["status"],
                                                    ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.teal,
                                                  foregroundColor: Colors.white,
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
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildNoBooking() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flight_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "No Booking Yet",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Manage your client bookings seemlessly",
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filter = value);
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.blue,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      checkmarkColor: Colors.white,
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }

  Widget _buildPreferenceChips(String label, List items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          ...items.map(
            (item) => Chip(
              label: Text(
                item.toString(),
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: Colors.blue[50],
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case "booked":
        return Colors.green;
      case "pending":
        return Colors.orange;
      case "completed":
        return Colors.blue;
      case "cancelled":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _updateStatus(BuildContext context, String bookingId, String current) {
    final statuses = ["booked", "pending", "completed", "cancelled"];
    String newStatus = current;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Update Booking Status"),
            content: StatefulBuilder(
              builder: (context, setDialogState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children:
                      statuses.map((status) {
                        return RadioListTile<String>(
                          title: Text(status.toUpperCase()),
                          value: status,
                          groupValue: newStatus,
                          activeColor: Colors.teal,
                          onChanged: (value) {
                            setDialogState(() => newStatus = value!);
                          },
                        );
                      }).toList(),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('bookings')
                      .doc(bookingId)
                      .update({"status": newStatus});
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Status updated successfully"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Update"),
              ),
            ],
          ),
    );
  }
}
