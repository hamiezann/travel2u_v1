import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:travel2u_v1/core/services/basic_service.dart';

class StaffReviewPage extends StatefulWidget {
  const StaffReviewPage({super.key});

  @override
  State<StaffReviewPage> createState() => _StaffReviewPageState();
}

class _StaffReviewPageState extends State<StaffReviewPage> {
  final BasicService _basicService = BasicService();

  // late Future<String> _userIdFuture;
  // late Future<String> _roleFuture;
  late Future<String?> userId;
  late Future<String?> role;
  @override
  void initState() {
    super.initState();
    // _userIdFuture = _basicService.getUserId().then((v) => v ?? "");
    userId = _basicService.getUserId();
    role = userId.then((id) => _basicService.getUserRole(id ?? ""));
    // _roleFuture = _userIdFuture.then((id) => _basicService.getUserRole(id) ?? "staff");
  }

  /// =========================
  /// LOAD REVIEWS (Manager / Staff Filtering)
  /// =========================
  Future<Map<String, List<Map<String, dynamic>>>> _loadGroupedReviews(
    String uid,
    String role,
  ) async {
    final firestore = FirebaseFirestore.instance;

    QuerySnapshot reviewSnap;

    if (role == "manager") {
      reviewSnap = await firestore.collection("reviews").get();
    } else {
      final pkgSnap =
          await firestore
              .collection("travel_packages")
              .where("creatorId", isEqualTo: uid)
              .get();

      final packageIds = pkgSnap.docs.map((d) => d.id).toList();
      if (packageIds.isEmpty) return {};

      reviewSnap =
          await firestore
              .collection("reviews")
              .where("packageId", whereIn: packageIds)
              .get();
    }

    // Group reviews by packageId
    Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var doc in reviewSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final pkgId = data["packageId"];

      grouped.putIfAbsent(pkgId, () => []);
      grouped[pkgId]!.add({"id": doc.id, ...data});
    }

    return grouped;
  }

  /// =========================
  /// MAIN BUILD
  /// =========================
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([userId, role]),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final uid = snap.data![0] as String;
        final role = snap.data![1] as String;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              "Reviews",
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            backgroundColor: Colors.white,
          ),
          backgroundColor: Colors.grey.shade100,
          body: FutureBuilder(
            future: _loadGroupedReviews(uid, role),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final grouped =
                  snap.data as Map<String, List<Map<String, dynamic>>>;

              if (grouped.isEmpty) {
                return const Center(child: Text("No reviews found"));
              }
              print(grouped);
              return ListView(
                padding: const EdgeInsets.all(12),
                children:
                    grouped.entries.map((entry) {
                      final packageId = entry.key;
                      final reviews = entry.value;

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

                          if (!pkgSnap.data!.exists) return const SizedBox();

                          final pkg =
                              pkgSnap.data!.data() as Map<String, dynamic>;
                          return _buildPackageSection(pkg, reviews);
                        },
                      );
                    }).toList(),
              );
            },
          ),
        );
      },
    );
  }

  /// =========================
  /// PACKAGE SECTION
  /// =========================
  Widget _buildPackageSection(
    Map<String, dynamic> package,
    List<Map<String, dynamic>> reviews,
  ) {
    // Helper to get location details, assuming it might be stored elsewhere than "hotelDetail"
    final String packageName =
        package["name"] ?? package["hotelDetail"] ?? "Unknown Package";
    final String packageLocation = package["destination"] ?? "Unknown Location";
    final String packageImage = package["imageUrl"] ?? "";

    // Calculate average rating if needed (assuming 'rating' field is numeric in reviews)
    double averageRating = 0;
    if (reviews.isNotEmpty) {
      final totalRating = reviews.fold<double>(
        0.0,
        (sum, item) => sum + (item['rating'] as num).toDouble(),
      );
      averageRating = totalRating / reviews.length;
    }

    // A separate widget for the horizontal divider for clarity
    const Widget lightDivider = Divider(
      color: Color(0xFFE0E0E0),
      height: 24,
      thickness: 1,
      indent: 0,
      endIndent: 0,
    );

    return Container(
      // Replacing Card with Container for more styling control
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ), // Subtle border
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1), // Very light shadow
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. PACKAGE HEADER
          Padding(
            padding: const EdgeInsets.all(
              16.0,
            ), // Padding applied to the inner content
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Package Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child:
                      packageImage.isNotEmpty
                          ? Image.network(
                            packageImage,
                            height: 70, // Slightly smaller image
                            width: 70,
                            fit: BoxFit.cover,
                          )
                          : Container(
                            height: 70,
                            width: 70,
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.photo_size_select_actual_outlined,
                              color: Colors.grey,
                            ),
                          ),
                ),
                const SizedBox(width: 12),
                // Package Title and Location
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        packageName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18, // Slightly larger title
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.red.shade400,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            packageLocation,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Review Summary / Average Rating
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            reviews.isNotEmpty
                                ? "${averageRating.toStringAsFixed(1)} Average Rating (${reviews.length} reviews)"
                                : "No reviews yet.",
                            style: TextStyle(
                              color:
                                  reviews.isNotEmpty
                                      ? Colors.black87
                                      : Colors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Add the divider after the main package info
          lightDivider,

          // 2. REVIEWS LIST
          // We map and build the review tiles without extra padding,
          // as the _buildReviewTile is assumed to handle its own spacing/card (like the previous example).
          ...reviews.map((r) => _buildReviewTile(r)).toList(),

          // Optional: Show a button if there are many reviews
          if (reviews.length > 3)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: TextButton(
                  onPressed: () {
                    // Handle navigation to all reviews
                  },
                  child: const Text("View All Reviews"),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// =========================
  /// INDIVIDUAL REVIEW TILE
  /// =========================

  Widget _buildReviewTile(Map<String, dynamic> review) {
    final timestamp = (review["timestamp"] as Timestamp).toDate();
    final String ratingValue = review["rating"].toString();

    // --- Start of FutureBuilder Chain (Retrieving Booking) ---
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance
              .collection("bookings")
              .doc(review["bookingId"])
              .get(),
      builder: (context, bookingSnap) {
        if (!bookingSnap.hasData || !bookingSnap.data!.exists) {
          // Handle loading/missing booking gracefully
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Booking information unavailable."),
            ),
          );
        }

        final booking = bookingSnap.data!.data() as Map<String, dynamic>;
        final userId = booking["userId"] ?? booking["uid"];

        // --- Start of FutureBuilder Chain (Retrieving User) ---
        return FutureBuilder<DocumentSnapshot>(
          future:
              FirebaseFirestore.instance.collection("users").doc(userId).get(),
          builder: (context, userSnap) {
            final user = userSnap.data?.data() as Map<String, dynamic>?;
            final photo = user?["imageUrl"] ?? "";
            final name = user?["firstName"] ?? "Anonymous User";

            final ImageProvider userImage =
                photo.isNotEmpty
                    ? NetworkImage(photo)
                    : const AssetImage("assets/default_user.jpg")
                        as ImageProvider;

            // ----------------------------------------------------
            // 1. HEADER (What is always visible - used as ExpansionTile title)
            // ----------------------------------------------------
            Widget reviewHeader = Row(
              children: [
                // Profile Photo
                CircleAvatar(
                  radius: 20,
                  backgroundImage: userImage,
                  backgroundColor: Colors.grey.shade100,
                ),
                const SizedBox(width: 12),
                // Name and Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        DateFormat(
                          "dd MMM yyyy 'at' hh:mm a",
                        ).format(timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Rating Display
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.yellow.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.yellow.shade700),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Colors.yellow.shade700, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        ratingValue,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.yellow.shade800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );

            // ----------------------------------------------------
            // 2. BODY (What is shown when expanded - used as ExpansionTile children)
            // ----------------------------------------------------
            List<Widget> reviewBody = [];

            // Review Text
            if ((review["review"] ?? "").toString().isNotEmpty) {
              reviewBody.add(
                Text(
                  review["review"],
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black,
                    height: 1.4,
                  ),
                ),
              );
            }

            // Review Images
            if (review["images"] != null &&
                (review["images"] as List).isNotEmpty) {
              reviewBody.add(
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: SizedBox(
                    height: 80,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children:
                          (review["images"] as List)
                              .map(
                                (img) => Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      img,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                ),
              );
            }

            // ----------------------------------------------------
            // 3. FINAL WIDGET STRUCTURE (ExpansionTile)
            // ----------------------------------------------------
            return Container(
              margin: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 16.0,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade200),
              ),
              // Replaced Column/Padding/ListTile structure with ExpansionTile
              child: ExpansionTile(
                key: ValueKey(
                  review["reviewId"],
                ), // Use a unique key for stability
                title: reviewHeader, // The header (always visible)
                tilePadding: const EdgeInsets.all(
                  16.0,
                ), // Padding around the header
                childrenPadding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 16,
                ), // Padding for the body
                // The body content (review text and images)
                children: reviewBody,
                // Optional: Customize the rotation of the icon
                iconColor: Colors.grey.shade600,
                collapsedIconColor: Colors.grey.shade600,
              ),
            );
          },
        );
      },
    );
  }
}
