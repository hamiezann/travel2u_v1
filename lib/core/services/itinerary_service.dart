import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travel2u_v1/core/models/activity.dart';
import 'package:travel2u_v1/core/models/itinerary.dart';

class ItineraryService {
  /// Returns a map: { success: bool, message: string, itineraryId?: string }
  static Future<Map<String, dynamic>> generateUserItinerary({
    required String userId,
    required String packageId,
    required Map<String, dynamic> userPrefs,
    required int packageDuration,
    bool writeLogs = true,
  }) async {
    final firestore = FirebaseFirestore.instance;

    try {
      // 1) Try subcollection 'activities'
      List<Activity> allActivities = [];
      final activitiesCollection = firestore
          .collection('travel_packages')
          .doc(packageId)
          .collection('activities');

      final subSnap = await activitiesCollection.get();
      if (subSnap.docs.isNotEmpty) {
        allActivities =
            subSnap.docs.map((d) {
              final data = Map<String, dynamic>.from(d.data());
              // ensure id field exists for model
              if (!data.containsKey('id')) data['id'] = d.id;
              return Activity.fromJson(data);
            }).toList();
      } else {
        // 2) Fallback: read package doc fields (activityPool / activitiesByDay)
        final pkgDoc =
            await firestore.collection('travel_packages').doc(packageId).get();
        if (!pkgDoc.exists) {
          throw Exception('Package document not found for id=$packageId');
        }
        final pkgData = pkgDoc.data() ?? {};

        // activityPool: list of activity maps
        if (pkgData['activityPool'] is List &&
            (pkgData['activityPool'] as List).isNotEmpty) {
          final pool = List<Map<String, dynamic>>.from(pkgData['activityPool']);
          allActivities =
              pool.map((m) {
                final entry = Map<String, dynamic>.from(m);
                if (!entry.containsKey('id')) entry['id'] = entry['id'] ?? '';
                return Activity.fromJson(entry);
              }).toList();
        } else if (pkgData['activitiesByDay'] is List &&
            (pkgData['activitiesByDay'] as List).isNotEmpty) {
          final days = pkgData['activitiesByDay'] as List;
          final flattened = <Map<String, dynamic>>[];
          for (final d in days) {
            if (d is Map && d['activities'] is List) {
              for (final a in List.from(d['activities'])) {
                flattened.add(Map<String, dynamic>.from(a));
              }
            } else if (d is List) {
              for (final a in d) {
                flattened.add(Map<String, dynamic>.from(a));
              }
            }
          }
          allActivities = flattened.map((m) => Activity.fromJson(m)).toList();
        }
      }

      // 3) Perform matching and distribution
      final matched = _matchActivities(allActivities, userPrefs);
      final days = _distributeIntoDays(matched, packageDuration);

      // 4) Save itinerary
      final itDocRef = await firestore.collection('itineraries').add({
        'packageId': packageId,
        'userId': userId,
        'status': 'pending',
        'days': days.map((d) => d.toJson()).toList(),
        'createdAt': FieldValue.serverTimestamp(),
        'lastEditedBy': userId,
        'generationNotes':
            'Generated ${matched.length} activities via rule-based matcher.',
      });

      return {
        'success': true,
        'message': 'Itinerary generated',
        'itineraryId': itDocRef.id,
      };
    } catch (e, st) {
      // optional logging collection for easier debugging
      if (writeLogs) {
        await firestore.collection('itineraryGenerationLogs').add({
          'packageId': packageId,
          'userId': userId,
          'error': e.toString(),
          'stack': st.toString(),
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
      return {'success': false, 'message': e.toString()};
    }
  }

  // ----------------- matching & distribute (unchanged logic) -----------------
  static List<Activity> _matchActivities(
    List<Activity> all,
    Map<String, dynamic> prefs,
  ) {
    final preferredTypes = List<String>.from(
      prefs['preferredActivities'] ?? [],
    );
    final preferredFood = List<String>.from(prefs['foodPreference'] ?? []);
    final avoidTypes = List<String>.from(prefs['avoidPreference'] ?? []);

    final bool noPrefs =
        preferredTypes.isEmpty && preferredFood.isEmpty && avoidTypes.isEmpty;

    if (noPrefs) return [];

    // 1) Remove avoid types
    final valid = all.where((a) => !avoidTypes.contains(a.type)).toList();

    if (valid.isEmpty) return [];

    // 2) Score activities
    final scored =
        valid.map((act) {
          int score = 0;

          if (preferredTypes.contains(act.type)) score += 3;
          if (act.foodType.any((f) => preferredFood.contains(f))) score += 1;

          return {"a": act, "s": score};
        }).toList();

    // 3) Keep scored>=2 only
    final filtered = scored.where((e) => (e["s"] as int) >= 2).toList();
    if (filtered.isEmpty) return [];

    // 4) Safe sort
    filtered.sort(
      (a, b) => ((b["s"] as int?) ?? 0).compareTo((a["s"] as int?) ?? 0),
    );

    // 5) Top 60%
    final takeCount = (filtered.length * 0.6).ceil().clamp(1, filtered.length);
    final top = filtered.take(takeCount).toList();

    return top.map((e) => e["a"] as Activity).toList();
  }

  static List<ItineraryDay> _distributeIntoDays(
    List<Activity> activities,
    int totalDays,
  ) {
    const maxPerDay = 5;
    const minPerDay = 1;

    List<ItineraryDay> days = [];
    int index = 0;
    final total = activities.length;

    // If empty → generate empty days
    if (total == 0) {
      for (int d = 1; d <= totalDays; d++) {
        days.add(ItineraryDay(day: d, activities: []));
      }
      return days;
    }

    for (int d = 1; d <= totalDays; d++) {
      int remaining = total - index;
      int daysLeft = totalDays - d + 1;

      int allocate = (remaining / daysLeft).ceil();

      allocate = allocate.clamp(minPerDay, maxPerDay);
      allocate = allocate.clamp(0, remaining);

      if (allocate <= 0) {
        days.add(ItineraryDay(day: d, activities: []));
        continue;
      }

      // SAFE: prevents RangeError
      final end = (index + allocate).clamp(0, total);
      final dayActivities = activities.sublist(index, end);

      days.add(ItineraryDay(day: d, activities: dayActivities));

      index = end;
    }

    return days;
  }
}
