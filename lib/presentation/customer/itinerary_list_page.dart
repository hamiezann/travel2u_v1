import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ItinerariesPage extends StatefulWidget {
  const ItinerariesPage({super.key});

  @override
  State<ItinerariesPage> createState() => _ItinerariesPageState();
}

class _ItinerariesPageState extends State<ItinerariesPage> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    // add space below as it blocked by bottom nav bar

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection("itineraries")
              .where("userId", isEqualTo: uid)
              .orderBy("createdAt", descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              "No itineraries available yet.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final List days = data["days"] ?? [];
            final String status = data["status"] ?? "pending";
            final String generationNotes = data["generationNotes"] ?? "";

            return _buildItineraryCard(days, status, generationNotes);
          },
        );
      },
    );
  }

  Widget _buildItineraryCard(List days, String status, String generationNotes) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (title + status chip)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Your Trip Itinerary",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                Chip(
                  label: Text(
                    status.toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: _statusColor(status),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Generation notes block
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blueGrey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                "📝 *Generation Notes* "
                "${generationNotes}",
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
            ),

            const SizedBox(height: 18),

            // Days section
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final dayData = days[index];
                final List activities = dayData["activities"] ?? [];

                return _buildDaySection(index + 1, activities);
              },
            ),

            const SizedBox(height: 8),

            // Action buttons row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.receipt_long),
                    label: const Text("Booking Details"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.chat_bubble),
                    label: const Text("Chat"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Download itinerary button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Itinerary downloaded!')),
                  );
                },
                icon: const Icon(Icons.download),
                label: const Text("Download Itinerary"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySection(int dayNumber, List activities) {
    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Day $dayNumber",
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 14),

          // Activities timeline
          ...activities.map((act) {
            return _buildTimelineItem(
              act["name"] ?? "",
              act["duration"] ?? "",
              act["location"] ?? "",
              act["type"] ?? "",
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    String duration,
    String location,
    String type,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dot + Line
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  shape: BoxShape.circle,
                ),
              ),
              Container(width: 2, height: 50, color: Colors.blue.shade200),
            ],
          ),

          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    duration,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  Text(
                    location,
                    style: const TextStyle(color: Colors.black45, fontSize: 12),
                  ),
                  Text(
                    type,
                    style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case "complete":
        return Colors.green;
      case "pending":
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }
}
