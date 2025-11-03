import 'package:flutter/material.dart';

class ManageTaxonomyPage extends StatelessWidget {
  const ManageTaxonomyPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Staff Brand Color
    const staffColor = Colors.teal;

    // List of Taxonomy Items for easier iteration and styling
    final List<Map<String, dynamic>> taxonomies = [
      {
        'type': 'tags',
        'title': 'Manage Tags',
        'icon': Icons.label_important_outline,
        'color': Colors.blueGrey,
      },
      {
        'type': 'activityTypes',
        'title': 'Manage Activity Types',
        'icon': Icons.directions_run_outlined,
        'color': Colors.indigo,
      },
      {
        'type': 'foodTypes',
        'title': 'Manage Food Types',
        'icon': Icons.restaurant_menu_outlined,
        'color': Colors.orange,
      },
      {
        'type': 'flightClass',
        'title': 'Manage Flight Class',
        'icon': Icons.flight_takeoff_outlined,
        'color': Colors.pink,
      },
      // You can add more here easily
    ];

    void navigateToTaxonomy(String taxonomyType) {
      Navigator.pushNamed(
        context,
        '/crud-taxonomy',
        arguments: {'taxonomyType': taxonomyType},
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Taxonomy Management",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: staffColor,
        elevation: 0, // Removes the shadow
      ),
      body: Container(
        // Subtle gradient background for a management dashboard feel
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [staffColor.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Categorization Hub",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: staffColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "Select a category to view, create, or edit its terms.",
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Use ListView.builder or map for dynamic creation
              ...taxonomies.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _TaxonomyCard(
                    title: item['title'],
                    icon: item['icon'],
                    color: item['color'],
                    onTap: () => navigateToTaxonomy(item['type']),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}

// ---
// Custom Widget for a cleaner UI
// ---

class _TaxonomyCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TaxonomyCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
