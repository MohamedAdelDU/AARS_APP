import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Activity {
  final String id;
  final String description;
  final String type;
  final DateTime timestamp;
  final double distance;
  final double speed;
  final String rating;
  final double? latitude;
  final double? longitude;

  Activity({
    required this.id,
    required this.description,
    required this.type,
    required this.timestamp,
    required this.distance,
    required this.speed,
    required this.rating,
    this.latitude,
    this.longitude,
  });
}

class ActivityProvider with ChangeNotifier {
  double _distance = 0.0;
  double _maxSpeed = 0.0;
  List<Activity> _recentActivities = [];
  List<double> _distanceHistory = [];
  String? _userId;
  bool _isLoading = false;
  List<String> _badges = [];

  ActivityProvider() {
    _initializeUserId();
  }

  double get distance => _distance;
  double get distanceTraveled => _distance;
  double get maxSpeed => _maxSpeed;
  List<Activity> get recentActivities => _recentActivities;
  bool get isLoading => _isLoading;
  List<String> get badges => _badges;
  List<Activity> get activities => _recentActivities;

  Future<void> _initializeUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userId = user.uid;
      await loadActivities();
    }
  }

  void updateDistance(double distanceInKm, double speed) {
    if (_userId == null) return;

    if (distanceInKm > 0.0 && distanceInKm < 0.1) {
      _distanceHistory.add(distanceInKm);
      if (_distanceHistory.length > 5) _distanceHistory.removeAt(0);
      double avgDistance =
          _distanceHistory.reduce((a, b) => a + b) / _distanceHistory.length;
      _distance += avgDistance;
    } else {
      _distance += distanceInKm;
    }
    _updateBadges();
    notifyListeners();
  }

  void updateMaxSpeed(double speed) {
    if (speed > _maxSpeed) {
      _maxSpeed = speed;
      if (speed >= 100.0 && !_badges.contains("Safe Speed: 100 km")) {
        _badges.add("Safe Speed: 100 km");
        FlutterLocalNotificationsPlugin().show(
          1,
          '🎉 إنجاز جديد!',
          'لقد وصلت إلى سرعة 100 كم/س بأمان!',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'badge_channel',
              'Badge Notifications',
              channelDescription: 'Notifications for achievements and badges',
              importance: Importance.high,
              priority: Priority.high,
              showWhen: true,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          payload: 'badge_speed_100km',
        );
      }
      notifyListeners();
    }
  }

  Future<void> addActivity(
    String description,
    String type, {
    double? latitude,
    double? longitude,
  }) async {
    if (_userId == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      final activityData = {
        'description': description,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
        'distance': _distance,
        'maxSpeed': _maxSpeed,
        'rating': 0,
        'latitude': latitude,
        'longitude': longitude,
      };

      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('activities')
          .add(activityData);

      final newActivity = Activity(
        id: docRef.id,
        description: description,
        type: type,
        timestamp: DateTime.now(),
        distance: _distance,
        speed: _maxSpeed,
        rating: "Excellent",
        latitude: latitude,
        longitude: longitude,
      );

      _recentActivities.insert(0, newActivity);
      if (_recentActivities.length > 100) {
        _recentActivities.removeLast();
      }

      final allActivities =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_userId)
              .collection('activities')
              .orderBy('timestamp', descending: true)
              .get();
      if (allActivities.docs.length > 100) {
        for (var i = 100; i < allActivities.docs.length; i++) {
          await allActivities.docs[i].reference.delete();
        }
      }

      if (_recentActivities.length >= 100 &&
          !_badges.contains("City Explorer")) {
        _badges.add("City Explorer");
        FlutterLocalNotificationsPlugin().show(
          2,
          '🎉 إنجاز جديد!',
          'لقد أصبحت مستكشف المدينة بتسجيل 100 نشاط!',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'badge_channel',
              'Badge Notifications',
              channelDescription: 'Notifications for achievements and badges',
              importance: Importance.high,
              priority: Priority.high,
              showWhen: true,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          payload: 'badge_city_explorer',
        );
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print("Error adding activity: $e");
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Failed to add activity',
      );
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateActivityRating(String activityId, int rating) async {
    if (_userId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('activities')
          .doc(activityId)
          .update({'rating': rating});

      final activityIndex = _recentActivities.indexWhere(
        (activity) => activity.id == activityId,
      );
      if (activityIndex != -1) {
        final activity = _recentActivities[activityIndex];
        _recentActivities[activityIndex] = Activity(
          id: activity.id,
          description: activity.description,
          type: activity.type,
          timestamp: activity.timestamp,
          distance: activity.distance,
          speed: activity.speed,
          rating: _ratingToString(rating),
          latitude: activity.latitude,
          longitude: activity.longitude,
        );
        notifyListeners();
      }
    } catch (e) {
      print("Error updating activity rating: $e");
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Failed to update activity rating',
      );
    }
  }

  Future<void> removeActivity(String activityId) async {
    if (_userId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('activities')
          .doc(activityId)
          .delete();

      _recentActivities.removeWhere((activity) => activity.id == activityId);
      notifyListeners();
    } catch (e) {
      print("Error removing activity: $e");
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Failed to remove activity',
      );
    }
  }

  Future<void> loadActivities() async {
    if (_userId == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_userId)
              .collection('activities')
              .orderBy('timestamp', descending: true)
              .limit(100)
              .get();

      _recentActivities =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return Activity(
              id: doc.id,
              description: data['description'] ?? '',
              type: data['type'] ?? '',
              timestamp:
                  (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
              distance: data['distance']?.toDouble() ?? 0.0,
              speed: data['maxSpeed']?.toDouble() ?? 0.0,
              rating: _ratingToString(data['rating'] ?? 0),
              latitude: data['latitude']?.toDouble(),
              longitude: data['longitude']?.toDouble(),
            );
          }).toList();

      _distance = _recentActivities.fold(
        0.0,
        (sum, activity) => sum + activity.distance,
      );
      _updateBadges();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print("Error loading activities: $e");
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Failed to load activities',
      );
      _isLoading = false;
      notifyListeners();
    }
  }

  double getDistanceForPeriod({int? days}) {
    final cutoff =
        days != null
            ? DateTime.now().subtract(Duration(days: days))
            : DateTime(1970);
    return _recentActivities
        .where((activity) => activity.timestamp.isAfter(cutoff))
        .fold(0.0, (sum, activity) => sum + activity.distance);
  }

  String getDrivingRating({int? days}) {
    final cutoff =
        days != null
            ? DateTime.now().subtract(Duration(days: days))
            : DateTime(1970);
    final relevantActivities =
        _recentActivities
            .where((activity) => activity.timestamp.isAfter(cutoff))
            .toList();

    if (relevantActivities.isEmpty) return "Excellent";

    final averageRating =
        relevantActivities
            .map((activity) => _stringToRatingValue(activity.rating))
            .reduce((a, b) => a + b) /
        relevantActivities.length;

    if (averageRating <= 1.5) return "Dangerous";
    if (averageRating <= 3.5) return "Normal";
    return "Excellent";
  }

  void _updateBadges() {
    bool newBadge = false;
    if (_distance >= 2000 && !_badges.contains("Safe Driver: 2000 km")) {
      _badges.add("Safe Driver: 2000 km");
      newBadge = true;
      FlutterLocalNotificationsPlugin().show(
        3,
        '🎉 إنجاز جديد!',
        'لقد قطعت 2000 كم بأمان!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'badge_channel',
            'Badge Notifications',
            channelDescription: 'Notifications for achievements and badges',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: 'badge_2000km',
      );
    } else if (_distance >= 1000 && !_badges.contains("Safe Driver: 1000 km")) {
      _badges.add("Safe Driver: 1000 km");
      newBadge = true;
      FlutterLocalNotificationsPlugin().show(
        4,
        '🎉 إنجاز جديد!',
        'لقد قطعت 1000 كم بأمان!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'badge_channel',
            'Badge Notifications',
            channelDescription: 'Notifications for achievements and badges',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: 'badge_1000km',
      );
    } else if (_distance >= 500 && !_badges.contains("Safe Driver: 500 km")) {
      _badges.add("Safe Driver: 500 km");
      newBadge = true;
      FlutterLocalNotificationsPlugin().show(
        5,
        '🎉 إنجاز جديد!',
        'لقد قطعت 500 كم بأمان!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'badge_channel',
            'Badge Notifications',
            channelDescription: 'Notifications for achievements and badges',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: 'badge_500km',
      );
    } else if (_distance >= 100 && !_badges.contains("Safe Driver: 100 km")) {
      _badges.add("Safe Driver: 100 km");
      newBadge = true;
      FlutterLocalNotificationsPlugin().show(
        6,
        '🎉 إنجاز جديد!',
        'لقد قطعت 100 كم بأمان!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'badge_channel',
            'Badge Notifications',
            channelDescription: 'Notifications for achievements and badges',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: 'badge_100km',
      );
    }
    if (newBadge) notifyListeners();
  }

  String _ratingToString(int rating) {
    if (rating <= 1) return "Dangerous";
    if (rating <= 3) return "Normal";
    return "Excellent";
  }

  int _stringToRatingValue(String rating) {
    switch (rating) {
      case "Dangerous":
        return 1;
      case "Normal":
        return 3;
      case "Excellent":
        return 5;
      default:
        return 5;
    }
  }
}
