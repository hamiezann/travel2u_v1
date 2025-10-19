class UserPreferences {
  final String userId;
  final List<String> preferredActivities;
  final List<String> foodPreference;
  final String travelPace; // e.g. relax, adventure

  UserPreferences({
    required this.userId,
    required this.preferredActivities,
    required this.foodPreference,
    required this.travelPace,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      userId: json['userId'],
      preferredActivities: List<String>.from(json['preferredActivities'] ?? []),
      foodPreference: List<String>.from(json['foodPreference'] ?? []),
      travelPace: json['travelPace'],
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'preferredActivities': preferredActivities,
    'foodPreference': foodPreference,
    'travelPace': travelPace,
  };
}
