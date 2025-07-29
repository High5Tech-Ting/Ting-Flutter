import 'package:flutter/material.dart';
import 'package:ting/features/appointments/presentation/screens/calendar_view_screen.dart';
import 'package:ting/features/appointments/presentation/screens/student_book_slot_screen.dart';
import 'package:ting/features/appointments/presentation/screens/lecturer_add_slot_screen.dart';
import 'package:ting/features/appointments/presentation/screens/lecturer_appointments_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/appointmentSchedule': (context) => const CalendarViewScreen(),
  '/book-appointment': (context) => const StudentBookSlotScreen(),
  '/add-slot': (context) => const LecturerAddSlotScreen(),
  '/manage-appointments': (context) => const LecturerAppointmentsScreen(),
};
