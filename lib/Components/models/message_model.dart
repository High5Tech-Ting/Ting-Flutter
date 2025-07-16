import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String messageId;
  final String senderId;
  final String receiverId;
  final String text;
  final Timestamp timestamp;
  final String status;

  Message({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.status = 'unknown'
  });

  factory Message.fromMap(Map<String, dynamic> data) {
    return Message(
        messageId: data['messageId'] as String? ?? 'unknown-id',
        senderId: data['senderId'] as String? ?? 'unknown-sender',
        receiverId: data['receiverId'] as String? ?? 'unknown-receiver',
        text: data['text'] as String? ?? 'No message provided',
        timestamp: data['timestamp'] is Timestamp
            ? data['timestamp'] as Timestamp
            : Timestamp.now(),
        status: data['status'] as String? ?? 'unknown'
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': timestamp,
      'status': status
    };
  }
}