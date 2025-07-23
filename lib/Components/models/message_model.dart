import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String messageId;
  final String senderId;
  final String receiverId;
  final String text;
  final Timestamp timestamp;
  final String status;
  final String? fileUrl; 
  final String type; 
  final List<String> deletedFor;
  final bool isDeletedForEveryone;
  final String? replyToMessageId;
  final String? replyToText;
  final String? replyToSenderId;

  Message({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.status = 'unknown',
    this.fileUrl,
    this.type = 'text',
    this.deletedFor = const [],
    this.isDeletedForEveryone = false,
    this.replyToMessageId,
    this.replyToText,
    this.replyToSenderId,
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
        status: data['status'] as String? ?? 'unknown',
        fileUrl: data['fileUrl'] as String?,
        type: data['type'] as String? ?? 'text',
        deletedFor: List<String>.from(data['deletedFor'] ?? []),
        isDeletedForEveryone: data['isDeletedForEveryone'] ?? false,
        replyToMessageId: data['replyToMessageId'] as String?,
        replyToText: data['replyToText'] as String?,
        replyToSenderId: data['replyToSenderId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': timestamp,
      'status': status,
      'fileUrl': fileUrl,
      'type': type,
      'deletedFor': deletedFor,
      'isDeletedForEveryone': isDeletedForEveryone,
      'replyToMessageId': replyToMessageId,
      'replyToText': replyToText,
      'replyToSenderId': replyToSenderId,
    };
  }
}