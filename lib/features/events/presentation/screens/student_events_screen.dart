import 'package:flutter/material.dart';
import 'package:ting/core/services/event_service.dart';
import 'package:ting/core/models/event_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ting/features/events/presentation/widgets/event_card.dart';
import 'package:ting/shared/theme.dart';

class StudentEventsScreen extends StatelessWidget {
  final String batchNo;
  const StudentEventsScreen({super.key, required this.batchNo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Events', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: EventService.getBatchEvents(batchNo),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          }
          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return const Center(child: Text('No events for your batch.'));
          }
          return ListView.builder(
            itemCount: events.length,
            padding: const EdgeInsets.all(8.0),
            itemBuilder: (context, index) {
              final event = events[index];
              final now = DateTime.now();
              final isExpired = now.isAfter(event.endTime);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: EventCard(
                  event: event,
                  expired: isExpired,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentEventInfoScreen(event: event),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class StudentEventInfoScreen extends StatelessWidget {
  final EventModel event;
  const StudentEventInfoScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isExpired = now.isAfter(event.endTime);
    final timeLeft = isExpired ? 'Expired' : _formatDuration(event.endTime.difference(now));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Info', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card-like info section with title and status
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isExpired ? Colors.red.withOpacity(0.15) : Colors.blue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isExpired ? 'EXPIRED' : 'ACTIVE',
                          style: TextStyle(
                            color: isExpired ? Colors.red : Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(event.description, style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text('Date: ${event.date.toLocal().toString().split(' ')[0]}'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text('Start: ${_formatTime(event.startTime)}'),
                      const SizedBox(width: 12),
                      Text('End: ${_formatTime(event.endTime)}'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.group, size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text('Batch: ${event.batchNo}'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(isExpired ? Icons.timer_off : Icons.timer, size: 18, color: isExpired ? Colors.red : Colors.blue),
                      const SizedBox(width: 6),
                      Text('Time left: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(timeLeft, style: TextStyle(color: isExpired ? Colors.red : Colors.blue)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
