import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:travel2u_v1/presentation/customer/booking_review_page.dart';

class ReviewListingPage extends StatelessWidget {
  final String uid;

  const ReviewListingPage({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Review",
          style: TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey.shade100,
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection("bookings")
                .where("userId", isEqualTo: uid)
                .where("status", isEqualTo: "completed") // only completed trips
                .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookings = snap.data!.docs;

          if (bookings.isEmpty) {
            return const Center(child: Text("No completed trips"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: bookings.length,
            itemBuilder: (context, i) {
              final b = bookings[i].data() as Map<String, dynamic>;
              final bookingId = bookings[i].id;
              final packageId = b['packageId'];

              return FutureBuilder<DocumentSnapshot>(
                future:
                    FirebaseFirestore.instance
                        .collection("travel_packages")
                        .doc(packageId)
                        .get(),
                builder: (context, pkgSnap) {
                  if (!pkgSnap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (!pkgSnap.data!.exists) {
                    return const Text("Package not found");
                  }

                  final package = pkgSnap.data!.data() as Map<String, dynamic>;

                  // ------------------- PACKAGE FIELDS -------------------
                  final packageImage = package['imageUrl'] ?? '';
                  final hotelName = package['hotelDetail'] ?? '';
                  final destination = package['destination'] ?? '';
                  final rating = package['hotelRating'] ?? '0';
                  final duration = package['duration'] ?? 1;
                  final guideName = package['tourGuide'] ?? "No guide";

                  // ------------------- BOOKING FIELDS -------------------
                  final startDate =
                      DateTime.tryParse(b['travelDate'] ?? "") ??
                      DateTime.now();
                  final endDate = startDate.add(Duration(days: duration));

                  // Now check review
                  return FutureBuilder<QuerySnapshot>(
                    future:
                        FirebaseFirestore.instance
                            .collection("reviews")
                            .where("bookingId", isEqualTo: bookingId)
                            .limit(1)
                            .get(),
                    builder: (context, reviewSnap) {
                      final hasReview =
                          reviewSnap.hasData &&
                          reviewSnap.data!.docs.isNotEmpty;

                      final review =
                          hasReview
                              ? reviewSnap.data!.docs.first.data()
                                  as Map<String, dynamic>
                              : null;

                      final reviewDate =
                          hasReview
                              ? (review?['timestamp'] as Timestamp?)?.toDate()
                              : null;
                      final reviewDoc =
                          hasReview ? reviewSnap.data!.docs.first : null;
                      final String? reviewId = reviewDoc?.id;
                      return buildBookingTile(
                        context: context,
                        packageImage: packageImage,
                        hotelName: hotelName,
                        destination: destination,
                        rating: rating.toString(),
                        startDate: startDate,
                        endDate: endDate,
                        tourGuide: guideName,
                        hasReview: hasReview,
                        reviewDate: reviewDate,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => ReviewPage(
                                    bookingId: bookingId,
                                    packageId: packageId,
                                    mode: hasReview ? 'view' : 'add',
                                    reviewId: reviewId,
                                  ),
                            ),
                          );
                        },
                        onEdit: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => ReviewPage(
                                    bookingId: bookingId,
                                    packageId: packageId,
                                    mode: 'edit',
                                    reviewId: reviewId,
                                  ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget buildBookingTile({
    required BuildContext context,
    required bool hasReview,
    required DateTime? reviewDate,
    required VoidCallback onTap,
    required String packageImage,
    required String hotelName,
    required String destination,
    required String rating,
    required DateTime startDate,
    required DateTime endDate,
    required String tourGuide,
    required VoidCallback onEdit,
  }) {
    const Widget subtleDivider = Divider(
      color: Color(0xFFE0E0E0), // A light grey for subtlety
      height: 0, // Controls vertical space above/below the line
      thickness: 1,
      indent: 0, // No indent for full width
      endIndent: 0,
    );
    // Vertical Divider
    const Widget verticalDivider = VerticalDivider(
      color: Color(0xFFE0E0E0), // A light grey for subtlety
      width: 16, // Controls horizontal space (margin) around the divider
      thickness: 1, // The thickness of the line itself
      indent: 4, // Space above the line (top of the available height)
      endIndent: 4, // Space below the line (bottom of the available height)
    );
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        // padding: const EdgeInsets.all(12),
        // padding: EdgeInsets.only(bottom: ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- Row 1: Image + hotel/destination/rating ----------
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(15)),
                  // borderRadius: BorderRadiusGeometry.all(Radius.circular(10)),
                  child: Image.network(
                    packageImage,
                    height: 100,
                    width: MediaQuery.of(context).size.width * 0.25,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hotelName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 18,
                          ),
                          Text(
                            destination,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.yellow,
                            size: 18,
                          ),
                          Text(rating),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            subtleDivider,
            // const SizedBox(height: 12),

            // ---------- Row 2: Date + Guide ----------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                  child: Text(
                    "${DateFormat('dd MMM yyyy').format(startDate)} → ${DateFormat('dd MMM yyyy').format(endDate)}",
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const VerticalDivider(
                  color: Color(0xFFE0E0E0),
                  width: 16, // Width allocated for the divider widget
                  thickness: 1,
                  indent: 4,
                  endIndent: 4,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                  child: Text(
                    "Guide: $tourGuide",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            subtleDivider,

            // ---------- Row 3: Chat + Review info ----------
            Row(
              // mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 10),
                hasReview
                    ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          "Reviewed on ${DateFormat('dd MMM yyyy').format(reviewDate!)}",
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        //  edit button
                        ElevatedButton(
                          onPressed: onEdit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade400,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),

                            elevation: 0,
                            shadowColor: Colors.transparent,

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Edit Review',

                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                    : const Text(
                      "No review",
                      style: TextStyle(color: Colors.red, fontSize: 13),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
