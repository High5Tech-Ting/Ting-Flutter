import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RequestTile extends StatelessWidget {
  final String studentName;
  final DateTime dateTime;
  final String meetingType;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const RequestTile({
    super.key,
    required this.studentName,
    required this.dateTime,
    required this.meetingType,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        title: Text(studentName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat.yMMMMd().add_jm().format(dateTime)),
            Text("Type: ${meetingType == 'online' ? 'Online' : 'In-Person'}"),
          ],
        ),
        trailing: Wrap(
          spacing: 8,
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: onAccept,
              tooltip: 'Accept',
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: onReject,
              tooltip: 'Reject',
            ),
          ],
        ),
      ),
    );
  }
}
