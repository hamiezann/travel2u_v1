// 3. Itineraries - Access Anytime During Trip
import 'package:flutter/material.dart';

class ItinerariesPage extends StatefulWidget {
  const ItinerariesPage({super.key});

  @override
  State<ItinerariesPage> createState() => _ItinerariesPageState();
}

class _ItinerariesPageState extends State<ItinerariesPage> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Text(
                '${index + 1}',
                style: const TextStyle(color: Colors.blue),
              ),
            ),
            title: Text(
              'Trip ${index + 1} Itinerary',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Nov ${15 + index * 5}, 2025'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildItineraryDay(
                      'Day 1',
                      'Arrival & Check-in',
                      '09:00 AM',
                    ),
                    _buildItineraryDay('Day 2', 'City Tour', '08:00 AM'),
                    _buildItineraryDay('Day 3', 'Beach Activities', '10:00 AM'),
                    _buildItineraryDay('Day 4', 'Mountain Hiking', '07:00 AM'),
                    _buildItineraryDay('Day 5', 'Departure', '12:00 PM'),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Itinerary downloaded!'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('Download Itinerary'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItineraryDay(String day, String activity, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 4, height: 40, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(activity, style: TextStyle(color: Colors.grey[700])),
                Text(
                  time,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
