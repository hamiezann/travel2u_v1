import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:travel2u_v1/app.dart';
import 'package:travel2u_v1/core/services/notification_service.dart';
import 'package:travel2u_v1/core/utils/navigator.dart';
import 'package:travel2u_v1/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    NotificationService().onNotificationTap = (payload) async {
      print("📨 Notification tapped payload: $payload");

      final type = payload["type"];

      if (type == "chat-staff") {
        navigatorKey.currentState?.pushNamed(
          "/chat-customer",
          arguments: {
            "bookingId": payload["bookingId"],
            "packageId": payload["packageId"],
            "userId": payload["userId"],
            "supportId": payload["supportId"],
          },
        );
        return;
      }

      if (type == "chat-customer") {
        navigatorKey.currentState?.pushNamed("/staff/manage-booking");
        return;
      }
      if (type == "new-booking") {
        navigatorKey.currentState?.pushNamed("/staff/manage-booking");
        return;
      }
      if (type == "itinerary-update") {
        final packageDoc =
            await FirebaseFirestore.instance
                .collection('travel_packages')
                .doc(payload['packageId'])
                .get();

        final bookingDoc =
            await FirebaseFirestore.instance
                .collection('bookings')
                .doc(payload['bookingId'])
                .get();

        navigatorKey.currentState?.pushNamed(
          "/customer/booking-detail",
          arguments: {
            "packageData": packageDoc.data(),
            "bookingData": bookingDoc.data(),
          },
        );
      }
      if (type == "update-status") {
        final packageDoc =
            await FirebaseFirestore.instance
                .collection('travel_packages')
                .doc(payload['packageId'])
                .get();

        final bookingDoc =
            await FirebaseFirestore.instance
                .collection('bookings')
                .doc(payload['bookingId'])
                .get();

        navigatorKey.currentState?.pushNamed(
          "/customer/booking-status",
          arguments: {
            "packageData": packageDoc.data(),
            "bookingData": bookingDoc.data(),
          },
        );
      }
    };

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await NotificationService().init();

    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      NotificationService().onNotificationTap?.call(initialMessage.data);
    }
  } catch (e) {
    print('Failed to initialize Firebase: $e');
  }

  runApp(TravelApp());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔵 Background message: ${message.notification?.title}");
}
