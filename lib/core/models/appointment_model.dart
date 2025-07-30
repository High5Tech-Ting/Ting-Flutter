import 'package:cloud_firestore/cloud_firestore.dart';

enum AppointmentStatus { pending, resolved, closed }

class Appointment {
  final String appointmentId;
  final String userId;
  final String title;
  final String description;
  final String? lecturerId;
  final String? lecturerName;
  final DateTime appointmentDate;
  final String timeSlot; // e.g., "09:00 - 10:00"
  final String location;
  final AppointmentStatus status;
  final Timestamp createdAt;
  final Timestamp? updatedAt;
  final List<AppointmentMessage> messages;

  Appointment({
    required this.appointmentId,
    required this.userId,
    required this.title,
    required this.description,
    this.lecturerId,
    this.lecturerName,
    required this.appointmentDate,
    required this.timeSlot,
    required this.location,
    this.status = AppointmentStatus.pending,
    required this.createdAt,
    this.updatedAt,
    this.messages = const [],
  });

  factory Appointment.fromMap(Map<String, dynamic> data, String appointmentId) {
    return Appointment(
      appointmentId: appointmentId,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      lecturerId: data['lecturerId'] as String?,
      lecturerName: data['lecturerName'] as String?,
      appointmentDate: (data['appointmentDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timeSlot: data['timeSlot'] as String? ?? '',
      location: data['location'] as String? ?? '',
      status: _parseStatus(data['status'] as String?),
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
      messages: [], // Messages are loaded separately
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'lecturerId': lecturerId,
      'lecturerName': lecturerName,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'timeSlot': timeSlot,
      'location': location,
      'status': status.name,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
    };
  }

  static AppointmentStatus _parseStatus(String? status) {
    switch (status) {
      case 'pending':
        return AppointmentStatus.pending;
      case 'resolved':
        return AppointmentStatus.resolved;
      case 'closed':
        return AppointmentStatus.closed;
      default:
        return AppointmentStatus.pending;
    }
  }

  Appointment copyWith({
    String? appointmentId,
    String? userId,
    String? title,
    String? description,
    String? lecturerId,
    String? lecturerName,
    DateTime? appointmentDate,
    String? timeSlot,
    String? location,
    AppointmentStatus? status,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    List<AppointmentMessage>? messages,
  }) {
    return Appointment(
      appointmentId: appointmentId ?? this.appointmentId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      lecturerId: lecturerId ?? this.lecturerId,
      lecturerName: lecturerName ?? this.lecturerName,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      timeSlot: timeSlot ?? this.timeSlot,
      location: location ?? this.location,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
    );
  }
}

class AppointmentMessage {
  final String messageId;
  final String appointmentId;
  final String senderId;
  final String senderName;
  final String message;
  final bool isFromLecturer;
  final Timestamp createdAt;

  AppointmentMessage({
    required this.messageId,
    required this.appointmentId,
    required this.senderId,
    required this.senderName,
    required this.message,
    this.isFromLecturer = false,
    required this.createdAt,
  });

  factory AppointmentMessage.fromMap(Map<String, dynamic> data, String messageId) {
    return AppointmentMessage(
      messageId: messageId,
      appointmentId: data['appointmentId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? 'Unknown',
      message: data['message'] as String? ?? '',
      isFromLecturer: data['isFromLecturer'] as bool? ?? false,
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appointmentId': appointmentId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'isFromLecturer': isFromLecturer,
      'createdAt': createdAt,
    };
  }
}
