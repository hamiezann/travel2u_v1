import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CrudTaxonomyPage extends StatefulWidget {
  final String taxonomyType; // e.g., 'tags', 'activityTypes', 'foodTypes'
  const CrudTaxonomyPage({super.key, required this.taxonomyType});

  @override
  State<CrudTaxonomyPage> createState() => _CrudTaxonomyPageState();
}

class _CrudTaxonomyPageState extends State<CrudTaxonomyPage> {
  final TextEditingController _controller = TextEditingController();
  List<String> _values = [];
  bool _loading = true;

  // 🔑 Staff Brand Color
  // static const Color _staffColor = Colors.teal;
  static const _staffColor = Colors.teal;

  // Helper to format the title nicely
  String get _formattedTitle {
    // Converts "activityTypes" to "Activity Types"
    return widget.taxonomyType
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[1]}')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  void initState() {
    super.initState();
    _fetchValues();
  }

  // --- Data Logic (Unchanged for Functionality) ---

  Future<void> _fetchValues() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('taxonomy')
            .doc(widget.taxonomyType)
            .get();

    if (doc.exists && doc.data()!['values'] is List) {
      setState(() {
        _values = List<String>.from(doc.data()!['values']);
        _loading = false;
      });
    } else {
      await FirebaseFirestore.instance
          .collection('taxonomy')
          .doc(widget.taxonomyType)
          .set({'values': []});
      setState(() => _loading = false);
    }
  }

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  Future<void> _addValue(String newValue) async {
    // final trimmedValue = newValue.trim().toUpperCase();
    final trimmedValue = _toTitleCase(newValue.trim());
    if (trimmedValue.isEmpty || _values.contains(trimmedValue)) return;

    // 🔑 Immediately close the keyboard
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _values.add(trimmedValue);
      // Sort the list after adding for a better managerial view
      _values.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    });

    await FirebaseFirestore.instance
        .collection('taxonomy')
        .doc(widget.taxonomyType)
        .update({'values': _values});

    _controller.clear();
  }

  Future<void> _deleteValue(String value) async {
    setState(() => _values.remove(value));

    await FirebaseFirestore.instance
        .collection('taxonomy')
        .doc(widget.taxonomyType)
        .update({'values': _values});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage $_formattedTitle',
          style: TextStyle(color: Colors.white),
        ), // 🔑 Improved Title
        backgroundColor: _staffColor, // 🔑 Branded Color
        elevation: 1,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_staffColor.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                  padding: const EdgeInsets.all(20), // 🔑 Increased padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- 1. Add New Item Input ---
                      _buildInputRow(context),
                      const SizedBox(
                        height: 25,
                      ), // 🔑 Increased vertical spacing
                      // --- 2. List Header ---
                      Text(
                        'Current $_formattedTitle (${_values.length})',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const Divider(
                        color: _staffColor,
                        thickness: 2,
                      ), // 🔑 Visual separator
                      // --- 3. Items List ---
                      Expanded(
                        child:
                            _values.isEmpty
                                ? Center(
                                  child: Text('No $_formattedTitle added yet.'),
                                )
                                : ListView.separated(
                                  // 🔑 Use ListView.separated for dividers
                                  itemCount: _values.length,
                                  separatorBuilder:
                                      (context, index) =>
                                          const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final item = _values[index];
                                    return _buildTaxonomyTile(
                                      item,
                                    ); // 🔑 Custom Tile Widget
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  // 🔑 Custom Widget for the Input Field
  Widget _buildInputRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Enter new ${_formattedTitle.toLowerCase()}',
              hintText: 'e.g., Beach, Hiking, Buffet',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _staffColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _staffColor, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 15,
              ),
            ),
            onSubmitted: _addValue, // 🔑 Allow adding by pressing Enter/Done
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () => _addValue(_controller.text),
          icon: const Icon(Icons.add, size: 20),
          label: const Text('Add'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _staffColor, // 🔑 Branded Color
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  // 🔑 Custom Widget for the List Item
  Widget _buildTaxonomyTile(String item) {
    return Card(
      elevation: 2, // Subtle lift
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(Icons.category, color: _staffColor.withOpacity(0.7)),
        title: Text(
          item,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.delete_outline,
            color: Colors.redAccent,
          ), // 🔑 Improved delete icon
          onPressed: () => _deleteValue(item),
        ),
      ),
    );
  }
}
