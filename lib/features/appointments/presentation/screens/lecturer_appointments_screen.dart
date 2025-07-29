import 'package:flutter/material.dart';
import '../widgets/request_tile.dart'; // Make sure this widget exists
import 'package:intl/intl.dart';

import '../widgets/request_tile.dart';

class LecturerAppointmentsScreen extends StatefulWidget {
  const LecturerAppointmentsScreen({super.key});

  @override
  State<LecturerAppointmentsScreen> createState() => _LecturerAppointmentsScreenState();
}

class _LecturerAppointmentsScreenState extends State<LecturerAppointmentsScreen> {
  List<Map<String, dynamic>> pendingAppointments = [];

  @override
  void initState() {
    super.initState();
    _fetchPendingAppointments();
  }

  void _fetchPendingAppointments() async {
    // TODO: Replace with actual Firebase Function
    setState(() {
      pendingAppointments = [
        {
          'id': 'apt1',
          'studentName': 'Savindu N.',
          'dateTime': DateTime.now().add(const Duration(days: 1, hours: 2)),
          'type': 'online',
        },
        {
          'id': 'apt2',
          'studentName': 'Nethmi R.',
          'dateTime': DateTime.now().add(const Duration(days: 2, hours: 3)),
          'type': 'in_person',
        },
      ];
    });
  }

  void _respondToAppointment(String id, String action) async {
    // TODO: Replace with Firebase function
    setState(() {
      pendingAppointments.removeWhere((apt) => apt['id'] == id);
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Appointment $action'),
      backgroundColor: action == 'accepted' ? Colors.green : Colors.red,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending Appointment Requests')),
      body: pendingAppointments.isEmpty
          ? const Center(child: Text('No pending requests.'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pendingAppointments.length,
        itemBuilder: (context, index) {
          final appointment = pendingAppointments[index];
          final dateTime = appointment['dateTime'] as DateTime;

          return RequestTile(
            studentName: appointment['studentName'],
            dateTime: dateTime,
            meetingType: appointment['type'],
            onAccept: () => _respondToAppointment(appointment['id'], 'accepted'),
            onReject: () => _respondToAppointment(appointment['id'], 'rejected'),
          );
        },
      ),
    );
  }
}
