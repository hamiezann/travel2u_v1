import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:travel2u_v1/core/services/notification_service.dart';

class ChatPage extends StatefulWidget {
  final String bookingId;
  final String userId;
  final String packageId;
  final String supportId;

  const ChatPage({
    super.key,
    required this.bookingId,
    required this.userId,
    required this.packageId,
    required this.supportId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _msgController = TextEditingController();
  String staffName = "Support";
  String customerName = "Customer";

  @override
  void initState() {
    super.initState();
    markAsRead();
    loadNames();
  }

  Future<void> loadNames() async {
    final staffId = FirebaseAuth.instance.currentUser?.uid;

    // Load staff/admin name
    final staffDoc =
        await FirebaseFirestore.instance.collection("users").doc(staffId).get();

    if (staffDoc.exists) {
      staffName = staffDoc["firstName"] ?? "Support";
    }

    // Load customer name
    final custDoc =
        await FirebaseFirestore.instance
            .collection("users")
            .doc(widget.userId)
            .get();

    if (custDoc.exists) {
      customerName = custDoc["firstName"] ?? "Customer";
    }

    if (mounted) setState(() {});
  }

  void markAsRead() {
    FirebaseFirestore.instance
        .collection("chats")
        .doc(widget.bookingId)
        .collection("messages")
        .where("sender", isNotEqualTo: "customer")
        // .where("senderId", isNotEqualTo: widget.userId)
        .where("isRead", isEqualTo: false)
        .get()
        .then((snapshot) {
          for (var doc in snapshot.docs) {
            doc.reference.update({"isRead": true});
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final chatRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.bookingId)
        .collection('messages')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Chat with $staffName",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: chatRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    final isMe = msg['senderId'] == widget.userId;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.teal : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          msg['text'] ?? "",
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
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
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final messageRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.bookingId)
        .collection('messages');

    await messageRef.add({
      'senderId': widget.userId,
      'receiverId': widget.supportId,
      'sender': 'customer',
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    // Send notification to support
    await NotificationService().sendNotification(
      title: "Message from $customerName",
      body: text,
      userId: widget.supportId,
      data: {
        "bookingId": widget.bookingId,
        // "packageId": widget.packageId,
        // "userId": widget.userId,
        // "supportId": widget.supportId,
        "type": "chat-customer",
      },
    );

    _msgController.clear();
  }
}
