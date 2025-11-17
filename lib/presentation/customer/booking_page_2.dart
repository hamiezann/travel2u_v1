import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingPage2 extends StatefulWidget {
  final int numTravelers;
  final Function(Map<String, dynamic>) onDataSaved;
  final Map<String, dynamic> initialData;

  const BookingPage2({
    super.key,
    required this.numTravelers,
    required this.onDataSaved,
    required this.initialData,
  });

  @override
  State<BookingPage2> createState() => BookingPage2State();
}

class BookingPage2State extends State<BookingPage2> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;

  // ---------------------------------------------------------------------------
  // BOOKING DATA MODEL (All info stored here)
  // ---------------------------------------------------------------------------
  final Map<String, dynamic> _bookingData = {
    "mainUser": {
      "name": "",
      "email": "",
      "phone": "",
      "foodPreference": <String>[],
      "preferredActivities": <String>[],
      "avoidPreference": <String>[],
      // "travelPace": "",
    },
    "travelers": <Map<String, String>>[],
  };

  Map<String, dynamic> getBookingData() {
    return {
      "mainUser": _bookingData["mainUser"],
      "travelers": _bookingData["travelers"],
      "preferences": {
        "foodPreference": _bookingData["mainUser"]["foodPreference"],
        "preferredActivities": _bookingData["mainUser"]["preferredActivities"],
        "avoidPreference": _bookingData["mainUser"]["avoidPreference"],
      },
    };
  }

  // ---------------------------------------------------------------------------
  // Firestore taxonomy
  // ---------------------------------------------------------------------------
  List<String> foodTypes = [];
  List<String> activityTypes = [];

  @override
  void initState() {
    super.initState();
    _loadEverything();
  }

  // ===========================================================================
  // LOAD EVERYTHING
  // ===========================================================================
  Future<void> _loadEverything() async {
    setState(() => _loading = true);

    await _loadTaxonomy(); // foodTypes, activityTypes
    await _loadUserProfile(); // user name, email, phone
    await _loadUserPrefs(); // saved preferences
    _restoreInitialData(); // from Page 1 → Page 2 navigation

    _generateTravelersList();

    setState(() => _loading = false);
  }

  Future<void> _loadTaxonomy() async {
    final snap = await FirebaseFirestore.instance.collection('taxonomy').get();

    for (final doc in snap.docs) {
      if (doc.id == "foodTypes") {
        foodTypes = List<String>.from(doc['values'] ?? []);
      } else if (doc.id == "activityTypes") {
        activityTypes = List<String>.from(doc['values'] ?? []);
      }
    }
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

    if (!doc.exists) return;

    final d = doc.data()!;
    _bookingData["mainUser"]["name"] =
        "${d['firstName'] ?? ''} ${d['lastName'] ?? ''}".trim();
    _bookingData["mainUser"]["email"] = d["email"] ?? "";
    _bookingData["mainUser"]["phone"] = d["phone"] ?? "";
  }

  Future<void> _loadUserPrefs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final prefsDoc =
        await FirebaseFirestore.instance
            .collection("userPreferences")
            .doc(user.uid)
            .get();

    if (!prefsDoc.exists) return;

    final p = prefsDoc.data()!;
    _bookingData["mainUser"]["foodPreference"] = List<String>.from(
      p["foodPreference"] ?? [],
    );
    _bookingData["mainUser"]["preferredActivities"] = List<String>.from(
      p["preferredActivities"] ?? [],
    );
    _bookingData["mainUser"]["avoidPreference"] = List<String>.from(
      p["avoidPreference"] ?? [],
    );
  }

  // Restore state if user came back from Page 3
  void _restoreInitialData() {
    if (widget.initialData.isEmpty) return;

    if (widget.initialData["mainUser"] != null) {
      final m = widget.initialData["mainUser"];
      _bookingData["mainUser"].addAll(m);
    }

    if (widget.initialData["travelers"] != null) {
      _bookingData["travelers"] = List<Map<String, String>>.from(
        widget.initialData["travelers"],
      );
    }
  }

  void _generateTravelersList() {
    if (_bookingData["travelers"].isNotEmpty) return;

    final count = widget.numTravelers - 1;
    _bookingData["travelers"] = List.generate(
      count,
      (_) => {"name": "", "relationship": ""},
    );
  }

  void saveToParent() {
    widget.onDataSaved({
      "mainUser": _bookingData["mainUser"],
      "travelers": _bookingData["travelers"],
      "preferences": {
        "foodPreference": _bookingData["mainUser"]["foodPreference"],
        "preferredActivities": _bookingData["mainUser"]["preferredActivities"],
        "avoidPreference": _bookingData["mainUser"]["avoidPreference"],
      },
    });
  }

  // ===========================================================================
  // SAVE PREFERENCES (Firestore)
  // ===========================================================================
  Future<void> savePreferencesToFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final prefsRef = FirebaseFirestore.instance
          .collection("userPreferences")
          .doc(user.uid);

      final prefsData = {
        "userId": user.uid,
        "foodPreference": _bookingData["mainUser"]["foodPreference"],
        "preferredActivities": _bookingData["mainUser"]["preferredActivities"],
        "avoidPreference": _bookingData["mainUser"]["avoidPreference"],
      };

      final doc = await prefsRef.get();
      if (doc.exists) {
        await prefsRef.update(prefsData);
      } else {
        await prefsRef.set(prefsData);
      }
    } catch (e) {
      // Handle errors if necessary
      print("Error saving preferences: $e");
    }
  }

  // ===========================================================================
  // MAIN BUILD
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title("Account Owner Details"),
            _gap(),
            _textField(
              label: "Full Name",
              initial: _bookingData["mainUser"]["name"],
              onChanged: (v) => _bookingData["mainUser"]["name"] = v,
            ),
            _gap(),
            _textField(
              label: "Email",
              keyboard: TextInputType.emailAddress,
              initial: _bookingData["mainUser"]["email"],
              onChanged: (v) => _bookingData["mainUser"]["email"] = v,
            ),
            _gap(),
            _textField(
              label: "Phone",
              keyboard: TextInputType.phone,
              initial: _bookingData["mainUser"]["phone"],
              onChanged: (v) => _bookingData["mainUser"]["phone"] = v,
            ),

            const SizedBox(height: 20),
            const Divider(),

            // ======================= PREFERENCES =======================
            // _title("Preferences"),
            // _gap(),
            // _dropdown(
            //   label: "Travel Pace",
            //   items: activityTypes,
            //   value:
            //       _bookingData["mainUser"]["travelPace"].isEmpty
            //           ? null
            //           : _bookingData["mainUser"]["travelPace"],
            //   onChanged: (v) {
            //     setState(() => _bookingData["mainUser"]["travelPace"] = v!);
            //   },
            // ),
            _gap(),

            _multiSelect(
              label: "Food Preference",
              items: foodTypes,
              selected: List<String>.from(
                _bookingData["mainUser"]["foodPreference"],
              ),
              onChanged: (list) {
                setState(() {
                  _bookingData["mainUser"]["foodPreference"] = list;
                });
              },
            ),
            _gap(),

            _multiSelect(
              label: "Preferred Activities",
              items: activityTypes,
              selected: List<String>.from(
                _bookingData["mainUser"]["preferredActivities"],
              ),
              onChanged: (list) {
                setState(() {
                  _bookingData["mainUser"]["preferredActivities"] = list;
                  _bookingData["mainUser"]["avoidPreference"].removeWhere(
                    (a) => list.contains(a),
                  );
                });
              },
            ),
            _gap(),
            _multiSelect(
              label: "Activities to Avoid",
              items: activityTypes,
              selected: List<String>.from(
                _bookingData["mainUser"]["avoidPreference"],
              ),
              onChanged: (list) {
                setState(() {
                  _bookingData["mainUser"]["avoidPreference"] = list;
                  _bookingData["mainUser"]["preferredActivities"].removeWhere(
                    (a) => list.contains(a),
                  );
                });
              },
            ),

            // ======================= TRAVELERS =========================
            if (widget.numTravelers > 1) ...[
              const SizedBox(height: 30),
              const Divider(),
              _title("Travel Companions"),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _bookingData["travelers"].length,
                itemBuilder: (context, i) => _travelerCard(i),
              ),
            ],

            const SizedBox(height: 30),
            // _saveButton(),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // BUILD HELPERS
  // ===========================================================================

  Widget _title(String t) => Text(
    t,
    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  );

  Widget _gap() => const SizedBox(height: 12);

  Widget _textField({
    required String label,
    String? initial,
    TextInputType? keyboard,
    required Function(String) onChanged,
  }) {
    return TextFormField(
      initialValue: initial,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      validator: (v) => (v == null || v.isEmpty) ? "Please enter $label" : null,
      onChanged: onChanged,
    );
  }

  Widget _dropdown({
    required String label,
    required List<String> items,
    String? value,
    Function(String?)? onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        labelText: label,
      ),
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      validator:
          (v) => (v == null || v.isEmpty) ? "Please select $label" : null,
    );
  }

  Widget _multiSelect({
    required String label,
    required List<String> items,
    required List<String> selected,
    required Function(List<String>) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        Wrap(
          spacing: 8,
          children:
              items.map((item) {
                final isSelected = selected.contains(item);
                return FilterChip(
                  label: Text(item),
                  selected: isSelected,
                  selectedColor: Colors.blue.shade100,
                  onSelected: (v) {
                    final newList = List<String>.from(selected);
                    v ? newList.add(item) : newList.remove(item);
                    onChanged(newList);
                  },
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _travelerCard(int i) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Traveler ${i + 2}",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          _gap(),
          _textField(
            label: "Full Name",
            initial: _bookingData["travelers"][i]["name"],
            onChanged: (v) => _bookingData["travelers"][i]["name"] = v,
          ),
          _gap(),
          _textField(
            label: "Relationship",
            initial: _bookingData["travelers"][i]["relationship"],
            onChanged: (v) => _bookingData["travelers"][i]["relationship"] = v,
          ),
        ],
      ),
    );
  }

  Widget _saveButton() {
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.save),
        label: const Text("Save Details"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
        onPressed: () async {
          if (!_formKey.currentState!.validate()) return;

          // Save firestore prefs
          await savePreferencesToFirestore();

          // Pass booking data back to parent
          widget.onDataSaved(_bookingData);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("User details added successfully!"),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }
}
