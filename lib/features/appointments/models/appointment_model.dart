class Appointment {
  final String id;
  final String lecturerId;
  final String studentId;
  final DateTime slotTime;
  final String type; // online or in_person
  final String status; // pending, accepted, rejected

  Appointment({
    required this.id,
    required this.lecturerId,
    required this.studentId,
    required this.slotTime,
    required this.type,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lecturerId': lecturerId,
      'studentId': studentId,
      'slotTime': slotTime.toIso8601String(),
      'type': type,
      'status': status,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'],
      lecturerId: map['lecturerId'],
      studentId: map['studentId'],
      slotTime: DateTime.parse(map['slotTime']),
      type: map['type'],
      status: map['status'],
    );
  }
}
