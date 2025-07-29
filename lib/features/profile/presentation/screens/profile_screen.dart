import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ting/features/auth/data/auth_repository.dart';
import 'package:ting/features/profile/presentation/widgets/profile_header.dart';
import 'package:ting/shared/widgets/custom_clip_path.dart';
import 'package:ting/features/appointments/presentation/screens/calendar_view_screen.dart'; //lect view checked
import 'package:ting/features/appointments/presentation/screens/student_book_slot_screen.dart';



class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    user = AuthRepository.currentUser();
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
                userName: user?.displayName ?? 'User Name',
                userEmail: user?.email ?? 'Email',
                studentId: user?.uid ?? 'Student ID',
                batchNo: 'Batch 2023',
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
              title: const Text('Calendar'),
              onTap: () {},
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
            ),
            ListTile(
              leading: const Icon(Icons.schedule_outlined),
              title: const Text('Appointment Schedule'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    //builder: (context) => const CalendarViewScreen(),
                    builder: (context) => const StudentBookSlotScreen(),
                  ),
                );
              },
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),

            ListTile(
              leading: const Icon(Icons.support_agent_outlined),
              title: const Text('Support Tickets'),
              onTap: () {},
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
