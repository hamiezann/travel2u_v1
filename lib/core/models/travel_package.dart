import 'package:travel2u_v1/core/models/activity.dart';

class TravelPackage {
  String id;
  String name;
  String destination;
  int duration;
  double price;
  String imageUrl;
  String tourGuide;
  String flightDetail;
  String flightClass;
  String hotelDetail;
  String hotelRating;
  List<String> tags;
  List<Activity> activityPool; // flattened list
  List<List<Activity>> activitiesByDay; // structured by day

  TravelPackage({
    required this.id,
    required this.name,
    required this.destination,
    required this.duration,
    required this.price,
    required this.imageUrl,
    required this.flightClass,
    required this.flightDetail,
    required this.hotelDetail,
    required this.hotelRating,
    required this.tourGuide,
    required this.tags,
    required this.activityPool,
    required this.activitiesByDay,
  });

  factory TravelPackage.fromJson(Map<String, dynamic> json) {
    return TravelPackage(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      destination: json['destination'] ?? '',
      duration: (json['duration'] ?? 0).toInt(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl'] ?? '',
      tourGuide: json['tourGuide'] ?? '',
      flightDetail: json['flightDetail'] ?? '',
      flightClass: json['flightClass'] ?? '',
      hotelDetail: json['hotelDetail'] ?? '',
      hotelRating: json['hotelRating'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),

      activityPool:
          (json['activityPool'] as List<dynamic>?)
              ?.map((e) => Activity.fromJson(e))
              .toList() ??
          [],

      activitiesByDay:
          (json['activitiesByDay'] as List<dynamic>?)?.map((dayData) {
            if (dayData is Map<String, dynamic> &&
                dayData['activities'] is List) {
              return (dayData['activities'] as List)
                  .map((a) => Activity.fromJson(a))
                  .toList();
            } else if (dayData is List) {
              return dayData.map((a) => Activity.fromJson(a)).toList();
            } else {
              return <Activity>[];
            }
          }).toList() ??
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
    'tourGuide': tourGuide,
    'flightDetail': flightDetail,
    'flightClass': flightClass,
    'hotelDetail': hotelDetail,
    'hotelRating': hotelRating,
    'tags': tags,
    'activityPool': activityPool.map((a) => a.toJson()).toList(),
    'activitiesByDay':
        activitiesByDay
            .map((dayList) => dayList.map((a) => a.toJson()).toList())
            .toList(),
  };
}
