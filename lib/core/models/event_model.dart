import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final String batchNo;
  final String status; // 'active' or 'expired'
  final String createdBy;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.batchNo,
    required this.status,
    required this.createdBy,
  });

  factory EventModel.fromMap(Map<String, dynamic> data, String id) {
    return EventModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      batchNo: data['batchNo'] ?? '',
      status: data['status'] ?? 'active',
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'batchNo': batchNo,
      'status': status,
      'createdBy': createdBy,
    };
  }
}
