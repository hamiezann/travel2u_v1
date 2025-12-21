import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:travel2u_v1/core/models/travel_package.dart';
import 'package:travel2u_v1/presentation/customer/package_detail_page.dart';
// import 'package:travel2u_v1/presentation/widgets/ads_placeholder.dart';
import 'package:travel2u_v1/presentation/widgets/carousel_slider.dart';
import 'package:travel2u_v1/presentation/widgets/custom_message_popup.dart';
import 'package:travel2u_v1/presentation/widgets/popular_packages_section.dart';

class PackagesPage extends StatefulWidget {
  const PackagesPage({super.key});

  @override
  _PackagesPageState createState() => _PackagesPageState();
}

class _PackagesPageState extends State<PackagesPage> {
  List<TravelPackage> packageList = [];
  bool isLoading = false;
  final _filterTextController = TextEditingController();
  // String userId = FirebaseAuth.instance.currentUser!.uid;
  final user = FirebaseAuth.instance.currentUser;
  List<String> selectedTags = [];
  List<String> tagsList = [];
  DateTime? startDate;
  DateTime? endDate;
  List<TravelPackage> popularPackages = [];
  bool showFilter = false; // toggle filter section

  @override
  void initState() {
    super.initState();
    _filterTextController.addListener(() {
      final query = _filterTextController.text.trim();
      if (query.isNotEmpty) {
        _fetchTravelPackages(query);
      } else {
        setState(() {
          packageList.clear();
        });
      }
    });
    fetchTags();
    fetchPopularPackages();
  }

  @override
  void dispose() {
    _filterTextController.dispose();
    super.dispose();
  }

  Future<void> _fetchTravelPackages(String query) async {
    setState(() => isLoading = true);
    try {
      final firestore = FirebaseFirestore.instance;

      final lowerQuery = query.toLowerCase();
      final nameResults =
          await firestore
              .collection('travel_packages')
              .where('name_lower', isGreaterThanOrEqualTo: lowerQuery)
              .where('name_lower', isLessThanOrEqualTo: '$lowerQuery\uf8ff')
              .get();
      final destResults =
          await firestore
              .collection('travel_packages')
              .where('destination_lower', isGreaterThanOrEqualTo: lowerQuery)
              .where(
                'destination_lower',
                isLessThanOrEqualTo: '$lowerQuery\uf8ff',
              )
              .get();
      final uniqueDocs = {
        for (var doc in [...nameResults.docs, ...destResults.docs]) doc.id: doc,
      };

      final fetchedPackages =
          uniqueDocs.values
              .map((doc) => TravelPackage.fromJson(doc.data()))
              .toList();

      if (mounted) {
        setState(() {
          packageList = fetchedPackages;
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      MessagePopup.show(
        context,
        message: "Error fetching travel packages: $e",
        type: MessageType.error,
        position: PopupPosition.top,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> fetchTags() async {
    final docSnapshot =
        await FirebaseFirestore.instance
            .collection('taxonomy')
            .doc('tags')
            .get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data() as Map<String, dynamic>?;
      tagsList = List<String>.from(data?['values'] ?? []);
    } else {
      tagsList = [];
    }

    setState(() {});
  }

  Future<void> fetchPopularPackages() async {
    final snapShot =
        await FirebaseFirestore.instance.collection('bookings').get();
    final packageCounts = <String, int>{};

    for (var doc in snapShot.docs) {
      final packageId = doc['packageId'] as String?;
      if (packageId != null) {
        packageCounts[packageId] = (packageCounts[packageId] ?? 0) + 1;
      }
    }
    final popularPackageIds = packageCounts.keys.toList();
    popularPackages = [];

    for (var pkgId in popularPackageIds) {
      final pkgDoc =
          await FirebaseFirestore.instance
              .collection('travel_packages')
              .doc(pkgId)
              .get();

      if (pkgDoc.exists) {
        popularPackages.add(
          TravelPackage.fromJson(pkgDoc.data() as Map<String, dynamic>),
        );
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> toggleWishlist(String userId, TravelPackage package) async {
    final wishlistRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .doc(package.id);

    final doc = await wishlistRef.get();

    if (doc.exists) {
      await wishlistRef.delete();
    } else {
      await wishlistRef.set({
        "packageId": package.id,
        "name": package.name,
        "imageUrl": package.imageUrl,
        "destination": package.destination,
        "price": package.price,
        "savedAt": DateTime.now(),
      });
    }

    setState(() {});
  }

  Stream<bool> isWishlisted(String userId, String packageId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .doc(packageId)
        .snapshots()
        .map((snap) => snap.exists);
  }

  Future<void> _applyFilters() async {
    setState(() => isLoading = true);
    final firestore = FirebaseFirestore.instance;
    Query q = firestore.collection('travel_packages');
    if (selectedTags.isNotEmpty) {
      q = q.where('tags', arrayContainsAny: selectedTags);
    }
    late QuerySnapshot snap;
    try {
      snap = await q.get();
    } catch (e) {
      print("Filter error: $e");
      setState(() => isLoading = false);
      return;
    }
    List<TravelPackage> results =
        snap.docs
            .map(
              (d) => TravelPackage.fromJson(d.data() as Map<String, dynamic>),
            )
            .toList();
    if (startDate != null || endDate != null) {
      // print(startDate);
      // print(endDate);
      results =
          results.where((pkg) {
            final pkgDate = pkg.travelDate;
            if (pkgDate == null) return false;
            if (startDate != null && pkgDate.isBefore(startDate!)) return false;
            if (endDate != null && pkgDate.isAfter(endDate!)) return false;
            return true;
          }).toList();
    }

    setState(() {
      packageList = results;
      isLoading = false;
    });
  }

  void _resetFilters() {
    setState(() {
      _filterTextController.clear();
      selectedTags.clear();
      startDate = null;
      endDate = null;
      packageList.clear();
      showFilter = false; // collapse filter UI
    });

    fetchPopularPackages(); // reload popular
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // color: const Color(0xFFF7F9FC),
      color: const Color(0xFFEFE9E3),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              color: Color(0xFF0064D2),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _filterTextController,
                      decoration: InputDecoration(
                        hintText: 'Search destination or package name',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF0064D2),
                          size: 22,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF0064D2),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _resetFilters,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    tooltip: "Reset filters",
                  ),
                ],
              ),
            ),
          ),
          // FILTER TOGGLE BUTTON
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() => showFilter = !showFilter);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        color: Colors.white,
                        child: Row(
                          children: [
                            Icon(Icons.filter_list, color: Colors.black87),
                            SizedBox(width: 8),
                            Text(
                              "Filters",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Spacer(),
                            Icon(
                              showFilter
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // FILTER CONTENT
                    if (showFilter)
                      Container(
                        padding: EdgeInsets.all(16),
                        color: Colors.white,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Filter by Tags",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),

                            // TAG SELECTOR
                            Wrap(
                              spacing: 8,
                              children:
                                  tagsList.map((tag) {
                                    final isSelected = selectedTags.contains(
                                      tag,
                                    );
                                    return ChoiceChip(
                                      label: Text(tag),
                                      selected: isSelected,
                                      selectedColor: Colors.blue,
                                      backgroundColor: Colors.blue.shade200,
                                      labelStyle: TextStyle(
                                        color: Colors.white,
                                      ),
                                      onSelected: (_) {
                                        setState(() {
                                          isSelected
                                              ? selectedTags.remove(tag)
                                              : selectedTags.add(tag);
                                        });
                                        _applyFilters();
                                      },
                                    );
                                  }).toList(),
                            ),

                            SizedBox(height: 20),
                            Text(
                              "Travel Date Range",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),

                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Colors.blue, // Button color
                                      foregroundColor:
                                          Colors.white, // Text/icon color
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 5, // Shadow depth
                                    ),
                                    onPressed: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime(2025),
                                        lastDate: DateTime(2035),
                                      );
                                      if (picked != null) {
                                        setState(() {
                                          startDate = picked;
                                        });
                                        _applyFilters();
                                      }
                                    },
                                    child: Text(
                                      startDate == null
                                          ? "Start Date"
                                          : DateFormat(
                                            "dd/MM/yyyy",
                                          ).format(startDate!),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Colors.blue, // Button color
                                      foregroundColor:
                                          Colors.white, // Text/icon color
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 5, // Shadow depth
                                    ),
                                    onPressed: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2035),
                                      );
                                      if (picked != null) {
                                        setState(() {
                                          endDate = picked;
                                        });
                                        _applyFilters();
                                      }
                                    },
                                    child: Text(
                                      endDate == null
                                          ? "End Date"
                                          : DateFormat(
                                            "dd/MM/yyyy",
                                          ).format(endDate!),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    _buildMainSection(),
                  ],
                ),
              ),
            ),
          ),

          // Package List
          // Expanded(
          //   child:
          //       isLoading
          //           ? const Center(
          //             child: CircularProgressIndicator(
          //               color: Color(0xFF0064D2),
          //             ),
          //           )
          //           : packageList.isEmpty
          //           ?
          //           Expanded(
          //             child: Column(
          //               children: [
          //                 buildImageSlider(),
          //                 // buildAdsPlaceholder(),
          //                 buildPopularPackages(popularPackages),
          //               ],
          //             ),
          //           )
          //           : ListView.builder(
          //             padding: EdgeInsets.fromLTRB(
          //               16,
          //               16,
          //               16,
          //               MediaQuery.of(context).padding.bottom + 16,
          //             ),
          //             itemCount: packageList.length,
          //             itemBuilder: (context, index) {
          //               final package = packageList[index];
          //               return _buildPackageCard(context, package, index);
          //             },
          //           ),
          // ),
        ],
      ),
    );
  }

  Widget _buildMainSection() {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 100),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF0064D2)),
        ),
      );
    }
    if (packageList.isEmpty) {
      return Column(
        children: [
          buildImageSlider(),
          const SizedBox(height: 24),
          buildPopularPackages(popularPackages),
        ],
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      itemCount: packageList.length,
      itemBuilder: (context, index) {
        final package = packageList[index];
        return _buildPackageCard(context, package, index);
      },
    );
  }

  Widget _buildPackageCard(
    BuildContext context,
    TravelPackage package,
    int index,
  ) {
    final userId = user?.uid; // may be null
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Header
            Stack(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    color: Colors.grey[200],
                  ),
                  child:
                      package.imageUrl.isNotEmpty
                          ? ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                            child: Image.network(
                              package.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholderImage();
                              },
                            ),
                          )
                          : _buildPlaceholderImage(),
                ),
                // Rating badge (top right)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          color: Color(0xFFFF9800),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '4.${5 + index % 5}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Package Name
                  Text(
                    package.name.isNotEmpty ? package.name : 'Package Name',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Destination
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Color(0xFF687089),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          package.destination.isNotEmpty
                              ? package.destination
                              : 'Destination',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF687089),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Tags
                  if (package.tags.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          package.tags.take(3).map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F4FD),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF0064D2),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  if (package.tags.isNotEmpty) const SizedBox(height: 12),

                  Row(
                    children: [
                      // Duration
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F9FC),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.schedule,
                              size: 14,
                              color: Color(0xFF687089),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              package.duration > 0
                                  ? '${package.duration} days'
                                  : 'Duration N/A',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF687089),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F9FC),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.date_range,
                              size: 14,
                              color: Color(0xFF687089),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              package.travelDate != null
                                  ? DateFormat("dd/MM/yyyy").format(
                                    DateTime.parse(
                                      package.travelDate.toLocal().toString(),
                                    ).toLocal(),
                                  )
                                  : '-',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF687089),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Divider
                  Divider(color: Colors.grey[200], height: 1),
                  const SizedBox(height: 16),

                  // Price and Book Button Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Price
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Start from',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF687089),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'RM ${package.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFFF5C00), // Traveloka orange
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      userId == null
                          ? Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  MessagePopup.show(
                                    context,
                                    message:
                                        "Please log in to save to wishlist",
                                    type: MessageType.warning,
                                    position: PopupPosition.top,
                                    duration: const Duration(seconds: 2),
                                  );
                                },
                                icon: const Icon(
                                  Icons.favorite_border,
                                  color: Colors.grey,
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => PackageDetailPage(
                                            package: package,
                                          ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF0064D2),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Trip Details',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              StreamBuilder<bool>(
                                stream: isWishlisted(userId, package.id),
                                builder: (context, snapshot) {
                                  final isSaved = snapshot.data ?? false;

                                  return IconButton(
                                    onPressed: () {
                                      toggleWishlist(userId, package);
                                    },
                                    icon: Icon(
                                      isSaved
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color:
                                          isSaved
                                              ? Colors.red
                                              : Color(0xFF0064D2),
                                      size: 28,
                                    ),
                                  );
                                },
                              ),

                              SizedBox(width: 8),

                              // Trip details main button
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => PackageDetailPage(
                                            package: package,
                                          ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF0064D2),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Trip Details',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0064D2).withOpacity(0.6),
            const Color(0xFF0064D2),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 60,
          color: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }
}
