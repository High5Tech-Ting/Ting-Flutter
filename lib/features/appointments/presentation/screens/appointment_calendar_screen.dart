import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:ting/core/models/appointment_model.dart';
import 'package:ting/core/services/appointment_service.dart';
import 'package:ting/core/services/user_service.dart';
import 'package:ting/features/appointments/presentation/screens/appointment_detail_screen.dart';
import 'package:ting/shared/theme.dart';
import 'package:intl/intl.dart';

class AppointmentCalendarScreen extends StatefulWidget {
  const AppointmentCalendarScreen({super.key});

  @override
  State<AppointmentCalendarScreen> createState() => _AppointmentCalendarScreenState();
}

class _AppointmentCalendarScreenState extends State<AppointmentCalendarScreen> {
  final EventController _eventController = EventController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  @override
  void dispose() {
    _eventController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get all appointments for the current lecturer
      final allAppointments = <Appointment>[];
      
      // Get all statuses to include lecturer-created appointments and assigned appointments
      final pendingAppointments = await AppointmentService.getAppointmentsByStatus(AppointmentStatus.pending).first;
      final bookedAppointments = await AppointmentService.getAppointmentsByStatus(AppointmentStatus.booked).first;
      final doneAppointments = await AppointmentService.getAppointmentsByStatus(AppointmentStatus.done).first;
      
      allAppointments.addAll(pendingAppointments);
      allAppointments.addAll(bookedAppointments);
      allAppointments.addAll(doneAppointments);

      // Clear existing events
      _eventController.removeWhere((event) => true);

      // Convert appointments to calendar events
      for (final appointment in allAppointments) {
        final event = await _createCalendarEvent(appointment);
        if (event != null) {
          _eventController.add(event);
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading appointments: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<CalendarEventData?> _createCalendarEvent(Appointment appointment) async {
    try {
      // Parse time slot (e.g., "09:00 - 10:00")
      final timeSlotParts = appointment.timeSlot.split(' - ');
      if (timeSlotParts.length != 2) return null;

      final startTimeParts = timeSlotParts[0].split(':');
      final endTimeParts = timeSlotParts[1].split(':');
      
      // Validate time parts
      if (startTimeParts.length != 2 || endTimeParts.length != 2) return null;
      
      final startTime = DateTime(
        appointment.appointmentDate.year,
        appointment.appointmentDate.month,
        appointment.appointmentDate.day,
        int.parse(startTimeParts[0]),
        int.parse(startTimeParts[1]),
      );
      
      final endTime = DateTime(
        appointment.appointmentDate.year,
        appointment.appointmentDate.month,
        appointment.appointmentDate.day,
        int.parse(endTimeParts[0]),
        int.parse(endTimeParts[1]),
      );

      // Get student/creator name
      String creatorName = 'Unknown';
      try {
        final user = await UserService.getUserById(appointment.userId);
        creatorName = user?.displayName ?? 'Unknown User';
      } catch (e) {
        print('Error getting user name: $e');
      }

      // Determine color and display status based on appointment status
      Color eventColor;
      String statusText;
      switch (appointment.status) {
        case AppointmentStatus.pending:
          eventColor = Colors.blue;
          statusText = 'Pending';
          break;
        case AppointmentStatus.booked:
          // Show booked appointments as "Pending" in calendar (orange color)
          eventColor = Colors.orange;
          statusText = 'Pending';
          break;
        case AppointmentStatus.done:
          // Show done appointments as "Done" in calendar (green color)
          eventColor = Colors.green;
          statusText = 'Done';
          break;
      }

      return CalendarEventData(
        date: appointment.appointmentDate,
        startTime: startTime,
        endTime: endTime,
        title: appointment.title,
        description: '${appointment.description}\n\nStudent: $creatorName\nLocation: ${appointment.location}\nStatus: $statusText',
        color: eventColor,
        event: appointment, // Store the appointment object for reference
      );
    } catch (e) {
      print('Error creating calendar event: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Appointment Calendar',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAppointments,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CalendarControllerProvider(
              controller: _eventController,
              child: MonthView(
                controller: _eventController,
                // Customize the month view
                cellAspectRatio: 0.55,
                onEventTap: (event, date) {
                  _showEventDetails(context, event);
                },
                onDateLongPress: (date) {
                  _showDayEvents(context, date);
                },
                headerBuilder: (date) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Text(
                      DateFormat('MMMM yyyy').format(date),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
                weekDayBuilder: (day) {
                  final dayString = day.toString();
                  final displayText = dayString.length >= 3 
                      ? dayString.substring(0, 3).toUpperCase()
                      : dayString.toUpperCase();
                  
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      displayText,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "refresh",
            onPressed: _loadAppointments,
            backgroundColor: Colors.grey[600],
            child: const Icon(Icons.refresh, color: Colors.white),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "legend",
            onPressed: () => _showLegend(context),
            backgroundColor: AppTheme.primary,
            child: const Icon(Icons.info, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _showEventDetails(BuildContext context, CalendarEventData event) {
    final appointment = event.event as Appointment;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time: ${DateFormat('HH:mm').format(event.startTime!)} - ${DateFormat('HH:mm').format(event.endTime!)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(event.description ?? 'No description'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AppointmentDetailScreen(
                    appointmentId: appointment.appointmentId,
                  ),
                ),
              ).then((_) {
                // Refresh calendar when returning from detail screen
                _loadAppointments();
              });
            },
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }

  void _showDayEvents(BuildContext context, DateTime date) {
    final dayEvents = _eventController.getEventsOnDay(date);
    
    if (dayEvents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No appointments on ${DateFormat('MMM dd, yyyy').format(date)}'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Appointments - ${DateFormat('MMM dd, yyyy').format(date)}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: dayEvents.length,
            itemBuilder: (context, index) {
              final event = dayEvents[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: event.color,
                  radius: 8,
                ),
                title: Text(event.title),
                subtitle: Text(
                  '${DateFormat('HH:mm').format(event.startTime!)} - ${DateFormat('HH:mm').format(event.endTime!)}',
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showEventDetails(context, event);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLegend(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Calendar Legend'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLegendItem(Colors.blue, 'New Pending'),
            const SizedBox(height: 8),
            _buildLegendItem(Colors.orange, 'Booked (Pending)'),
            const SizedBox(height: 8),
            _buildLegendItem(Colors.green, 'Done (Completed)'),
            const SizedBox(height: 16),
            const Text(
              'Tap on an event to see details\nLong press on a date to see all events',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: color,
          radius: 8,
        ),
        const SizedBox(width: 12),
        Text(label),
      ],
    );
  }
}
