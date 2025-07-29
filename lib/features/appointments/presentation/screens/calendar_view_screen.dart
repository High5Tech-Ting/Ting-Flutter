import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class CalendarViewScreen extends StatefulWidget {
  const CalendarViewScreen({super.key});

  @override
  State<CalendarViewScreen> createState() => _CalendarViewScreenState();
}

class _CalendarViewScreenState extends State<CalendarViewScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, List<Map<String, dynamic>>> appointmentMap = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchConfirmedAppointments();
  }

  void _fetchConfirmedAppointments() {
    // TODO: Replace with Firebase call
    List<Map<String, dynamic>> appointments = [
      {
        'studentName': 'Savindu',
        'dateTime': DateTime.now().add(const Duration(days: 1, hours: 2)),
        'type': 'online',
      },
      {
        'studentName': 'Nethmi',
        'dateTime': DateTime.now().add(const Duration(days: 2, hours: 3)),
        'type': 'in_person',
      },
    ];

    for (var apt in appointments) {
      DateTime date = DateTime(apt['dateTime'].year, apt['dateTime'].month, apt['dateTime'].day);
      appointmentMap.putIfAbsent(date, () => []).add(apt);
    }

    setState(() {});
  }

  List<Map<String, dynamic>> _getAppointmentsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return appointmentMap[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final selectedAppointments = _getAppointmentsForDay(_selectedDay!);

    return Scaffold(
      appBar: AppBar(title: const Text('My Appointments Calendar')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            onFormatChanged: (format) => setState(() => _calendarFormat = format),
            eventLoader: _getAppointmentsForDay,
            calendarStyle: const CalendarStyle(
              markerDecoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: selectedAppointments.isEmpty
                ? const Center(child: Text('No appointments on this day.'))
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: selectedAppointments.length,
              itemBuilder: (context, index) {
                final apt = selectedAppointments[index];
                final dateTime = apt['dateTime'] as DateTime;
                return Card(
                  child: ListTile(
                    title: Text(apt['studentName']),
                    subtitle: Text(DateFormat.jm().format(dateTime)),
                    trailing: Text(apt['type'] == 'online' ? 'Online' : 'In-Person'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
