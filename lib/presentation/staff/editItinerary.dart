import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:multi_select_flutter/chip_display/multi_select_chip_display.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:travel2u_v1/core/models/activity.dart';
import 'package:travel2u_v1/core/models/travel_package.dart';
import 'package:travel2u_v1/core/services/notification_service.dart';
import 'package:travel2u_v1/presentation/widgets/custom_message_popup.dart';

class EditItineraryPage extends StatefulWidget {
  final String itineraryId;
  final String bookingId;
  final String packageId;

  const EditItineraryPage({
    super.key,
    required this.itineraryId,
    required this.bookingId,
    required this.packageId,
  });

  @override
  State<EditItineraryPage> createState() => _EditItineraryPageState();
}

class _EditItineraryPageState extends State<EditItineraryPage> {
  bool loading = true;
  Map<String, dynamic> itinerary = {};
  List<List<Activity>> activityList = [];
  List days = [];
  final TextEditingController generationNotesController =
      TextEditingController();
  final List<String> statusOptions = ["pending", "complete", "cancelled"];
  String selectedStatus = "pending";
  List<String> _foodTypesList = [];
  List<String> _activityTypesList = [];
  List<String> _selectedFoodTypes = [];
  String? _selectedActivityType;
  Map<String, Set<int>> selectedActivitiesByDay = {};

  @override
  void initState() {
    super.initState();
    _fetchItinerary();
    _fetchActivityTypes();
    _fetchFoodTypes();
    _fetchActivities();
  }

  void _initSelectedActivitiesFromItinerary() {
    selectedActivitiesByDay.clear();

    for (int dayIndex = 0; dayIndex < days.length; dayIndex++) {
      final activities = days[dayIndex]["activities"] ?? [];

      for (final act in activities) {
        final id = act["id"];
        if (id != null) {
          selectedActivitiesByDay.putIfAbsent(id, () => <int>{}).add(dayIndex);
        }
      }
    }
  }

  Future<void> _fetchItinerary() async {
    final doc =
        await FirebaseFirestore.instance
            .collection("itineraries")
            .doc(widget.itineraryId)
            .get();

    itinerary = doc.data() ?? {};
    days = itinerary["days"] ?? [];
    _initSelectedActivitiesFromItinerary();
    generationNotesController.text = itinerary["generationNotes"] ?? "";
    selectedStatus = itinerary["status"] ?? "pending";

    setState(() => loading = false);
  }

  Future<void> _fetchActivities() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('travel_packages')
              .where('id', isEqualTo: widget.packageId)
              .get();
      if (querySnapshot.docs.isNotEmpty) {
        final packageData = TravelPackage.fromJson(
          querySnapshot.docs.first.data(),
        );
        setState(() {
          activityList = packageData.activitiesByDay;
        });
        // print("fetched activites: $activityList");
      }
    } catch (e) {
      debugPrint("Error fetching activities: $e");
    }
  }

  Future<void> _fetchFoodTypes() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('taxonomy')
              .doc('foodTypes')
              .get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['values'] != null) {
          setState(() {
            _foodTypesList = List<String>.from(data['values']);
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching tags: $e');
      setState(() {});
    }
  }

  Future<void> _fetchActivityTypes() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('taxonomy')
              .doc('activityTypes')
              .get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['values'] != null) {
          setState(() {
            _activityTypesList = List<String>.from(data['values']);
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching tags: $e');
      setState(() {});
    }
  }

  bool isActivitySelected(String activityId) {
    return selectedActivitiesByDay.containsKey(activityId) &&
        selectedActivitiesByDay[activityId]!.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text(
            "Edit Itinerary",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          backgroundColor: Colors.blue.shade700,
          elevation: 0,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.save_rounded),
                onPressed: _saveChanges,
                tooltip: "Save Changes",
                color: Colors.white,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // STATUS & NOTES CARD
              Card(
                elevation: 3,
                shadowColor: Colors.black.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Colors.blue.shade50.withOpacity(0.3),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.info_outline_rounded,
                              color: Colors.blue.shade700,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Itinerary Details",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // STATUS DROPDOWN
                      const Text(
                        "Status",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF424242),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField(
                        value: selectedStatus,
                        items:
                            statusOptions
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(
                                      s.toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          selectedStatus = value!;
                          setState(() {});
                        },
                        decoration: _inputDecoration("Select status"),
                      ),
                      const SizedBox(height: 20),

                      // GENERATION NOTES
                      const Text(
                        "Notes for Customer",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF424242),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: generationNotesController,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 14),
                        decoration: _inputDecoration(
                          "Add notes or instructions",
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // TABS
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: TabBar(
                    indicatorColor: Colors.blue.shade600,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.blue.shade700,
                    unselectedLabelColor: Colors.grey.shade600,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    tabs: [
                      Tab(
                        icon: Icon(Icons.event_available_rounded, size: 22),
                        text: "Available Activities",
                        height: 65,
                      ),
                      Tab(
                        icon: Icon(Icons.calendar_today_rounded, size: 22),
                        text: "Itinerary",
                        height: 65,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: TabBarView(
                  physics: const BouncingScrollPhysics(),
                  children: [_availableActivitiesTab(), _itineraryTab()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addActivityToDay(Activity activity, int dayIndex) {
    setState(() {
      selectedActivitiesByDay
          .putIfAbsent(activity.id, () => <int>{})
          .add(dayIndex);

      days[dayIndex]["activities"].add({
        "id": activity.id,
        "name": activity.name,
        "duration": activity.duration,
        "location": activity.location,
        "type": activity.type,
        "foodType": activity.foodType,
        "day": dayIndex + 1,
        "source": "package", // important
      });
    });
  }

  void _removeActivityFromDay(int dayIndex, int activityIndex) {
    final activityId = days[dayIndex]["activities"][activityIndex]["id"];

    setState(() {
      days[dayIndex]["activities"].removeAt(activityIndex);

      selectedActivitiesByDay[activityId]?.remove(dayIndex);

      if (selectedActivitiesByDay[activityId]?.isEmpty ?? false) {
        selectedActivitiesByDay.remove(activityId);
      }
    });
  }

  Widget _availableActivitiesTab() {
    if (activityList.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [_emptyCard("No available activities")],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activityList.length,
      itemBuilder: (context, i) => _buildAvailableActivitiesDay(i),
    );
  }

  Widget _itineraryTab() {
    if (days.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [_emptyCard("No days scheduled")],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: days.length,
      itemBuilder: (context, i) => _buildItineraryDay(i + 1, days[i]),
    );
  }

  Widget _emptyCard(String text) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(text, style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableActivitiesDay(int dayIndex) {
    final activities = activityList[dayIndex];

    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.pink.withOpacity(0.15),
            child: Text(
              "${dayIndex + 1}",
              style: const TextStyle(
                color: Colors.pink,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            "Day ${dayIndex + 1}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            "${activities.length} activities",
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          children: [
            activities.isEmpty
                ? _emptyText("No available activities")
                : Column(
                  children: List.generate(
                    activities.length,
                    (i) => _buildActivityListCard(
                      activities[i],
                      i == activities.length - 1,
                      dayIndex,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildItineraryDay(int dayNumber, Map<String, dynamic> dayData) {
    final List itineraryActivities = dayData["activities"] ?? [];
    final int dayIndex = dayNumber - 1;

    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Theme(
        // remove default ExpansionTile divider
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          initiallyExpanded: false,
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.teal.withOpacity(0.15),
            child: Text(
              "$dayNumber",
              style: const TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            "Day $dayNumber",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Text(
            "${itineraryActivities.length} activities",
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.teal),
                tooltip: "Add activity",
                onPressed: () => _showActivityDialog(dayIndex: dayIndex),
              ),
              const Icon(Icons.expand_more),
            ],
          ),
          children: [
            if (itineraryActivities.isEmpty)
              _emptyText("No activities added yet")
            else
              Column(
                children: List.generate(
                  itineraryActivities.length,
                  (i) =>
                      _buildActivityCard(dayIndex, i, itineraryActivities[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptyText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(text, style: TextStyle(color: Colors.grey[500])),
    );
  }

  Widget _buildActivityListCard(Activity activity, bool isLast, int dayIndex) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.pink,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.pink.withOpacity(0.2),
                    width: 4,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.pink.withOpacity(0.3),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(
              isActivitySelected(activity.id)
                  ? Icons.check_circle
                  : Icons.add_circle_outline,
              color:
                  isActivitySelected(activity.id) ? Colors.green : Colors.blue,
            ),
            onPressed: () {
              _addActivityToDay(activity, dayIndex);
              _showSnack("Activity added to Day ${dayIndex + 1}");
            },
          ),

          const SizedBox(width: 16),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // const SizedBox(height: 4),
                  const SizedBox(height: 8),
                  Text(
                    activity.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        activity.duration,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              isActivitySelected(activity.id)
                                  ? Colors.green
                                  : Colors.pink,
                          fontSize: 12,
                        ),
                      ),
                      if (isActivitySelected(activity.id))
                        Chip(
                          label: const Text("Added"),
                          backgroundColor: Colors.green.shade50,
                          labelStyle: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else
                        _buildTypeTag(activity.type),
                    ],
                  ),

                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          activity.location,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (activity.foodType.isNotEmpty) ...[
                    const Divider(height: 20),
                    Wrap(
                      spacing: 8,
                      children:
                          activity.foodType
                              .map(
                                (food) => Text(
                                  "#$food",
                                  style: TextStyle(
                                    color: Colors.orange[700],
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeTag(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.blue[800],
        ),
      ),
    );
  }

  Widget _buildActivityCard(
    int dayIndex,
    int activityIndex,
    Map<String, dynamic> activity,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // Activity Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: Colors.teal, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    activity["name"] ?? "Untitled Activity",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Activity Details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildActivityInfo(
                  Icons.place_outlined,
                  "Location",
                  activity["location"],
                ),
                const SizedBox(height: 8),
                _buildActivityInfo(
                  Icons.access_time,
                  "Duration",
                  activity["duration"],
                ),
                const SizedBox(height: 8),
                _buildActivityInfo(
                  Icons.category_outlined,
                  "Type",
                  activity["type"],
                ),
                if (activity["foodType"] != null &&
                    activity["foodType"].isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildActivityInfo(
                    Icons.restaurant_outlined,
                    "Food",
                    activity["foodType"].join(', '),
                  ),
                ],
                const SizedBox(height: 12),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text("Edit"),
                        onPressed:
                            () => _showActivityDialog(
                              dayIndex: dayIndex,
                              activityIndex: activityIndex,
                            ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text("Delete"),
                        onPressed:
                            () => _confirmDelete(dayIndex, activityIndex),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
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
  }

  Widget _buildActivityInfo(IconData icon, String label, String? value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(value ?? "-", style: const TextStyle(fontSize: 14)),
        ),
      ],
    );
  }

  void _confirmDelete(int dayIndex, int activityIndex) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text("Delete Activity?"),
            content: const Text(
              "This activity will be removed from the itinerary.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                // onPressed: () {
                //   setState(() {
                //     days[dayIndex]["activities"].removeAt(activityIndex);
                //   });
                //   Navigator.pop(context);
                // },
                onPressed: () {
                  final activityId =
                      days[dayIndex]["activities"][activityIndex]["id"];

                  setState(() {
                    days[dayIndex]["activities"].removeAt(activityIndex);
                    selectedActivitiesByDay[activityId]?.remove(dayIndex);

                    if (selectedActivitiesByDay[activityId]?.isEmpty ?? false) {
                      selectedActivitiesByDay.remove(activityId);
                    }
                  });

                  Navigator.pop(context);
                  _showSnack("Activity removed");
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Delete"),
              ),
            ],
          ),
    );
  }

  void _showActivityDialog({required int dayIndex, int? activityIndex}) {
    final isEdit = activityIndex != null;
    final Map<String, dynamic> activity =
        isEdit
            ? days[dayIndex]["activities"][activityIndex]
            : {
              "name": "",
              "duration": "",
              "location": "",
              "type": "",
              "foodType": [],
              "id": "",
            };

    _selectedActivityType = isEdit ? activity["type"] : null;
    _selectedFoodTypes =
        isEdit ? List<String>.from(activity["foodType"] ?? []) : [];

    final nameCtrl = TextEditingController(text: activity["name"]);
    final durationCtrl = TextEditingController(text: activity["duration"]);
    final locationCtrl = TextEditingController(text: activity["location"]);
    final typeCtrl = TextEditingController(text: activity["type"]);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isEdit ? Icons.edit_rounded : Icons.add_rounded,
                    color: Colors.teal.shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isEdit ? "Edit Activity" : "Add Activity",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Activity Name
                  _textField(nameCtrl, "Activity Name", Icons.event_rounded),
                  const SizedBox(height: 16),

                  // Duration
                  _textField(
                    durationCtrl,
                    "Duration (e.g., 2 hours)",
                    Icons.access_time_rounded,
                  ),
                  const SizedBox(height: 16),

                  // Location
                  _textField(locationCtrl, "Location", Icons.place_rounded),
                  const SizedBox(height: 16),

                  // Activity Type Dropdown
                  const Text(
                    "Activity Type",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF424242),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value:
                        (_selectedActivityType != null &&
                                _activityTypesList.contains(
                                  _selectedActivityType,
                                ))
                            ? _selectedActivityType
                            : null,
                    items:
                        _activityTypesList.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedActivityType = value;
                      });
                    },
                    decoration: _inputDecoration("Select activity type"),
                  ),
                  const SizedBox(height: 16),

                  // Food Types Multi-Select
                  const Text(
                    "Food Types",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF424242),
                    ),
                  ),
                  const SizedBox(height: 8),
                  MultiSelectDialogField<String>(
                    items:
                        _foodTypesList
                            .map((food) => MultiSelectItem(food, food))
                            .toList(),
                    initialValue: List<String>.from(activity["foodType"] ?? []),
                    title: const Text("Select Food Types"),
                    buttonText: const Text(
                      "Choose Food Types",
                      style: TextStyle(fontSize: 14),
                    ),
                    searchable: true,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    buttonIcon: Icon(
                      Icons.restaurant_rounded,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    onConfirm: (values) {
                      _selectedFoodTypes = values;
                    },
                    chipDisplay: MultiSelectChipDisplay(
                      chipColor: Colors.teal.shade50,
                      textStyle: TextStyle(
                        color: Colors.teal.shade700,
                        fontSize: 13,
                      ),
                      onTap: (value) {
                        setState(() {
                          _selectedFoodTypes.remove(value);
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  "Cancel",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty) {
                    MessagePopup.show(
                      context,
                      message: "Activity name is required",
                      type: MessageType.error,
                      position: PopupPosition.top,
                      duration: const Duration(seconds: 2),
                    );
                    return;
                  }

                  final id =
                      activity["id"] ??
                      DateTime.now().millisecondsSinceEpoch.toString();

                  final updatedActivity = {
                    "name": nameCtrl.text.trim(),
                    "duration": durationCtrl.text.trim(),
                    "location": locationCtrl.text.trim(),
                    "type": _selectedActivityType ?? typeCtrl.text.trim(),
                    "foodType": _selectedFoodTypes,
                    "day": dayIndex + 1,
                    "id": id,
                  };

                  setState(() {
                    if (isEdit) {
                      days[dayIndex]["activities"][activityIndex] =
                          updatedActivity;
                    } else {
                      days[dayIndex]["activities"].add(updatedActivity);
                    }
                    selectedActivitiesByDay
                        .putIfAbsent(id, () => <int>{})
                        .add(dayIndex);
                  });

                  _showSnack(isEdit ? "Activity updated" : "Activity added");
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  isEdit ? "Save Changes" : "Add Activity",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
  }
  // void _showActivityDialog({required int dayIndex, int? activityIndex}) {
  //   final isEdit = activityIndex != null;
  //   final Map<String, dynamic> activity =
  //       isEdit
  //           ? days[dayIndex]["activities"][activityIndex]
  //           : {
  //             "name": "",
  //             "duration": "",
  //             "location": "",
  //             "type": "",
  //             "foodType": [],
  //             "id": "",
  //           };
  //   _selectedActivityType = isEdit ? activity["type"] : null;
  //   _selectedFoodTypes =
  //       isEdit ? List<String>.from(activity["foodType"] ?? []) : [];
  //   final nameCtrl = TextEditingController(text: activity["name"]);
  //   final durationCtrl = TextEditingController(text: activity["duration"]);
  //   final locationCtrl = TextEditingController(text: activity["location"]);
  //   final typeCtrl = TextEditingController(text: activity["type"]);
  //   // final foodCtrl = TextEditingController(
  //   //   text: activity["foodType"]?.join(", ") ?? "",
  //   // );
  //   showDialog(
  //     context: context,
  //     builder:
  //         (context) => AlertDialog(
  //           backgroundColor: Colors.white,
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(12),
  //           ),
  //           title: Text(isEdit ? "Edit Activity" : "Add Activity"),
  //           content: SingleChildScrollView(
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 _textField(nameCtrl, "Activity Name", Icons.event),
  //                 const SizedBox(height: 12),
  //                 _textField(
  //                   durationCtrl,
  //                   "Duration (e.g., 2 hours)",
  //                   Icons.access_time,
  //                 ),
  //                 const SizedBox(height: 12),
  //                 _textField(locationCtrl, "Location", Icons.place),
  //                 const SizedBox(height: 12),
  //                 // _textField(
  //                 //   typeCtrl,
  //                 //   "Type (e.g., Sightseeing)",
  //                 //   Icons.category,
  //                 // ),
  //                 // const SizedBox(height: 12),
  //                 // _textField(
  //                 //   foodCtrl,
  //                 //   "Food Types (comma separated)",
  //                 //   Icons.restaurant,
  //                 // ),
  //                 // Activity Type (single select)
  //                 DropdownButtonFormField<String>(
  //                   value:
  //                       (_selectedActivityType != null &&
  //                               _activityTypesList.contains(
  //                                 _selectedActivityType,
  //                               ))
  //                           ? _selectedActivityType
  //                           : null,
  //                   items:
  //                       _activityTypesList.map((type) {
  //                         return DropdownMenuItem(
  //                           value: type,
  //                           child: Text(type),
  //                         );
  //                       }).toList(),
  //                   onChanged: (value) {
  //                     setState(() {
  //                       _selectedActivityType = value;
  //                     });
  //                   },
  //                   decoration: _inputDecoration("Select activity type"),
  //                 ),

  //                 const SizedBox(height: 12),

  //                 // Food Types (multi-select)
  //                 MultiSelectDialogField<String>(
  //                   items:
  //                       _foodTypesList
  //                           .map((food) => MultiSelectItem(food, food))
  //                           .toList(),
  //                   initialValue: List<String>.from(activity["foodType"] ?? []),
  //                   title: const Text("Food Types"),
  //                   buttonText: const Text("Select Food Types"),
  //                   searchable: true,
  //                   onConfirm: (values) {
  //                     _selectedFoodTypes = values;
  //                   },
  //                   chipDisplay: MultiSelectChipDisplay(
  //                     onTap: (value) {
  //                       setState(() {
  //                         _selectedFoodTypes.remove(value);
  //                       });
  //                     },
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //           actions: [
  //             TextButton(
  //               child: const Text("Cancel"),
  //               onPressed: () => Navigator.pop(context),
  //             ),
  //             ElevatedButton(
  //               style: ElevatedButton.styleFrom(
  //                 backgroundColor: Colors.teal,
  //                 foregroundColor: Colors.white,
  //               ),
  //               child: Text(isEdit ? "Save" : "Add"),
  //               onPressed: () {
  //                 if (nameCtrl.text.trim().isEmpty) {
  //                   MessagePopup.show(
  //                     context,
  //                     message: "Activity name is required",
  //                     type: MessageType.error,
  //                     position: PopupPosition.top,
  //                     duration: const Duration(seconds: 2),
  //                   );
  //                   return;
  //                 }

  //                 final updatedActivity = {
  //                   "name": nameCtrl.text,
  //                   "duration": durationCtrl.text,
  //                   "location": locationCtrl.text,
  //                   // "type": typeCtrl.text,
  //                   // "foodType":
  //                   //     foodCtrl.text.split(",").map((e) => e.trim()).toList(),
  //                   "type": _selectedActivityType ?? typeCtrl.text,
  //                   "foodType": _selectedFoodTypes,
  //                   "day": dayIndex + 1,
  //                   "id":
  //                       activity["id"] ??
  //                       DateTime.now().millisecondsSinceEpoch.toString(),
  //                 };
  //                 final id =
  //                     activity["id"] ??
  //                     DateTime.now().millisecondsSinceEpoch.toString();

  //                 updatedActivity["id"] = id;
  //                 setState(() {
  //                   if (isEdit) {
  //                     days[dayIndex]["activities"][activityIndex] =
  //                         updatedActivity;
  //                   } else {
  //                     days[dayIndex]["activities"].add(updatedActivity);
  //                   }
  //                   selectedActivitiesByDay
  //                       .putIfAbsent(id, () => <int>{})
  //                       .add(dayIndex);
  //                 });
  //                 _showSnack(isEdit ? "Activity updated" : "Activity added");
  //                 Navigator.pop(context);
  //               },
  //             ),
  //           ],
  //         ),
  //   );
  // }

  void _showSnack(String message) {
    if (!mounted) return;

    MessagePopup.show(
      context,
      message: message,
      type: MessageType.info,
      position: PopupPosition.top,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _saveChanges() async {
    try {
      // 1. Get latest version from Firestore (ensures correctness)
      final doc =
          await FirebaseFirestore.instance
              .collection("itineraries")
              .doc(widget.itineraryId)
              .get();

      final oldData = doc.data() ?? {};

      // 2. Prepare update message
      List<String> updates = [];

      if (selectedStatus != oldData['status']) {
        updates.add("Itinerary status was updated to $selectedStatus");
      }

      if (days != oldData['days']) {
        updates.add("Itinerary activity was updated");
      }

      String message = updates.join("\n");

      // 3. Update Firestore
      await FirebaseFirestore.instance
          .collection("itineraries")
          .doc(widget.itineraryId)
          .update({
            "days": days,
            "generationNotes": generationNotesController.text,
            "status": selectedStatus,
            "lastEditedBy": "staff",
            "editedAt": FieldValue.serverTimestamp(),
          });

      // 4. Send notification only if there is an update
      if (message.isNotEmpty) {
        await NotificationService().sendNotification(
          title: "Itinerary Updates",
          body: message,
          userId: oldData['userId'],
          data: {
            "packageId": oldData['packageId'],
            "bookingId": widget.bookingId,
            "type": "itinerary-update",
          },
        );
      }

      if (mounted) {
        MessagePopup.show(
          context,
          message: "Itinerary saved succesfully",
          type: MessageType.success,
          position: PopupPosition.top,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (mounted) {
        MessagePopup.show(
          context,
          message: "Error saving: $e",
          type: MessageType.error,
          position: PopupPosition.top,
          duration: const Duration(seconds: 4),
        );
      }
    }
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    filled: true,
    fillColor: Colors.grey[50],
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );

  Widget _textField(TextEditingController ctrl, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      decoration: _inputDecoration(
        hint,
      ).copyWith(prefixIcon: Icon(icon, color: Colors.grey[600], size: 20)),
    );
  }
}
