import 'package:cloud_firestore/cloud_firestore.dart';

enum TicketStatus { pending, resolved, closed }

class SupportTicket {
  final String ticketId;
  final String userId;
  final String title;
  final String description;
  final String? imageUrl;
  final TicketStatus status;
  final Timestamp createdAt;
  final Timestamp? updatedAt;
  final String? assignedTo;
  final String? assignedToName;
  final Timestamp? assignedAt;
  final List<TicketMessage> messages;

  SupportTicket({
    required this.ticketId,
    required this.userId,
    required this.title,
    required this.description,
    this.imageUrl,
    this.status = TicketStatus.pending,
    required this.createdAt,
    this.updatedAt,
    this.assignedTo,
    this.assignedToName,
    this.assignedAt,
    this.messages = const [],
  });

  factory SupportTicket.fromMap(Map<String, dynamic> data, String ticketId) {
    return SupportTicket(
      ticketId: ticketId,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      status: _parseStatus(data['status'] as String?),
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
      assignedTo: data['assignedTo'] as String?,
      assignedToName: data['assignedToName'] as String?,
      assignedAt: data['assignedAt'] as Timestamp?,
      messages: [], // Messages are loaded separately
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'status': status.name,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'assignedAt': assignedAt,
    };
  }

  static TicketStatus _parseStatus(String? status) {
    switch (status) {
      case 'pending':
        return TicketStatus.pending;
      case 'resolved':
        return TicketStatus.resolved;
      case 'closed':
        return TicketStatus.closed;
      default:
        return TicketStatus.pending;
    }
  }

  SupportTicket copyWith({
    String? ticketId,
    String? userId,
    String? title,
    String? description,
    String? imageUrl,
    TicketStatus? status,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    String? assignedTo,
    String? assignedToName,
    Timestamp? assignedAt,
    List<TicketMessage>? messages,
  }) {
    return SupportTicket(
      ticketId: ticketId ?? this.ticketId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      assignedAt: assignedAt ?? this.assignedAt,
      messages: messages ?? this.messages,
    );
  }
}

class TicketMessage {
  final String messageId;
  final String ticketId;
  final String senderId;
  final String senderName;
  final String message;
  final bool isFromAdmin;
  final Timestamp createdAt;

  TicketMessage({
    required this.messageId,
    required this.ticketId,
    required this.senderId,
    required this.senderName,
    required this.message,
    this.isFromAdmin = false,
    required this.createdAt,
  });

  factory TicketMessage.fromMap(Map<String, dynamic> data, String messageId) {
    return TicketMessage(
      messageId: messageId,
      ticketId: data['ticketId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? 'Unknown',
      message: data['message'] as String? ?? '',
      isFromAdmin: data['isFromAdmin'] as bool? ?? false,
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ticketId': ticketId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'isFromAdmin': isFromAdmin,
      'createdAt': createdAt,
    };
  }
}
