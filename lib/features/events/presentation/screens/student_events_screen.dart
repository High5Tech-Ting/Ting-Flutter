import 'package:flutter/material.dart';
import 'package:ting/core/services/event_service.dart';
import 'package:ting/core/models/event_model.dart';
import 'package:ting/features/events/presentation/widgets/event_card.dart';
import 'package:ting/shared/widgets/primary_button.dart';
import 'package:ting/services/widget_service.dart';

class StudentEventsScreen extends StatelessWidget {
  final String batchNo;
  const StudentEventsScreen({super.key, required this.batchNo});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Events', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Expired'),
            ],
          ),
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
            final now = DateTime.now();
            final active = events
                .where((e) => now.isBefore(e.endTime))
                .toList();
            final expired = events
                .where((e) => now.isAfter(e.endTime))
                .toList();
            return TabBarView(
              children: [
                _buildEventList(context, active, false),
                _buildEventList(context, expired, true),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEventList(
    BuildContext context,
    List<EventModel> events,
    bool expired,
  ) {
    if (events.isEmpty) {
      return Center(
        child: Text(expired ? 'No expired events.' : 'No active events.'),
      );
    }
    return ListView.builder(
      itemCount: events.length,
      padding: const EdgeInsets.all(8.0),
      itemBuilder: (context, index) {
        final event = events[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: EventCard(
            event: event,
            expired: expired,
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
  }
}

class StudentEventInfoScreen extends StatelessWidget {
  final EventModel event;
  const StudentEventInfoScreen({super.key, required this.event});

  Future<void> _addEventToHomeScreen(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Set the event in the widget service
      await WidgetService.setCurrentEvent(event);

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event added to home screen widget successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Close loading dialog if open
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add event to widget: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isExpired = now.isAfter(event.endTime);
    final timeLeft = isExpired
        ? 'Expired'
        : _formatDuration(event.endTime.difference(now));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Info', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
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
                      isExpired
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'EXPIRED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'ACTIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(event.description, style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Date: ${event.date.toLocal().toString().split(' ')[0]}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text('Start: ${_formatTime(event.startTime)}'),
                      const SizedBox(width: 12),
                      Text('End: ${_formatTime(event.endTime)}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.group, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text('Batch: ${event.batchNo}'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.timer, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Time left: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        timeLeft,
                        style: TextStyle(
                          color: isExpired ? Colors.red : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  if (!isExpired) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        onPressed: () async {
                          await _addEventToHomeScreen(context);
                        },
                        child: const Text('Add event to home screen'),
                      ),
                    ),
                  ],
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
