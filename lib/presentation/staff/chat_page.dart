import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:travel2u_v1/core/services/notification_service.dart';

class ChatPage extends StatefulWidget {
  final String bookingId;
  final String clientName; // You already pass this!
  final String customerId;
  final String packageId;

  const ChatPage({
    super.key,
    required this.bookingId,
    required this.clientName,
    required this.customerId,
    required this.packageId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final staffId = FirebaseAuth.instance.currentUser?.uid;

  String staffName = "Support";
  String clientName = "-"; // <- SAFE DEFAULT (fixes crash)

  CollectionReference get _chatCollection => FirebaseFirestore.instance
      .collection('chats')
      .doc(widget.bookingId)
      .collection('messages');

  @override
  void initState() {
    super.initState();
    clientName = widget.clientName;
    getSenderName();
    markAsRead();
  }

  void markAsRead() {
    FirebaseFirestore.instance
        .collection("chats")
        .doc(widget.bookingId)
        .collection("messages")
        .where("senderId", isEqualTo: widget.customerId)
        .where("isRead", isEqualTo: false)
        .get()
        .then((snapshot) {
          for (var doc in snapshot.docs) {
            doc.reference.update({"isRead": true});
          }
        });
  }

  Future<void> getSenderName() async {
    // Load customer name
    final userDoc =
        await FirebaseFirestore.instance
            .collection("users")
            .doc(widget.customerId)
            .get();

    if (userDoc.exists) {
      setState(() {
        clientName = userDoc.data()?["firstName"] ?? "Customer";
      });
    }

    // Load staff name
    final staffDoc =
        await FirebaseFirestore.instance.collection("users").doc(staffId).get();

    if (staffDoc.exists) {
      setState(() {
        staffName = staffDoc.data()?["firstName"] ?? "Support";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Chat with $clientName",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  _chatCollection
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  return const Center(child: Text("No messages yet"));
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    final isStaff = msg["sender"] == "staff";

                    return Align(
                      alignment:
                          isStaff
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 12,
                        ),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isStaff ? Colors.teal[200] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(msg["text"] ?? ""),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Type a message",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.teal),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    await _chatCollection.add({
      "text": text,
      "sender": "staff",
      "senderId": staffId,
      "createdAt": FieldValue.serverTimestamp(),
      "isRead": false,
    });

    await NotificationService().sendNotification(
      title: "Message from Support $staffName",
      body: text,
      userId: widget.customerId,
      data: {
        "bookingId": widget.bookingId,
        "packageId": widget.packageId,
        "userId": widget.customerId,
        "supportId": staffId,
        "type": "chat-staff",
      },
    );

    _controller.clear();
  }
}
