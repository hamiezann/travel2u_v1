import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationIcon extends StatelessWidget {
  final VoidCallback onTap;
  const NotificationIcon({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox();

    final notiRef = FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("notifications");

    return StreamBuilder<QuerySnapshot>(
      stream: notiRef.where("isRead", isEqualTo: false).snapshots(),
      builder: (context, snapshot) {
        int unreadCount = 0;
        if (snapshot.hasData) unreadCount = snapshot.data!.docs.length;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: onTap,
              child: const Icon(
                Icons.notifications_outlined,
                color: Colors.blue,
                size: 24, // match your other leading icons
              ),
            ),

            if (unreadCount > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
