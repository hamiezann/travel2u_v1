class Activity {
  final String id;
  final String name;
  final String type; // e.g. beach, food, culture
  final String duration;
  final String location;
  final List<String> foodType;
  final int day;

  Activity({
    required this.id,
    required this.name,
    required this.type,
    required this.duration,
    required this.location,
    required this.foodType,
    required this.day,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      duration: json['duration'],
      location: json['location'],
      foodType: List<String>.from(json['foodType'] ?? []),
      day: json['day'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'duration': duration,
    'location': location,
    'foodType': foodType,
    'day': day,
  };
}
