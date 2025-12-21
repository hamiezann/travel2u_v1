import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:travel2u_v1/core/services/basic_service.dart';
import 'package:travel2u_v1/core/services/notification_service.dart';
import 'package:travel2u_v1/presentation/staff/chat_page.dart';
import 'package:travel2u_v1/presentation/staff/editItinerary.dart';
import 'package:travel2u_v1/presentation/widgets/custom_message_popup.dart';

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
                            final customerId = data["userId"] ?? '';
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

                                        Row(
                                          children: [
                                            // CHAT BUTTON
                                            Expanded(
                                              child: StreamBuilder<
                                                QuerySnapshot
                                              >(
                                                stream:
                                                    FirebaseFirestore.instance
                                                        .collection('chats')
                                                        .doc(bookingDoc.id)
                                                        .collection('messages')
                                                        .where(
                                                          'isRead',
                                                          isEqualTo: false,
                                                        )
                                                        .where(
                                                          'sender',
                                                          isEqualTo: 'customer',
                                                        )
                                                        // .where(
                                                        //   'data',
                                                        //   isEqualTo: userId,
                                                        // ) // only unread messages for this staff
                                                        .snapshots(),
                                                builder: (context, snapshot) {
                                                  int unreadCount = 0;
                                                  if (snapshot.hasData) {
                                                    unreadCount =
                                                        snapshot
                                                            .data!
                                                            .docs
                                                            .length;
                                                  }
                                                  return ElevatedButton.icon(
                                                    onPressed: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder:
                                                              (_) => ChatPage(
                                                                bookingId:
                                                                    bookingDoc
                                                                        .id,
                                                                clientName:
                                                                    mainUser["name"] ??
                                                                    "-",
                                                                customerId:
                                                                    customerId,
                                                                packageId:
                                                                    data["packageId"],
                                                              ),
                                                        ),
                                                      );
                                                    },
                                                    icon: Stack(
                                                      clipBehavior: Clip.none,
                                                      children: [
                                                        const Icon(
                                                          Icons
                                                              .chat_bubble_outline,
                                                          size: 18,
                                                        ),
                                                        if (unreadCount > 0)
                                                          Positioned(
                                                            top: -6,
                                                            right: -6,
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                    4,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color:
                                                                    Colors.red,
                                                                shape:
                                                                    BoxShape
                                                                        .circle,
                                                                border: Border.all(
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                  width: 1.5,
                                                                ),
                                                              ),
                                                              child: Text(
                                                                unreadCount
                                                                    .toString(),
                                                                style: const TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                  fontSize: 10,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                    label: Text(
                                                      "Chat",
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    style: ElevatedButton.styleFrom(
                                                      foregroundColor:
                                                          Colors.teal,
                                                      side: BorderSide(
                                                        color: Colors.teal,
                                                        width: 1.5,
                                                      ),
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 14,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              16,
                                                            ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),

                                            const SizedBox(width: 8),

                                            // EDIT BUTTON
                                            Expanded(
                                              child: ElevatedButton.icon(
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
                                                            bookingId:
                                                                bookingDoc.id,
                                                            packageId:
                                                                data["packageId"],
                                                          ),
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(
                                                  Icons.edit_outlined,
                                                  size: 18,
                                                ),
                                                label: const Text(
                                                  "Edit",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  foregroundColor:
                                                      Colors.blue.shade700,
                                                  side: BorderSide(
                                                    color: Colors.blue.shade700,
                                                    width: 1.5,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 14,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),

                                            const SizedBox(width: 8),

                                            // STATUS BUTTON
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed:
                                                    () => _updateStatus(
                                                      context,
                                                      bookingDoc.id,
                                                      data["status"],
                                                      data["packageName"],
                                                      data["packageId"],
                                                    ),
                                                icon: const Icon(
                                                  Icons.update,
                                                  size: 18,
                                                ),
                                                label: const Text(
                                                  "Status",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  foregroundColor: Colors.teal,
                                                  side: const BorderSide(
                                                    color: Colors.teal,
                                                    width: 1.5,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 14,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
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

  void _updateStatus(
    BuildContext context,
    String bookingId,
    String current,
    String package_name,
    String packageId,
  ) {
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
                  if (newStatus == current) {
                    if (context.mounted) Navigator.pop(context);
                    return;
                  }
                  try {
                    await FirebaseFirestore.instance
                        .collection('bookings')
                        .doc(bookingId)
                        .update({"status": newStatus});
                    final bookingDoc =
                        await FirebaseFirestore.instance
                            .collection('bookings')
                            .doc(bookingId)
                            .get();

                    final userId = bookingDoc.data()?['userId'] as String?;
                    if (userId != null) {
                      final String title =
                          "Booking Status: ${newStatus.toUpperCase()}";
                      final String body =
                          "Your booking $package_name ($bookingId) has been updated.";

                      await NotificationService().sendNotification(
                        title: title,
                        body: body,
                        userId: userId,
                        data: {
                          "bookingId": bookingId,
                          "packageId": packageId,
                          "type": "update-status",
                          "status": newStatus,
                        },
                      );
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      MessagePopup.show(
                        context,
                        message: "Status updated and user notified!",
                        type: MessageType.success,
                        position: PopupPosition.top,
                        duration: const Duration(seconds: 2),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      MessagePopup.show(
                        context,
                        message: "Error updating status: $e",
                        type: MessageType.error,
                        position: PopupPosition.top,
                        duration: const Duration(seconds: 4),
                      );
                    }
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
