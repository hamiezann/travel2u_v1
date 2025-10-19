import 'package:flutter/material.dart';

class ManageTaxonomyPage extends StatelessWidget {
  const ManageTaxonomyPage({super.key});

  @override
  Widget build(BuildContext context) {
    void navigateToTaxonomy(String taxonomyType) {
      Navigator.pushNamed(
        context,
        '/crud-taxonomy',
        arguments: {'taxonomyType': taxonomyType},
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Taxonomy"),
        backgroundColor: Colors.pink,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Select Taxonomy to Manage",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: () => navigateToTaxonomy('tags'),
              icon: const Icon(Icons.label),
              label: const Text("Manage Tags"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: () => navigateToTaxonomy('activityTypes'),
              icon: const Icon(Icons.local_activity),
              label: const Text("Manage Activity Types"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: () => navigateToTaxonomy('foodTypes'),
              icon: const Icon(Icons.fastfood),
              label: const Text("Manage Food Types"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
