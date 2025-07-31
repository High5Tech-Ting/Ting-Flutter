import 'package:flutter/material.dart';
import 'package:ting/services/widget_service.dart';

class WidgetManagementScreen extends StatefulWidget {
  const WidgetManagementScreen({super.key});

  @override
  State<WidgetManagementScreen> createState() => _WidgetManagementScreenState();
}

class _WidgetManagementScreenState extends State<WidgetManagementScreen> {
  Map<String, dynamic>? currentEvent;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentEvent();
  }

  Future<void> _loadCurrentEvent() async {
    try {
      final event = await WidgetService.getCurrentEvent();
      setState(() {
        currentEvent = event;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading current event: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeCurrentEvent() async {
    try {
      await WidgetService.removeCurrentEvent();
      setState(() {
        currentEvent = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event removed from widget successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing event: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Widget Management',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Home Screen Widget Status',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: currentEvent == null
                        ? Column(
                            children: [
                              Icon(
                                Icons.widgets_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No Event Selected',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Select an event from the events screen to display countdown on your home screen widget.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.event_available,
                                    color: Colors.green[600],
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Active Event',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                currentEvent!['title'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'End Time: ${DateTime.fromMillisecondsSinceEpoch(currentEvent!['endTime']).toString()}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _removeCurrentEvent,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Remove from Widget'),
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Instructions:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Go to Events screen and select an active event\n'
                    '2. Tap "Add event to home screen" button\n'
                    '3. Add the Event Reminder widget to your home screen\n'
                    '4. The widget will show a live countdown timer',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
    );
  }
}
