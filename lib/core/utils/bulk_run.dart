import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class BulkPackageUploader {
  static final _firestore = FirebaseFirestore.instance;

  /// Staff / Creator IDs you provided
  static final List<String> creatorIds = [
    "4NpJJodEwQX7PHAqNmivSoRTIPh2",
    "YklHCfUiJ0hekUhY1U0tvYiwtn73",
    "ub49u5CeERc2CYc5berUsdeRCq92",
  ];

  /// Random generator
  static final _random = Random();

  /// Call this method to insert all packages at once.
  static Future<void> uploadPackages() async {
    // -----------------------------
    // PUT YOUR GENERATED PACKAGES HERE
    // -----------------------------
    final List<Map<String, dynamic>> packages = [
      {
        "name": "KL Urban Explorer",
        "destination": "Kuala Lumpur, Malaysia",
        "duration": 3,
        "price": 499.00,
        "flightClass": "Air Asia",
        "foodTypes": ["Local Cuisine", "Street Food", "Halal/kosher"],
        "tags": ["Budget Friendly", "Weekend Getaway", "Hidden Gems"],
        "activityPool": [
          {
            "id": "act_pavilion",
            "name": "Pavilion Walk & Street Market",
            "type": "City Sightseeing",
            "foodType": ["Street Food"],
            "duration": 2,
          },
          {
            "id": "act_batu",
            "name": "Batu Caves Cultural Tour",
            "type": "Cultural Immersion",
            "foodType": ["Local Cuisine"],
            "duration": 3,
          },
          {
            "id": "act_klcc",
            "name": "KLCC Park Evening Walk",
            "type": "Outdoor",
            "foodType": [],
            "duration": 1,
          },
        ],
      },

      // Add more packages here...
      // {
      //  "name": "...",
      //  "destination": "...",
      // }
    ];

    // ----------------------------
    // Start actual upload process
    // ----------------------------
    for (final pkg in packages) {
      final docRef = _firestore.collection("travel_packages").doc();

      final creatorId = creatorIds[_random.nextInt(creatorIds.length)];

      final data = {
        "id": docRef.id,
        "name": pkg["name"],
        "destination": pkg["destination"],
        "duration": pkg["duration"],
        "price": pkg["price"],
        "flightClass": pkg["flightClass"],
        "tags": pkg["tags"] ?? [],
        "foodTypes": pkg["foodTypes"] ?? [],
        "activityPool": pkg["activityPool"] ?? [],

        // Optional fields you want to standardize
        "hotelDetail": pkg["hotelDetail"] ?? "",
        "hotelRating": pkg["hotelRating"] ?? "",
        "flightDetail": pkg["flightDetail"] ?? "",
        "tourGuide": pkg["tourGuide"] ?? "",
        "imageUrl":
            pkg["imageUrl"] ??
            "https://picsum.photos/seed/${docRef.id}/600/400",

        // Creator tracking
        "creatorId": creatorId,
        "createdAt": FieldValue.serverTimestamp(),

        // If you are using activitiesByDay for some packages:
        "activitiesByDay": pkg["activitiesByDay"] ?? [],
      };

      await docRef.set(data);
      print("Uploaded: ${pkg['name']} (${docRef.id})");
    }

    print("====== BULK UPLOAD COMPLETED ======");
  }
}
