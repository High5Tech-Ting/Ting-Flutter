import 'package:flutter/material.dart';
import 'package:ting/core/models/event_model.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap;
  final bool expired;
  const EventCard({super.key, required this.event, this.onTap, this.expired = false});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeLeft = expired ? 'Expired' : _formatDuration(event.endTime.difference(now));
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 3,
      color: expired ? Colors.red.shade50 : Colors.blue.shade50,
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          expired ? Icons.event_busy : Icons.event_available,
          color: expired ? Colors.red : Colors.blue,
          size: 36,
        ),
        title: Text(
          event.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: expired ? Colors.red : Colors.blue,
            fontSize: 18,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(event.description, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text('Batch: ${event.batchNo}'),
            Text('Ends in: $timeLeft'),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: expired ? Colors.red : Colors.blue, size: 18),
        isThreeLine: true,
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return 'Expired';
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    if (days > 0) return '${days}d ${hours}h';
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}
