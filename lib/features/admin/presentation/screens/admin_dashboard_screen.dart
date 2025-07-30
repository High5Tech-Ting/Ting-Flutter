import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ting/core/services/admin_service.dart';
import 'package:ting/features/admin/presentation/widgets/student_management_tab.dart';
import 'package:ting/features/admin/presentation/widgets/lecturer_management_tab.dart';
import 'package:ting/features/admin/presentation/widgets/staff_management_tab.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkAdminAccess();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _checkAdminAccess() {
    final user = _auth.currentUser;
    if (user == null || !AdminService.isAdmin(user.uid)) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access denied. Admin privileges required.'),
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
          'Admin Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.school),
              text: 'Students',
            ),
            Tab(
              icon: Icon(Icons.person_2),
              text: 'Lecturers',
            ),
            Tab(
              icon: Icon(Icons.work),
              text: 'Staff',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          StudentManagementTab(),
          LecturerManagementTab(),
          StaffManagementTab(),
        ],
      ),
    );
  }
}
