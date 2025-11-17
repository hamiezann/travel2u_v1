import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchItinerary();
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

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Itinerary"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveChanges),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // STATUS DROPDOWN
          const Text("Status", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),

          DropdownButtonFormField(
            value: selectedStatus,
            items:
                statusOptions
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
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
            "Generation Notes",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),

          TextFormField(
            controller: generationNotesController,
            maxLines: 3,
            decoration: _inputDecoration("Notes for customer"),
          ),

          const SizedBox(height: 20),

          // DAYS & ACTIVITIES
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // DAY TITLE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Day $dayNumber",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.teal),
                  onPressed: () => _showActivityDialog(dayIndex: dayNumber - 1),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ACTIVITIES LIST
            if (activities.isEmpty)
              const Text(
                "No activities added",
                style: TextStyle(color: Colors.grey),
              ),
            for (int i = 0; i < activities.length; i++)
              _buildActivityCard(dayNumber - 1, i, activities[i]),
          ],
        ),
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
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.teal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity["name"] ?? "",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text("Location: ${activity["location"]}"),
                Text("Duration: ${activity["duration"]}"),
                Text("Type: ${activity["type"]}"),
                if (activity["foodType"] != null &&
                    activity["foodType"].isNotEmpty)
                  Text("Food: ${activity["foodType"].join(', ')}"),
              ],
            ),
          ),

          // EDIT BUTTON
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed:
                () => _showActivityDialog(
                  dayIndex: dayIndex,
                  activityIndex: activityIndex,
                ),
          ),

          // DELETE BUTTON
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              setState(() {
                days[dayIndex]["activities"].removeAt(activityIndex);
              });
            },
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
            title: Text(isEdit ? "Edit Activity" : "Add Activity"),
            content: SizedBox(
              height: 300,
              child: Column(
                children: [
                  _textField(nameCtrl, "Activity Name"),
                  const SizedBox(height: 10),
                  _textField(durationCtrl, "Duration"),
                  const SizedBox(height: 10),
                  _textField(locationCtrl, "Location"),
                  const SizedBox(height: 10),
                  _textField(typeCtrl, "Type"),
                  const SizedBox(height: 10),
                  _textField(foodCtrl, "Food Types (comma separated)"),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: Text(isEdit ? "Save" : "Add"),
                onPressed: () {
                  final updatedActivity = {
                    "name": nameCtrl.text,
                    "duration": durationCtrl.text,
                    "location": locationCtrl.text,
                    "type": typeCtrl.text,
                    "foodType":
                        foodCtrl.text.split(",").map((e) => e.trim()).toList(),
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
          content: Text("Itinerary updated successfully"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // -------------------------
  // HELPERS
  // -------------------------
  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    filled: true,
  );

  Widget _textField(TextEditingController ctrl, String hint) {
    return TextField(controller: ctrl, decoration: _inputDecoration(hint));
  }
}
