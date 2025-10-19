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

  @override
  void initState() {
    super.initState();
    _fetchValues();
  }

  Future<void> _fetchValues() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('taxonomy')
            .doc(widget.taxonomyType)
            .get();

    if (doc.exists) {
      setState(() {
        _values = List<String>.from(doc['values']);
        _loading = false;
      });
    } else {
      // If doesn't exist, create it
      await FirebaseFirestore.instance
          .collection('taxonomy')
          .doc(widget.taxonomyType)
          .set({'values': []});
      setState(() => _loading = false);
    }
  }

  Future<void> _addValue(String newValue) async {
    if (newValue.isEmpty) return;

    setState(() => _values.add(newValue));

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
      appBar: AppBar(title: Text('Manage ${widget.taxonomyType}')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              labelText: 'Add new ${widget.taxonomyType}',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _addValue(_controller.text.trim()),
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _values.length,
                        itemBuilder: (context, index) {
                          final item = _values[index];
                          return ListTile(
                            title: Text(item),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteValue(item),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
