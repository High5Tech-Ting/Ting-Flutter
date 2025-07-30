import 'package:flutter/material.dart';
import 'package:ting/core/models/user_model.dart';
import 'package:ting/features/admin/presentation/screens/user_info_screen.dart';

class UserListItem extends StatelessWidget {
  final BaseUser appUser;
  final String userType;
  final VoidCallback? onDelete;

  const UserListItem({
    Key? key,
    required this.appUser,
    required this.userType,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserInfoScreen(user: appUser),
            ),
          );
        },
        leading: CircleAvatar(
          radius: 20,
          backgroundImage: (appUser.avatarUrl != null && appUser.avatarUrl!.isNotEmpty)
              ? NetworkImage(appUser.avatarUrl!)
              : NetworkImage(
                  "https://avatar.iran.liara.run/public/?username=${appUser.displayName}",
                ),
          backgroundColor: _getUserTypeColor(userType),
        ),
        title: Text(
          appUser.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(appUser.email),
            ..._buildUserSpecificSubtitle(),
          ],
        ),
        trailing: onDelete != null
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    onDelete!();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  List<Widget> _buildUserSpecificSubtitle() {
    switch (userType.toLowerCase()) {
      case 'student':
        if (appUser is Student) {
          final student = appUser as Student;
          return [
            if (student.studentId.isNotEmpty)
              Text(
                'Student ID: ${student.studentId}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            if (student.batchNo.isNotEmpty)
              Text(
                'Batch: ${student.batchNo.startsWith('Batch') ? student.batchNo : 'Batch ${student.batchNo}'}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ];
        }
        break;
      case 'lecturer':
        if (appUser is Lecturer) {
          final lecturer = appUser as Lecturer;
          return [
            if (lecturer.lecturerId.isNotEmpty)
              Text(
                'Lecturer ID: ${lecturer.lecturerId}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            if (lecturer.department != null && lecturer.department!.isNotEmpty)
              Text(
                'Department: ${lecturer.department}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ];
        }
        break;
      case 'staff':
        if (appUser is Staff) {
          final staff = appUser as Staff;
          return [
            if (staff.staffId.isNotEmpty)
              Text(
                'Staff ID: ${staff.staffId}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            Text(
              'Department: ${staff.department.displayName}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ];
        }
        break;
    }
    return [];
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
}
