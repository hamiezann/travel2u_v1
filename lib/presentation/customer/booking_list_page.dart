import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:travel2u_v1/presentation/customer/booking_detail_page.dart';

class MyTripsPage extends StatefulWidget {
  const MyTripsPage({super.key});

  @override
  State<MyTripsPage> createState() => _MyTripsPageState();
}

class _MyTripsPageState extends State<MyTripsPage> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  Future<Map<String, dynamic>?> _fetchPackageDetails(String packageId) async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection("travel_packages")
              .doc(packageId)
              .get();

      if (!doc.exists) return null;

      return doc.data();
    } catch (e) {
      print("❌ Error fetching package details: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.blue[50],
            child: const TabBar(
              labelColor: Colors.blue,
              indicatorColor: Colors.blue,
              tabs: [Tab(text: 'Upcoming'), Tab(text: 'Completed')],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildTrips(context, completed: false),
                _buildTrips(context, completed: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Fetch all bookings and filter in UI
  Widget _buildTrips(BuildContext context, {required bool completed}) {
    return StreamBuilder(
      stream:
          FirebaseFirestore.instance
              .collection('bookings')
              .where('userId', isEqualTo: uid)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        // Convert Firestore docs to usable maps
        final trips = docs.map((d) => d.data()).toList();

        // Split by complete or upcoming
        final now = DateTime.now();

        final filtered =
            trips.where((trip) {
              final status = trip['status'] ?? "";
              final date = DateTime.tryParse(trip['travelDate'] ?? "") ?? now;

              if (completed) {
                return status == "completed";
              } else {
                return status !=
                    "completed"; // includes empty, pending, generated
              }
            }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Text(
              completed ? "No completed trips yet." : "No upcoming trips.",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final trip = filtered[index];
            return _buildTripCard(context, trip, completed);
          },
        );
      },
    );
  }

  Widget _buildTripCard(
    BuildContext context,
    Map<String, dynamic> trip,
    bool completed,
  ) {
    final travelDate = DateTime.tryParse(trip['travelDate'] ?? "");
    final now = DateTime.now();
    int daysLeft = travelDate != null ? travelDate.difference(now).inDays : 0;

    final packageId = trip["packageId"] ?? "";
    final status = trip["itineraryStatus"] ?? "";

    return FutureBuilder(
      future: _fetchPackageDetails(packageId),
      builder: (context, snapshot) {
        final pkg = snapshot.data;

        final imageUrl = pkg?["imageUrl"] ?? "";
        final packageName = pkg?["name"] ?? "Unknown Package";
        final destination = pkg?["destination"] ?? "Unknown";

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) =>
                        BookingDetailPage(packageData: pkg!, bookingData: trip),
              ),
            );
          },
          child: Container(
            height: 100,
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              // borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                // dark overlay for readable text
                Container(
                  decoration: BoxDecoration(
                    // borderRadius: BorderRadius.circular(16),
                    color: Colors.black.withOpacity(0.3),
                  ),
                ),

                // CONTENT OVERLAY
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // LEFT: DAY COUNT
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            daysLeft >= 0 ? "$daysLeft" : "${daysLeft.abs()}",
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            completed ? "Days Ago" : "Days Left",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(width: 20),

                      // RIGHT: DESTINATION + DATE
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              destination,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              travelDate != null
                                  ? DateFormat(
                                    'EEEE, MMMM d',
                                  ).format(travelDate.toLocal())
                                  : "Unknown Date",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
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
  }

  void _showFeedbackDialog(BuildContext context, Map trip) {
    final rating = TextEditingController();
    final comments = TextEditingController();

    showDialog(
      context: context,
      builder:
          (c) => AlertDialog(
            title: const Text('Submit Feedback'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: rating,
                  decoration: const InputDecoration(
                    labelText: 'Rating (1–5)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: comments,
                  decoration: const InputDecoration(
                    labelText: 'Comments',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  // TODO save feedback to Firestore
                  Navigator.pop(c);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feedback submitted!')),
                  );
                },
                child: const Text('Submit'),
              ),
            ],
          ),
    );
  }
}
