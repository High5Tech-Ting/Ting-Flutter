import 'package:cloud_firestore/cloud_firestore.dart';

class Broadcast {
  final String broadcastId;
  final String broadcastName;
  final String? broadcastDescription;
  final List<String> userIds;
  final List<String> groupIds;
  final String createdBy;
  final Timestamp createdAt;
  final String? lastMessage;
  final Timestamp? lastMessageTime;
  final Map<String, int> unreadMessages;

  Broadcast({
    required this.broadcastId,
    required this.broadcastName,
    this.broadcastDescription,
    required this.userIds,
    required this.groupIds,
    required this.createdBy,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadMessages = const {},
  });

  factory Broadcast.fromMap(Map<String, dynamic> data, String broadcastId) {
    return Broadcast(
      broadcastId: broadcastId,
      broadcastName: data['broadcastName'] as String? ?? 'Unnamed Broadcast',
      broadcastDescription: data['broadcastDescription'] as String?,
      userIds: List<String>.from(data['userIds'] ?? []),
      groupIds: List<String>.from(data['groupIds'] ?? []),
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      lastMessage: data['lastMessage'] as String?,
      lastMessageTime: data['lastMessageTime'] as Timestamp?,
      unreadMessages: Map<String, int>.from(data['unreadMessages'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'broadcastName': broadcastName,
      'broadcastDescription': broadcastDescription,
      'userIds': userIds,
      'groupIds': groupIds,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'unreadMessages': unreadMessages,
    };
  }

  Broadcast copyWith({
    String? broadcastId,
    String? broadcastName,
    String? broadcastDescription,
    List<String>? userIds,
    List<String>? groupIds,
    String? createdBy,
    Timestamp? createdAt,
    String? lastMessage,
    Timestamp? lastMessageTime,
    Map<String, int>? unreadMessages,
  }) {
    return Broadcast(
      broadcastId: broadcastId ?? this.broadcastId,
      broadcastName: broadcastName ?? this.broadcastName,
      broadcastDescription: broadcastDescription ?? this.broadcastDescription,
      userIds: userIds ?? this.userIds,
      groupIds: groupIds ?? this.groupIds,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadMessages: unreadMessages ?? this.unreadMessages,
    );
  }

  // Get total recipient count
  int get totalRecipients => userIds.length + groupIds.length;
}

class BroadcastMessage {
  final String messageId;
  final String senderId;
  final String broadcastId;
  final String text;
  final Timestamp timestamp;
  final String? fileUrl;
  final String? fileType;
  final String? fileName;
  final List<String> deliveredTo;
  final List<String> readBy;
  final String? originalText;
  final bool isAppropriate;

  BroadcastMessage({
    required this.messageId,
    required this.senderId,
    required this.broadcastId,
    required this.text,
    required this.timestamp,
    this.fileUrl,
    this.fileType,
    this.fileName,
    this.deliveredTo = const [],
    this.readBy = const [],
    this.originalText,
    required this.isAppropriate,
  });

  factory BroadcastMessage.fromMap(Map<String, dynamic> data) {
    return BroadcastMessage(
      messageId: data['messageId'] as String? ?? 'unknown-id',
      senderId: data['senderId'] as String? ?? 'unknown-sender',
      broadcastId: data['broadcastId'] as String? ?? 'unknown-broadcast',
      text: data['text'] as String? ?? 'No message provided',
      timestamp: data['timestamp'] is Timestamp
          ? data['timestamp'] as Timestamp
          : Timestamp.now(),
      fileUrl: data['fileUrl'] as String?,
      fileType: data['fileType'] as String?,
      fileName: data['fileName'] as String?,
      deliveredTo: List<String>.from(data['deliveredTo'] ?? []),
      readBy: List<String>.from(data['readBy'] ?? []),
      originalText: data['originalText'] as String?,
      isAppropriate: data['isAppropriate'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'broadcastId': broadcastId,
      'text': text,
      'timestamp': timestamp,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'fileName': fileName,
      'deliveredTo': deliveredTo,
      'readBy': readBy,
      'originalText': originalText,
      'isAppropriate': isAppropriate,
    };
  }
}
