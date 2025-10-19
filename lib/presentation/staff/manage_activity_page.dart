import 'package:flutter/material.dart';

class ManageActivityPage extends StatelessWidget {
  const ManageActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Activities"),
        backgroundColor: Colors.teal,
      ),
      body: const Center(
        child: Text(
          "Activity Pool (Coming Soon)",
          style: TextStyle(fontSize: 18),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add activity form navigation
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
}
