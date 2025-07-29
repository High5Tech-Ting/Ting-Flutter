import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SlotCard extends StatelessWidget {
  final DateTime dateTime;
  final String meetingType;
  final VoidCallback onBook;

  const SlotCard({
    super.key,
    required this.dateTime,
    required this.meetingType,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(meetingType == 'online' ? Icons.videocam : Icons.location_on),
        title: Text(DateFormat.yMMMMd().add_jm().format(dateTime)),
        subtitle: Text(meetingType == 'online' ? 'Online' : 'In-Person'),
        trailing: ElevatedButton(
          onPressed: onBook,
          child: const Text('Book'),
        ),
      ),
    );
  }
}
