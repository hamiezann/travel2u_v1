import 'package:travel2u_v1/core/models/activity.dart';

class TravelPackage {
  String id;
  String name;
  String destination;
  int duration;
  double price;
  String imageUrl;
  List<String> tags;
  List<Activity> activityPool;

  TravelPackage({
    required this.id,
    required this.name,
    required this.destination,
    required this.duration,
    required this.price,
    required this.imageUrl,
    required this.tags,
    required this.activityPool,
  });

  factory TravelPackage.fromJson(Map<String, dynamic> json) {
    return TravelPackage(
      id: json['id'],
      name: json['name'],
      destination: json['destination'],
      duration: json['duration'],
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'],
      tags: List<String>.from(json['tags'] ?? []),
      activityPool:
          (json['activityPool'] as List<dynamic>?)
              ?.map((e) => Activity.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'destination': destination,
    'duration': duration,
    'price': price,
    'imageUrl': imageUrl,
    'tags': tags,
    'activityPool': activityPool.map((a) => a.toJson()).toList(),
  };
}
