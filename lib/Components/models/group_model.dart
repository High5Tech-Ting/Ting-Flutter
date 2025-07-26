import 'package:cloud_firestore/cloud_firestore.dart';

class GroupChat {
  final String groupId;
  final String groupName;
  final String? groupDescription;
  final String? groupImageUrl;
  final List<String> memberIds;
  final String createdBy;
  final Timestamp createdAt;
  final String? lastMessage;
  final Timestamp? lastMessageTime;
  final Map<String, int> unreadMessages;
  final List<String> admins;

  GroupChat({
    required this.groupId,
    required this.groupName,
    this.groupDescription,
    this.groupImageUrl,
    required this.memberIds,
    required this.createdBy,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadMessages = const {},
    this.admins = const [],
  });

  factory GroupChat.fromMap(Map<String, dynamic> data, String groupId) {
    return GroupChat(
      groupId: groupId,
      groupName: data['groupName'] as String? ?? 'Unnamed Group',
      groupDescription: data['groupDescription'] as String?,
      groupImageUrl: data['groupImageUrl'] as String?,
      memberIds: List<String>.from(data['memberIds'] ?? []),
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      lastMessage: data['lastMessage'] as String?,
      lastMessageTime: data['lastMessageTime'] as Timestamp?,
      unreadMessages: Map<String, int>.from(data['unreadMessages'] ?? {}),
      admins: List<String>.from(data['admins'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupName': groupName,
      'groupDescription': groupDescription,
      'groupImageUrl': groupImageUrl,
      'memberIds': memberIds,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'unreadMessages': unreadMessages,
      'admins': admins,
    };
  }

  GroupChat copyWith({
    String? groupId,
    String? groupName,
    String? groupDescription,
    String? groupImageUrl,
    List<String>? memberIds,
    String? createdBy,
    Timestamp? createdAt,
    String? lastMessage,
    Timestamp? lastMessageTime,
    Map<String, int>? unreadMessages,
    List<String>? admins,
  }) {
    return GroupChat(
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      groupDescription: groupDescription ?? this.groupDescription,
      groupImageUrl: groupImageUrl ?? this.groupImageUrl,
      memberIds: memberIds ?? this.memberIds,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadMessages: unreadMessages ?? this.unreadMessages,
      admins: admins ?? this.admins,
    );
  }
}

class GroupMessage {
  final String messageId;
  final String senderId;
  final String groupId;
  final String text;
  final Timestamp timestamp;
  final String status;
  final List<String> deletedFor;
  final bool isDeletedForEveryone;
  final String? replyToMessageId;
  final String? replyToText;
  final String? replyToSenderId;
  final String? fileUrl;
  final String? fileType;
  final String? fileName;

  GroupMessage({
    required this.messageId,
    required this.senderId,
    required this.groupId,
    required this.text,
    required this.timestamp,
    this.status = 'sent',
    this.deletedFor = const [],
    this.isDeletedForEveryone = false,
    this.replyToMessageId,
    this.replyToText,
    this.replyToSenderId,
    this.fileUrl,
    this.fileType,
    this.fileName,
  });

  factory GroupMessage.fromMap(Map<String, dynamic> data) {
    return GroupMessage(
      messageId: data['messageId'] as String? ?? 'unknown-id',
      senderId: data['senderId'] as String? ?? 'unknown-sender',
      groupId: data['groupId'] as String? ?? 'unknown-group',
      text: data['text'] as String? ?? 'No message provided',
      timestamp: data['timestamp'] is Timestamp
          ? data['timestamp'] as Timestamp
          : Timestamp.now(),
      status: data['status'] as String? ?? 'sent',
      deletedFor: List<String>.from(data['deletedFor'] ?? []),
      isDeletedForEveryone: data['isDeletedForEveryone'] ?? false,
      replyToMessageId: data['replyToMessageId'] as String?,
      replyToText: data['replyToText'] as String?,
      replyToSenderId: data['replyToSenderId'] as String?,
      fileUrl: data['fileUrl'] as String?,
      fileType: data['fileType'] as String?,
      fileName: data['fileName'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'groupId': groupId,
      'text': text,
      'timestamp': timestamp,
      'status': status,
      'deletedFor': deletedFor,
      'isDeletedForEveryone': isDeletedForEveryone,
      'replyToMessageId': replyToMessageId,
      'replyToText': replyToText,
      'replyToSenderId': replyToSenderId,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'fileName': fileName,
    };
  }
}
