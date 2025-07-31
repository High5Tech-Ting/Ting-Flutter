import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ting/features/auth/data/auth_repository.dart';
import 'package:ting/features/profile/presentation/widgets/profile_header.dart';
import 'package:ting/features/support/presentation/screens/support_tickets_screen.dart';
import 'package:ting/features/appointments/presentation/screens/appointments_screen.dart';
import 'package:ting/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:ting/core/services/admin_service.dart';
import 'package:ting/shared/widgets/custom_clip_path.dart';
import 'package:ting/features/events/presentation/screens/student_events_screen.dart';
import 'package:ting/features/events/presentation/screens/admin_events_screen.dart';
import 'package:ting/features/widgets/widget_management_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user;
  String? studentId;
  String? displayName;
  String? batchNo;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    user = AuthRepository.currentUser();

    if (user != null) {
      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(user!.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          setState(() {
            studentId = userData?['studentId'] as String?;
            displayName = userData?['displayName'] as String?;
            batchNo = userData?['batchNo'] as String?;
          });
        }
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            ClipPath(
              clipper: CustomClipPath(),
              child: ProfileHeader(
                userName: displayName ?? 'User Name',
                userEmail: user?.email ?? 'Email',
                studentId: studentId ?? 'Not Available',
                batchNo: batchNo ?? 'Not Available',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () {},
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {},
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Appoinments'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AppointmentsScreen(),
                  ),
                );
              },
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
            ),
            ListTile(
              leading: const Icon(Icons.support_agent_outlined),
              title: const Text('Support Tickets'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SupportTicketsScreen(),
                  ),
                );
              },
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
            ),
            if (!AdminService.isAdmin(user?.uid ?? ''))
              ListTile(
                leading: const Icon(Icons.event),
                title: const Text('Events'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          StudentEventsScreen(batchNo: 'Batch 2023'),
                    ),
                  );
                },
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
            if (!AdminService.isAdmin(user?.uid ?? ''))
              ListTile(
                leading: const Icon(Icons.widgets_outlined),
                title: const Text('Widget Management'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WidgetManagementScreen(),
                    ),
                  );
                },
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
            if (AdminService.isAdmin(user?.uid ?? ''))
              ListTile(
                leading: const Icon(Icons.event),
                title: const Text('Manage Events'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminEventsScreen(),
                    ),
                  );
                },
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
            if (AdminService.isAdmin(user?.uid ?? ''))
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('Admin Dashboard'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminDashboardScreen(),
                    ),
                  );
                },
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await AuthRepository.signOut(context);
              },
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}
