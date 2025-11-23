import 'package:flutter/material.dart';
import 'package:travel2u_v1/core/models/travel_package.dart';

class BookingPage3 extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  final Map<String, dynamic> package;
  final VoidCallback onConfirm;

  const BookingPage3({
    super.key,
    required this.bookingData,
    required this.package,
    required this.onConfirm,
  });

  @override
  State<BookingPage3> createState() => _BookingPage3State();
}

class _BookingPage3State extends State<BookingPage3> {
  late final TravelPackage travelPackage;

  @override
  void initState() {
    super.initState();
    travelPackage = TravelPackage.fromJson(widget.package);
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    final numTravelers = widget.bookingData['numTravelers'] ?? 1;
    final totalPrice = travelPackage.price * numTravelers;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Container(
        key: ValueKey(widget.bookingData),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              "Review Your Booking",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Package Card
            _buildPackageCard(context, travelPackage, numTravelers, totalPrice),

            const SizedBox(height: 24),

            // Traveler Details Section
            _buildUserDetails(context),

            const SizedBox(height: 24),

            // Price Breakdown
            _buildPriceSummary(
              context,
              travelPackage.price,
              numTravelers,
              totalPrice,
            ),

            const SizedBox(height: 30),

            // Confirm Button
            Center(
              child: ElevatedButton.icon(
                onPressed: widget.onConfirm,
                icon: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                ),
                label: const Text(
                  'Confirm Booking',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard(
    BuildContext context,
    TravelPackage pkg,
    int numTravelers,
    double totalPrice,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Package Image
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                pkg.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder:
                    (_, __, ___) => Container(
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.image_not_supported, size: 60),
                    ),
              ),
            ),

            // Package Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pkg.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pkg.destination,
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 18,
                        color: Colors.blueGrey,
                      ),
                      const SizedBox(width: 4),
                      Text('${pkg.duration} days'),
                      const SizedBox(width: 20),
                      const Icon(
                        Icons.person,
                        size: 18,
                        color: Colors.blueGrey,
                      ),
                      const SizedBox(width: 4),
                      Text('$numTravelers traveler(s)'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'RM ${totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserDetails(BuildContext context) {
    final userData = widget.bookingData;
    debugPrint("User Data: $userData");
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Traveler Details",
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const Divider(height: 20),
          _buildInfoRow(
            Icons.person_outline,
            "Full Name",
            userData['mainUser']['name'] ?? 'Not provided',
          ),
          _buildInfoRow(
            Icons.email_outlined,
            "Email",
            userData['mainUser']['email'] ?? 'Not provided',
          ),
          _buildInfoRow(
            Icons.phone_outlined,
            "Phone",
            userData['mainUser']['phone'] ?? 'Not provided',
          ),
          _buildInfoRow(
            Icons.location_on_outlined,
            "Address",
            userData['mainUser']['address'] ?? 'Not provided',
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummary(
    BuildContext context,
    double price,
    int numTravelers,
    double totalPrice,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Price Summary",
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const Divider(height: 20),
          _buildPriceRow("Package Price", "RM ${price.toStringAsFixed(2)}"),
          _buildPriceRow("No. of Travelers", "x$numTravelers"),
          const Divider(),
          _buildPriceRow(
            "Total",
            "RM ${totalPrice.toStringAsFixed(2)}",
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String title, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isBold ? Colors.blue.shade700 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
