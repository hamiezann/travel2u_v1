import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:travel2u_v1/presentation/customer/booking_review_page.dart';
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
  bool isComplete = false;
  late String supportId;
  @override
  void initState() {
    super.initState();
    _fetchItinerary();
    checkBookingStatus();
    getStaffId();
  }

  bool checkBookingStatus() {
    isComplete = widget.bookingData['status'].toString() == 'completed';
    return isComplete;
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

  Future<void> getStaffId() async {
    final packageId = widget.bookingData["packageId"];
    final snapshot =
        await FirebaseFirestore.instance
            .collection('travel_packages')
            .doc(packageId)
            .get();
    final doc = snapshot.data();
    if (doc != null) {
      supportId = doc['creatorId'] as String;
    } else {
      print("Error: Travel package document not found for ID: $packageId");
    }
  }

  String _formatDate(dynamic v) {
    try {
      if (v is Timestamp) return DateFormat("EEEE, MMM d").format(v.toDate());
      if (v is String) {
        return DateFormat("EEEE, MMM d").format(DateTime.parse(v));
      }
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

  Widget _buildBookingCard(Map booking) {
    print(booking['status']);
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Booking Details", Icons.receipt_long),
          _row("Booking ID", booking['id'] ?? "-"),
          _row("Booking Status", booking['status'].toString().toUpperCase()),
          _row("Booking Date", _formatDate(booking['createdAt'])),
          _row("Travel Date", _formatDate(booking['travelDate'])),

          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Leader", style: _subtitle),
              isComplete
                  ? SizedBox()
                  : IconButton(
                    icon: Icon(Icons.edit, size: 18, color: Colors.blue),
                    onPressed: () => _openEditLeaderModal(booking['mainUser']),
                  ),
            ],
          ),
          const SizedBox(height: 12),
          _travellerTile(booking['mainUser']),
          if (booking['travelers'] != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Trip Participants", style: _subtitle),
                isComplete
                    ? SizedBox()
                    : IconButton(
                      icon: Icon(Icons.edit, size: 18, color: Colors.blue),
                      onPressed:
                          () =>
                              _openEditParticipantsModal(booking['travelers']),
                    ),
              ],
            ),
          const SizedBox(height: 12),
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

  void _openEditLeaderModal(Map leader) {
    final nameCtrl = TextEditingController(text: leader['name']);
    final icCtrl = TextEditingController(text: leader['icNo']);
    final passportCtrl = TextEditingController(text: leader['passportNo']);
    final emailCtrl = TextEditingController(text: leader['email']);
    final phoneCtrl = TextEditingController(text: leader['phone']);
    final addressCtrl = TextEditingController(text: leader['address']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Edit Leader Details", style: _subtitle),
                  const SizedBox(height: 16),
                  _input("Name", nameCtrl),
                  _input("IC Number", icCtrl),
                  _input("Passport No", passportCtrl),
                  _input("Email", emailCtrl),
                  _input("Phone", phoneCtrl),
                  _input("Address", addressCtrl),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection("bookings")
                          .doc(widget.bookingData['id'])
                          .update({
                            "mainUser": {
                              "name": nameCtrl.text,
                              "icNo": icCtrl.text,
                              "passportNo": passportCtrl.text,
                              "email": emailCtrl.text,
                              "phone": phoneCtrl.text,
                              "address": addressCtrl.text,
                            },
                          });

                      setState(() {
                        widget.bookingData['mainUser'] = {
                          "name": nameCtrl.text,
                          "icNo": icCtrl.text,
                          "passportNo": passportCtrl.text,
                          "email": emailCtrl.text,
                          "phone": phoneCtrl.text,
                          "address": addressCtrl.text,
                        };
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Successfully update details'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                      Navigator.pop(context);
                    },
                    child: Text("Save", style: TextStyle(color: Colors.white)),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
    );
  }

  Widget _input(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    );
  }

  void _openEditParticipantsModal(List participants) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    left: 16,
                    right: 16,
                    top: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Edit Participants", style: _subtitle),
                      const SizedBox(height: 20),

                      ...participants.asMap().entries.map((entry) {
                        final i = entry.key;
                        final p = entry.value;

                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(p['name'], style: _travName),
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit, size: 18),
                                  onPressed: () {
                                    _openSingleParticipantModal(
                                      i,
                                      participants,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        );
                      }),

                      SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  void _openSingleParticipantModal(int index, List participants) {
    final p = participants[index];

    final nameCtrl = TextEditingController(text: p['name']);
    final relCtrl = TextEditingController(text: p['relationship']);
    final icCtrl = TextEditingController(text: p['icNumber']);
    final passCtrl = TextEditingController(text: p['passportNo']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Edit Participant", style: _subtitle),
                const SizedBox(height: 16),

                _input("Name", nameCtrl),
                _input("Relationship", relCtrl),
                _input("IC Number", icCtrl),
                _input("Passport Number", passCtrl),

                SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: () async {
                    participants[index] = {
                      "name": nameCtrl.text,
                      "relationship": relCtrl.text,
                      "icNumber": icCtrl.text,
                      "passportNo": passCtrl.text,
                    };

                    await FirebaseFirestore.instance
                        .collection("bookings")
                        .doc(widget.bookingData['id'])
                        .update({"travelers": participants});

                    setState(() {
                      widget.bookingData['travelers'] = participants;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Successfully update details'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  child: Text("Save", style: TextStyle(color: Colors.white)),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Widget _rowWrap(String l, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$l: ", style: _sub),
          Expanded(
            child: Text(
              v,
              style: TextStyle(fontWeight: FontWeight.w600),
              softWrap: true,
            ),
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
            children:
                ((t.containsKey('phone')))
                    ? ([
                      Text(t['name'] ?? "-", style: _travName),
                      Text(t['icNo'] ?? "-", style: _sub),
                      Text(t['passportNo'] ?? "-", style: _sub),
                      Text(t['email'] ?? "-", style: _sub),
                      Text(t['phone'] ?? "-", style: _sub),
                      Text(t['address'] ?? "-", style: _sub),
                    ])
                    : ([
                      Text(t['name'] ?? "-", style: _travName),
                      Text(t['relationship'] ?? "-", style: _sub),
                      Text(t['icNumber'] ?? "-", style: _sub),
                      Text(t['passportNo'] ?? "-", style: _sub),
                    ]),
          ),
        ],
      ),
    );
  }

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
              _rowWrap(
                "Food",
                booking['preferences']['foodPreference']?.join(", ") ?? "-",
              ),
              _rowWrap(
                "Avoid",
                booking['preferences']['avoidPreference']?.join(", ") ?? "-",
              ),
              _rowWrap(
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

  Widget _buildBottomButtons() {
    final booking = widget.bookingData;
    final bookingId = booking['id'];

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('chats')
                    .doc(bookingId)
                    .collection('messages')
                    // .where('sender', isEqualTo: 'staff')
                    .where('sender', isNotEqualTo: 'customer')
                    .where('isRead', isEqualTo: false)
                    .snapshots(),
            builder: (context, snapshot) {
              int unreadCount = 0;
              if (snapshot.hasData) {
                unreadCount = snapshot.data!.docs.length;
              }

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  _bottomBtn(Icons.chat, "Chat", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => ChatPage(
                              bookingId: bookingId,
                              userId: booking['userId'],
                              packageId: widget.packageData['id'],
                              supportId: supportId,
                            ),
                      ),
                    );
                  }),

                  if (unreadCount > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          const SizedBox(width: 14),

          // REVIEW BUTTON (IF COMPLETE)
          isComplete
              ? _bottomBtn(Icons.reviews_outlined, "Review", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => ReviewPage(
                          bookingId: booking['id'],
                          packageId: widget.packageData['id'],
                          mode: 'add',
                        ),
                  ),
                );
              })
              : SizedBox(),
        ],
      ),
    );
  }

  Widget _bottomBtn(IconData icon, String label, VoidCallback onTap) {
    return SizedBox(
      height: 55,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 22),
        label: Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF0064D2),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24),
        ),
      ),
    );
  }

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
