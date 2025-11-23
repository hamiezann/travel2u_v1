import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:travel2u_v1/presentation/customer/chat_page.dart';

class BookingDetailPage extends StatefulWidget {
  final Map<String, dynamic> packageData;
  final Map<String, dynamic> bookingData;

  const BookingDetailPage({
    super.key,
    required this.packageData,
    required this.bookingData,
  });

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  Map<String, dynamic>? itinerary;
  bool isLoadingItinerary = true;

  @override
  void initState() {
    super.initState();
    _fetchItinerary();
  }

  Future<void> _fetchItinerary() async {
    try {
      final itineraryId = widget.bookingData['itineraryId'];

      if (itineraryId != null && itineraryId.isNotEmpty) {
        final snap =
            await FirebaseFirestore.instance
                .collection('itineraries')
                .doc(itineraryId)
                .get();

        if (snap.exists) {
          setState(() {
            itinerary = snap.data();
            isLoadingItinerary = false;
          });
        } else {
          setState(() => isLoadingItinerary = false);
        }
      } else {
        setState(() => isLoadingItinerary = false);
      }
    } catch (e) {
      setState(() => isLoadingItinerary = false);
    }
  }

  String _formatDate(dynamic v) {
    try {
      if (v is Timestamp) return DateFormat("EEEE, MMM d").format(v.toDate());
      if (v is String)
        return DateFormat("EEEE, MMM d").format(DateTime.parse(v));
      return "-";
    } catch (_) {
      return "-";
    }
  }

  @override
  Widget build(BuildContext context) {
    final package = widget.packageData;
    final booking = widget.bookingData;

    return Scaffold(
      backgroundColor: Color(0xFFF6F9FC),
      bottomNavigationBar: _buildBottomButtons(),
      body: CustomScrollView(
        slivers: [
          _buildHeader(package),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildPackageCard(package),
                  const SizedBox(height: 16),
                  _buildBookingCard(booking),
                  const SizedBox(height: 16),
                  _buildInfoCard(package, booking),
                  const SizedBox(height: 16),
                  _buildItineraryCard(),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------
  //          HEADER
  // -------------------------------
  SliverAppBar _buildHeader(Map package) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: Color(0xFF0064D2),
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: Colors.white,
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            package["imageUrl"] != null
                ? Image.network(package["imageUrl"], fit: BoxFit.cover)
                : Container(color: Colors.blue),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------
  //         PACKAGE CARD
  // -------------------------------
  Widget _buildPackageCard(Map p) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p['name'] ?? "-", style: _title),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, size: 18, color: Color(0xFF0064D2)),
              const SizedBox(width: 6),
              Expanded(child: Text(p['destination'] ?? "-", style: _sub)),
            ],
          ),
          const SizedBox(height: 12),
          if (p['tags'] != null)
            Wrap(
              spacing: 8,
              children:
                  p['tags']
                      .map<Widget>(
                        (t) => Chip(
                          label: Text(t),
                          backgroundColor: Color(0xFFE8F4FD),
                        ),
                      )
                      .toList(),
            ),
        ],
      ),
    );
  }

  // -------------------------------
  //        BOOKING CARD
  // -------------------------------
  Widget _buildBookingCard(Map booking) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Booking Details", Icons.receipt_long),
          _row("Booking ID", booking['id'] ?? "-"),
          _row("Booking Date", _formatDate(booking['createdAt'])),
          _row("Travel Date", _formatDate(booking['travelDate'])),

          const SizedBox(height: 12),
          Text("Travellers", style: _subtitle),
          const SizedBox(height: 10),

          if (booking['travelers'] != null)
            Column(
              children:
                  booking['travelers']
                      .map<Widget>((t) => _travellerTile(t))
                      .toList(),
            ),
        ],
      ),
    );
  }

  Widget _travellerTile(Map t) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(12),
      decoration: _box,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Color(0xFF0064D2),
            child: Text(
              t['name'] != null && t['name'] != ""
                  ? t['name'][0].toUpperCase()
                  : "?",
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t['name'] ?? "-", style: _travName),
              Text(t['relationship'] ?? "-", style: _sub),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------
  //      INFO / PREFERENCES CARD
  // -------------------------------
  Widget _buildInfoCard(Map p, Map booking) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Info Details", Icons.info_outline),

          if (p['flightDetail'] != null)
            _iconInfo(Icons.flight, "Flight", [
              _row("Airline", p['flightDetail']),
              _row("Class", p['flightClass'] ?? "-"),
            ]),

          if (p['hotelDetail'] != null)
            _iconInfo(Icons.hotel, "Hotel", [
              _row("Hotel", p['hotelDetail']),
              _row("Rating", p['hotelRating'] ?? "-"),
            ]),

          if (booking['preferences'] != null)
            _iconInfo(Icons.favorite, "Preferences", [
              _row(
                "Food",
                booking['preferences']['foodPreference']?.join(", ") ?? "-",
              ),
              _row(
                "Avoid",
                booking['preferences']['avoidPreference']?.join(", ") ?? "-",
              ),
              _row(
                "Activities",
                booking['preferences']['preferredActivities']?.join(", ") ??
                    "-",
              ),
            ]),
        ],
      ),
    );
  }

  Widget _buildItineraryCard() {
    if (isLoadingItinerary) {
      return _card(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: CircularProgressIndicator(color: Colors.teal),
          ),
        ),
      );
    }

    if (itinerary == null) {
      return _card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.map_outlined, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  "No itinerary generated yet",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final days = itinerary!['days'] ?? [];
    // final status = widget.bookingData['itineraryStatus'] ?? "pending";
    final status = itinerary!['status'] ?? "pending";

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Itinerary", Icons.map_outlined),

          // Status with color-coded badge
          Row(
            children: [
              Text(
                "Status: ",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          // Notes section
          if (itinerary!['generationNotes'] != null &&
              itinerary!['generationNotes'].toString().trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Notes",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          itinerary!['generationNotes'],
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Days section
          if (days.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  "${days.length} ${days.length == 1 ? 'Day' : 'Days'}",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          ...days.asMap().entries.map((entry) {
            final index = entry.key;
            final day = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildDayCard(index + 1, day),
            );
          }).toList(),

          if (days.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  "No days scheduled",
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper method to get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "generated":
        return Colors.blue;
      case "complete":
        return Colors.green;
      case "pending":
        return Colors.orange;
      case "cancelled":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDayCard(int displayDay, Map day) {
    final activities = day['activities'] ?? [];
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: _box,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Day $displayDay", style: _subtitle),
          const SizedBox(height: 10),
          if (activities.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text("No activities planned for this day.", style: _sub),
            )
          else
            ...activities.map<Widget>((a) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a['name'] ?? "-", style: _travName),
                    const SizedBox(height: 6),
                    Text("Type: ${a['type']}", style: _sub),
                    Text("Location: ${a['location']}", style: _sub),
                    Text("Time: ${a['duration']}", style: _sub),
                    if (a['foodType'] != null)
                      Text("Food: ${a['foodType'].join(', ')}", style: _sub),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  // -------------------------------
  //         BOTTOM BUTTONS
  // -------------------------------
  Widget _buildBottomButtons() {
    final booking = widget.bookingData;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _bottomBtn(Icons.chat, "Chat", () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => ChatPage(
                      // bookingId: booking['id'],
                      bookingId: widget.bookingData['id'],
                      userId: booking['userId'],
                      packageId: widget.packageData['id'],
                      // clientName: booking['mainUser']?['name'] ?? "-",
                    ),
              ),
            );
          }),
          // const SizedBox(width: 12),
          // Expanded(
          //   child: ElevatedButton.icon(
          //     icon: Icon(Icons.download),
          //     onPressed: () {
          //       // TODO: implement itinerary download
          //     },
          //     label: Text("Download Itinerary"),
          //     style: ElevatedButton.styleFrom(
          //       backgroundColor: Color(0xFF0064D2),
          //       foregroundColor: Colors.white,
          //       padding: EdgeInsets.symmetric(vertical: 14),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _bottomBtn(IconData icon, String label, VoidCallback onTap) {
    return Container(
      width: 100,
      height: 55,
      decoration: _box,
      child: InkWell(onTap: onTap, child: Icon(icon, color: Color(0xFF0064D2))),
    );
  }

  // ==========================
  //   STYLE HELPERS
  // ==========================

  final _box = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.grey.shade200),
  );

  final _title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Color(0xFF1A1A1A),
  );

  final _subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Color(0xFF1A1A1A),
  );

  final _travName = TextStyle(fontSize: 15, fontWeight: FontWeight.bold);

  final _sub = TextStyle(fontSize: 14, color: Color(0xFF6B7280));

  Widget _row(String l, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: _sub),
          Text(v, style: TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _iconInfo(IconData icon, String label, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Color(0xFFE8F4FD),
            child: Icon(icon, color: Color(0xFF0064D2)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _subtitle),
                const SizedBox(height: 6),
                ...children,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t, IconData i) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(i, color: Color(0xFF0064D2)),
          const SizedBox(width: 8),
          Text(t, style: _subtitle),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _box.copyWith(
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}
