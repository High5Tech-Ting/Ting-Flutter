import 'package:flutter/material.dart';
import 'package:ting/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:ting/shared/theme.dart';

class ProfileHeader extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String studentId;
  final String batchNo;
  final String? userType;

  const ProfileHeader({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.studentId,
    required this.batchNo,
    this.userType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.primary,
      padding: const EdgeInsets.fromLTRB(16, 44, 16, 44),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: ProfileAvatar(size: 100, isEditable: true),
          ),
          Text(
            userName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            userEmail,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          // Student ID and Batch No - only show for students
          if (userType?.toLowerCase() == 'student') ...[
            const SizedBox(height: 4),
            Text(
              "Student ID: $studentId",
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              "Batch No: $batchNo",
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}
