import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:multi_select_flutter/chip_display/multi_select_chip_display.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';

class EditItineraryPage extends StatefulWidget {
  final String itineraryId;

  const EditItineraryPage({super.key, required this.itineraryId});

  @override
  State<EditItineraryPage> createState() => _EditItineraryPageState();
}

class _EditItineraryPageState extends State<EditItineraryPage> {
  bool loading = true;
  Map<String, dynamic> itinerary = {};
  List days = [];
  final TextEditingController generationNotesController =
      TextEditingController();
  final List<String> statusOptions = ["pending", "complete", "cancelled"];
  String selectedStatus = "pending";
  List<String> _foodTypesList = [];
  List<String> _activityTypesList = [];
  List<String> _selectedFoodTypes = [];
  String? _selectedActivityType;

  @override
  void initState() {
    super.initState();
    _fetchItinerary();
    _fetchActivityTypes();
    _fetchFoodTypes();
  }

  Future<void> _fetchItinerary() async {
    final doc =
        await FirebaseFirestore.instance
            .collection("itineraries")
            .doc(widget.itineraryId)
            .get();

    itinerary = doc.data() ?? {};
    days = itinerary["days"] ?? [];
    generationNotesController.text = itinerary["generationNotes"] ?? "";
    selectedStatus = itinerary["status"] ?? "pending";

    setState(() => loading = false);
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

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Edit Itinerary"),
        backgroundColor: Colors.teal,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveChanges,
            tooltip: "Save Changes",
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // STATUS & NOTES CARD
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.teal, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        "Itinerary Details",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // STATUS DROPDOWN
                  const Text(
                    "Status",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField(
                    value: selectedStatus,
                    items:
                        statusOptions
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.toUpperCase()),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      selectedStatus = value!;
                      setState(() {});
                    },
                    decoration: _inputDecoration("Select status"),
                  ),
                  const SizedBox(height: 16),

                  // GENERATION NOTES
                  const Text(
                    "Notes for Customer",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: generationNotesController,
                    maxLines: 3,
                    decoration: _inputDecoration("Add notes or instructions"),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // DAYS HEADER
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.teal, size: 20),
              const SizedBox(width: 8),
              const Text(
                "Daily Activities",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // DAYS & ACTIVITIES
          if (days.isEmpty)
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        "No days scheduled",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            for (int i = 0; i < days.length; i++)
              _buildDaySection(i + 1, days[i]),
        ],
      ),
    );
  }

  // -------------------------
  // DAY SECTION
  // -------------------------
  Widget _buildDaySection(int dayNumber, Map<String, dynamic> dayData) {
    List activities = dayData["activities"] ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // DAY HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Day $dayNumber",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  "${activities.length} ${activities.length == 1 ? 'activity' : 'activities'}",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.teal),
                  onPressed: () => _showActivityDialog(dayIndex: dayNumber - 1),
                  tooltip: "Add Activity",
                ),
              ],
            ),
          ),

          // ACTIVITIES LIST
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (activities.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      "No activities added yet",
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  )
                else
                  for (int i = 0; i < activities.length; i++)
                    _buildActivityCard(dayNumber - 1, i, activities[i]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------
  // ACTIVITY CARD
  // -------------------------
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

  // -------------------------
  // CONFIRM DELETE
  // -------------------------
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
                onPressed: () {
                  setState(() {
                    days[dayIndex]["activities"].removeAt(activityIndex);
                  });
                  Navigator.pop(context);
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

  // -------------------------
  // ADD / EDIT ACTIVITY DIALOG
  // -------------------------
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
    final foodCtrl = TextEditingController(
      text: activity["foodType"]?.join(", ") ?? "",
    );
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(isEdit ? "Edit Activity" : "Add Activity"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _textField(nameCtrl, "Activity Name", Icons.event),
                  const SizedBox(height: 12),
                  _textField(
                    durationCtrl,
                    "Duration (e.g., 2 hours)",
                    Icons.access_time,
                  ),
                  const SizedBox(height: 12),
                  _textField(locationCtrl, "Location", Icons.place),
                  const SizedBox(height: 12),
                  // _textField(
                  //   typeCtrl,
                  //   "Type (e.g., Sightseeing)",
                  //   Icons.category,
                  // ),
                  // const SizedBox(height: 12),
                  // _textField(
                  //   foodCtrl,
                  //   "Food Types (comma separated)",
                  //   Icons.restaurant,
                  // ),
                  // Activity Type (single select)
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

                  const SizedBox(height: 12),

                  // Food Types (multi-select)
                  MultiSelectDialogField<String>(
                    items:
                        _foodTypesList
                            .map((food) => MultiSelectItem(food, food))
                            .toList(),
                    initialValue: List<String>.from(activity["foodType"] ?? []),
                    title: const Text("Food Types"),
                    buttonText: const Text("Select Food Types"),
                    searchable: true,
                    onConfirm: (values) {
                      _selectedFoodTypes = values;
                    },
                    chipDisplay: MultiSelectChipDisplay(
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
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                child: Text(isEdit ? "Save" : "Add"),
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Activity name is required"),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final updatedActivity = {
                    "name": nameCtrl.text,
                    "duration": durationCtrl.text,
                    "location": locationCtrl.text,
                    // "type": typeCtrl.text,
                    // "foodType":
                    //     foodCtrl.text.split(",").map((e) => e.trim()).toList(),
                    "type": _selectedActivityType ?? typeCtrl.text,
                    "foodType": _selectedFoodTypes,
                    "day": dayIndex + 1,
                    "id":
                        activity["id"] ??
                        DateTime.now().millisecondsSinceEpoch.toString(),
                  };

                  setState(() {
                    if (isEdit) {
                      days[dayIndex]["activities"][activityIndex!] =
                          updatedActivity;
                    } else {
                      days[dayIndex]["activities"].add(updatedActivity);
                    }
                  });

                  Navigator.pop(context);
                },
              ),
            ],
          ),
    );
  }

  // -------------------------
  // SAVE CHANGES TO FIRESTORE
  // -------------------------
  Future<void> _saveChanges() async {
    try {
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Itinerary saved successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving: $e"),
            backgroundColor: Colors.red,
          ),
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
