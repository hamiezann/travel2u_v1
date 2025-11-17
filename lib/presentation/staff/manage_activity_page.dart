import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:travel2u_v1/presentation/staff/chat_page.dart';
import 'package:travel2u_v1/presentation/staff/editItinerary.dart';

class ManageActivityPage extends StatefulWidget {
  const ManageActivityPage({super.key});

  @override
  State<ManageActivityPage> createState() => _ManageActivityPageState();
}

class _ManageActivityPageState extends State<ManageActivityPage> {
  String _filter = "all";

  @override
  Widget build(BuildContext context) {
    Query bookingsQuery = FirebaseFirestore.instance.collection('bookings');

    if (_filter != "all") {
      bookingsQuery = bookingsQuery.where("status", isEqualTo: _filter);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Bookings & Itineraries"),
        backgroundColor: Colors.teal,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _filter = value),
            itemBuilder:
                (context) => [
                  const PopupMenuItem(value: "all", child: Text("All")),
                  const PopupMenuItem(value: "booked", child: Text("Booked")),
                  const PopupMenuItem(value: "pending", child: Text("Pending")),
                  const PopupMenuItem(
                    value: "completed",
                    child: Text("Completed"),
                  ),
                ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            bookingsQuery.orderBy("createdAt", descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookings = snapshot.data!.docs;

          if (bookings.isEmpty) {
            return const Center(child: Text("No bookings found"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final bookingDoc = bookings[index];
              final data = bookingDoc.data() as Map<String, dynamic>;

              final mainUser = data["mainUser"] ?? {};
              final travelers = List.from(data["travelers"] ?? []);
              final preferences = data["preferences"] ?? {};
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
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Package & Itinerary Info
                      Text(
                        data["packageTitle"] ?? "Unknown Package",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Itinerary Status: ${data["itineraryStatus"] ?? "-"}",
                      ),
                      Text("Booking Status: ${data["status"] ?? "-"}"),
                      const Divider(),

                      // User Info
                      Text("User Name: ${mainUser["name"] ?? "-"}"),
                      Text("Email: ${mainUser["email"] ?? "-"}"),
                      Text("Phone: ${mainUser["phone"] ?? "-"}"),
                      Text(
                        "Number of Travelers: ${mainUser["numTravelers"] ?? travelers.length}",
                      ),
                      if (travelDate != null)
                        Text(
                          "Travel Date: ${travelDate.toLocal()}".split(" ")[0],
                        ),
                      const Divider(),

                      // Travelers
                      Text(
                        "Travelers:",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...travelers.map(
                        (t) => Text(
                          "${t["name"] ?? "-"} (${t["relationship"] ?? "-"})",
                        ),
                      ),

                      const Divider(),

                      // Preferences
                      Text("Food Preferences: ${foodPreference.join(", ")}"),
                      Text("Avoid Preferences: ${avoidPreference.join(", ")}"),
                      Text(
                        "Preferred Activities: ${preferredActivities.join(", ")}",
                      ),
                      const SizedBox(height: 12),

                      // Actions
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chat, color: Colors.green),
                              tooltip: "Chat with Client",
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => ChatPage(
                                          bookingId: bookingDoc.id,
                                          clientName: mainUser["name"] ?? "-",
                                        ),
                                  ),
                                );
                              },
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              label: const Text("Edit Itinerary"),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => EditItineraryPage(
                                          itineraryId: data["itineraryId"],
                                        ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              icon: const Icon(
                                Icons.update,
                                color: Colors.orange,
                              ),
                              label: const Text("Update Status"),
                              onPressed:
                                  () => _updateStatus(
                                    context,
                                    bookingDoc.id,
                                    data["status"],
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _updateStatus(BuildContext context, String bookingId, String current) {
    final statuses = ["booked", "pending", "completed", "cancelled"];
    String newStatus = current;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Update Booking Status"),
            content: DropdownButtonFormField<String>(
              value: current,
              items:
                  statuses
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
              onChanged: (value) => newStatus = value!,
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
                  Navigator.pop(context);
                },
                child: const Text("Update"),
              ),
            ],
          ),
    );
  }
}
