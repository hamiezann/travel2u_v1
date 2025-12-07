import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  Function(Map<String, dynamic>)? onNotificationTap;

  Future<void> init() async {
    // -----------------------------
    // Local Notification Init
    // -----------------------------
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(),
    );

    await _local.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null && details.payload!.isNotEmpty) {
          onNotificationTap?.call(jsonDecode(details.payload!));
        }
      },
    );

    // -----------------------------
    // Firebase Messaging Init
    // -----------------------------
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // Save token on refresh
    _messaging.onTokenRefresh.listen(_saveTokenToFirestore);

    final token = await _messaging.getToken();
    if (token != null) _saveTokenToFirestore(token);

    // Foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      _showLocal(message);
      _saveToFirestore(message);
    });

    // Background & terminated → tapped
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      onNotificationTap?.call(message.data);
    });
  }

  // --------------------------------------------------
  // DISPLAY LOCAL NOTIFICATION
  // --------------------------------------------------
  Future<void> _showLocal(RemoteMessage message) async {
    const android = AndroidNotificationDetails(
      "main_channel",
      "General Notifications",
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/logo1bw',
    );

    final notification = message.notification;

    if (notification == null) return;

    await _local.show(
      message.hashCode,
      notification.title ?? "Notification",
      notification.body ?? "",
      const NotificationDetails(android: android),
      payload: jsonEncode(message.data),
    );
  }

  // --------------------------------------------------
  // SAVE NOTIFICATIONS TO FIRESTORE
  // --------------------------------------------------
  Future<void> _saveToFirestore(RemoteMessage msg) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("notifications")
          .add({
            "title": msg.notification?.title ?? "",
            "body": msg.notification?.body ?? "",
            "data": msg.data,
            "isRead": false,
            "timestamp": Timestamp.now(),
          });
    } catch (e) {
      print("Error saving notification: $e");
    }
  }

  // --------------------------------------------------
  // MARK SPECIFIC NOTIFICATION AS READ
  // --------------------------------------------------
  Future<void> markAsRead(String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("notifications")
        .doc(docId)
        .update({"isRead": true});
  }

  // --------------------------------------------------
  // SEND NOTIFICATION TO FIREBASE FUNCTIONS QUEUE
  // --------------------------------------------------
  Future<void> sendNotification({
    required String title,
    required String body,
    required String userId,
    Map<String, dynamic>? data,
  }) async {
    await FirebaseFirestore.instance.collection("push_queue").add({
      "userId": userId,
      "title": title,
      "body": body,
      "data": data ?? {},
      "timestamp": Timestamp.now(),
    });
  }

  // --------------------------------------------------
  // STORE TOKEN TO USER DOC
  // --------------------------------------------------
  void _saveTokenToFirestore(String token) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance.collection("users").doc(user.uid).update({
      "fcmToken": token,
    });
  }

  // --------------------------------------------------
  // mark all as read
  // --------------------------------------------------
  Future<void> markAllAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final notiRef = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("notifications");

    final unread = await notiRef.where("isRead", isEqualTo: false).get();

    for (var doc in unread.docs) {
      doc.reference.update({"isRead": true});
    }
  }

  // --------------------------------------------------
  // clear all notifications
  // --------------------------------------------------
  Future<void> clearAllNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final notiRef = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("notifications");

    final all = await notiRef.get();
    for (var doc in all.docs) {
      await doc.reference.delete();
    }
  }
}
