import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ting/core/models/appointment_model.dart';
import 'package:ting/core/services/appointment_service.dart';
import 'package:ting/core/services/admin_service.dart';
import 'package:ting/features/appointments/presentation/screens/create_appointment_screen.dart';
import 'package:ting/features/appointments/presentation/screens/appointment_detail_screen.dart';
import 'package:ting/features/appointments/presentation/screens/appointment_calendar_screen.dart';
import 'package:ting/features/appointments/presentation/widgets/appointment_card.dart';
import 'package:ting/shared/theme.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLecturer = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkUserType();
  }

  Future<void> _checkUserType() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data();
          final userType = userData?['userType'] as String?;
          setState(() {
            _isLecturer = userType == 'lecturer';
          });
        }
      }
    } catch (e) {
      print('Error checking user type: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Appointments',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isLecturer)
            IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AppointmentCalendarScreen(),
                  ),
                );
              },
              tooltip: 'Calendar View',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Booked'),
            Tab(text: 'Done'),
          ],
          dividerColor: Colors.transparent,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AppointmentList(status: AppointmentStatus.pending),
          _AppointmentList(status: AppointmentStatus.booked),
          _AppointmentList(status: AppointmentStatus.done),
        ],
      ),
      floatingActionButton: _isLecturer 
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: "calendar",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AppointmentCalendarScreen(),
                      ),
                    );
                  },
                  backgroundColor: Colors.grey[600],
                  child: const Icon(Icons.calendar_month, color: Colors.white),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: "create",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CreateAppointmentScreen()),
                    );
                  },
                  backgroundColor: AppTheme.primary,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            )
          : FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateAppointmentScreen()),
                );
              },
              backgroundColor: AppTheme.primary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }
}

class _AppointmentList extends StatelessWidget {
  final AppointmentStatus status;

  const _AppointmentList({required this.status});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Appointment>>(
      stream: AdminService.isCurrentUserAdmin()
          ? AppointmentService.getAllAppointmentsByStatus(status)
          : AppointmentService.getAppointmentsByStatus(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final appointments = snapshot.data ?? [];

        if (appointments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${status.name} appointments',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your ${status.name} appointments will appear here',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: AppointmentCard(
                appointment: appointments[index],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AppointmentDetailScreen(appointmentId: appointments[index].appointmentId),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
