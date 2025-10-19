import 'package:travel2u_v1/core/models/activity.dart';

class Itinerary {
  final String? id;
  final String packageId;
  final String userId;
  final List<ItineraryDay> days;
  final String status;
  final String lastEditedBy;

  Itinerary({
    this.id,
    required this.packageId,
    required this.userId,
    required this.days,
    required this.status,
    required this.lastEditedBy,
  });

  factory Itinerary.fromJson(Map<String, dynamic> json) {
    return Itinerary(
      id: json['id'],
      packageId: json['packageId'],
      userId: json['userId'],
      days:
          (json['days'] as List<dynamic>?)
              ?.map((e) => ItineraryDay.fromJson(e))
              .toList() ??
          [],
      status: json['status'],
      lastEditedBy: json['lastEditedBy'],
    );
  }

  Map<String, dynamic> toJson() => {
    'packageId': packageId,
    'userId': userId,
    'days': days.map((d) => d.toJson()).toList(),
    'status': status,
    'lastEditedBy': lastEditedBy,
  };
}

class ItineraryDay {
  final int day;
  final List<Activity> activities;

  ItineraryDay({required this.day, required this.activities});

  factory ItineraryDay.fromJson(Map<String, dynamic> json) {
    return ItineraryDay(
      day: json['day'],
      activities:
          (json['activities'] as List<dynamic>?)
              ?.map((e) => Activity.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'day': day,
    'activities': activities.map((a) => a.toJson()).toList(),
  };
}
