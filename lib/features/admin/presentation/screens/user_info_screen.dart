import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ting/core/models/user_model.dart';
import 'package:ting/shared/theme.dart';

class UserInfoScreen extends StatelessWidget {
  final BaseUser user;

  const UserInfoScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${_getUserTypeDisplayName(user.userType)} Information',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture and Basic Info
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage:
                        (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                        ? NetworkImage(user.avatarUrl!)
                        : NetworkImage(
                            "https://avatar.iran.liara.run/public/?username=${user.displayName}",
                          ),
                    backgroundColor: _getUserTypeColor(user.userType),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.displayName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getUserTypeColor(user.userType),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getUserTypeDisplayName(user.userType),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // User Details Section
            _buildSectionTitle('Personal Information'),
            const SizedBox(height: 16),

            _buildInfoCard([
              _buildInfoRow(Icons.email, 'Email', user.email),
              ..._buildUserSpecificFields(),
              _buildInfoRow(
                Icons.person,
                'User Type',
                _getUserTypeDisplayName(user.userType),
              ),
            ]),

            const SizedBox(height: 24),

            // Account Status Section
            _buildSectionTitle('Account Status'),
            const SizedBox(height: 16),

            _buildInfoCard([
              _buildInfoRow(
                user.online ? Icons.circle : Icons.circle_outlined,
                'Status',
                user.online ? 'Online' : 'Offline',
                statusColor: user.online ? Colors.green : Colors.grey,
              ),
              if (user.lastSeen != null)
                _buildInfoRow(
                  Icons.access_time,
                  'Last Seen',
                  _formatLastSeen(user.lastSeen!),
                ),
              _buildInfoRow(Icons.account_circle, 'User ID', user.uid),
            ]),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppTheme.primary,
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: statusColor ?? AppTheme.primary, size: 20),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w400,
                color: statusColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildUserSpecificFields() {
    switch (user.userType.toLowerCase()) {
      case 'student':
        if (user is Student) {
          final student = user as Student;
          return [
            _buildInfoRow(Icons.badge, 'Student ID', student.studentId),
            _buildInfoRow(
              Icons.group,
              'Batch Number',
              student.batchNo.startsWith('Batch')
                  ? student.batchNo
                  : 'Batch ${student.batchNo}',
            ),
            if (student.course != null && student.course!.isNotEmpty)
              _buildInfoRow(Icons.school, 'Course', student.course!),
            if (student.academicYear != null)
              _buildInfoRow(
                Icons.calendar_today,
                'Academic Year',
                student.academicYear.toString(),
              ),
          ];
        }
        break;
      case 'lecturer':
        if (user is Lecturer) {
          final lecturer = user as Lecturer;
          return [
            _buildInfoRow(Icons.badge, 'Lecturer ID', lecturer.lecturerId),
            if (lecturer.department != null && lecturer.department!.isNotEmpty)
              _buildInfoRow(Icons.business, 'Department', lecturer.department!),
            if (lecturer.qualification != null &&
                lecturer.qualification!.isNotEmpty)
              _buildInfoRow(
                Icons.verified,
                'Qualification',
                lecturer.qualification!,
              ),
            if (lecturer.modules.isNotEmpty)
              _buildInfoRow(Icons.book, 'Modules', lecturer.modules.join(', ')),
          ];
        }
        break;
      case 'staff':
        if (user is Staff) {
          final staff = user as Staff;
          return [
            _buildInfoRow(Icons.badge, 'Staff ID', staff.staffId),
            _buildInfoRow(
              Icons.business,
              'Department',
              staff.department.displayName,
            ),
            if (staff.position != null && staff.position!.isNotEmpty)
              _buildInfoRow(Icons.work, 'Position', staff.position!),
            if (staff.supervisor != null && staff.supervisor!.isNotEmpty)
              _buildInfoRow(
                Icons.supervisor_account,
                'Supervisor',
                staff.supervisor!,
              ),
          ];
        }
        break;
    }
    return [];
  }

  String _getUserTypeDisplayName(String? userType) {
    switch (userType?.toLowerCase()) {
      case 'student':
        return 'Student';
      case 'lecturer':
        return 'Lecturer';
      case 'staff':
        return 'Staff';
      default:
        return 'User';
    }
  }

  Color _getUserTypeColor(String userType) {
    switch (userType.toLowerCase()) {
      case 'student':
        return Colors.blue;
      case 'lecturer':
        return Colors.green;
      case 'staff':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatLastSeen(dynamic lastSeen) {
    try {
      DateTime dateTime;
      if (lastSeen.runtimeType.toString().contains('Timestamp')) {
        dateTime = lastSeen.toDate();
      } else if (lastSeen is DateTime) {
        dateTime = lastSeen;
      } else {
        return 'Unknown';
      }

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} minutes ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hours ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return DateFormat('MMM dd, yyyy at HH:mm').format(dateTime);
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
