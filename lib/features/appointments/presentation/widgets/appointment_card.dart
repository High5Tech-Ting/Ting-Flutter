import 'package:flutter/material.dart';
import 'package:ting/core/models/appointment_model.dart';
import 'package:ting/core/models/user_model.dart';
import 'package:ting/core/services/appointment_service.dart';
import 'package:ting/core/services/user_service.dart';
import 'package:intl/intl.dart';

class AppointmentCard extends StatefulWidget {
  final Appointment appointment;
  final VoidCallback? onTap;

  const AppointmentCard({super.key, required this.appointment, this.onTap});

  @override
  State<AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends State<AppointmentCard> {
  String? profileImageUrl;
  String? userName;
  bool isLoading = true;
  AppUser? user;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      user = await UserService.getUserById(widget.appointment.userId);
      final profilePictureUrl = await UserService.getProfilePictureUrl(
        widget.appointment.userId,
      );

      // Priority: uploaded profile picture -> avatarUrl -> fallback
      String? finalAvatarUrl = profilePictureUrl;
      if (finalAvatarUrl == null || finalAvatarUrl.isEmpty) {
        finalAvatarUrl = user?.avatarUrl;
      }

      setState(() {
        profileImageUrl = finalAvatarUrl;
        userName = user?.displayName ?? 'User';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        profileImageUrl = null;
        userName = 'User';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = AppointmentService.currentUserId;

    final isMyAppointment = widget.appointment.userId == currentUserId;
    final isForMe = widget.appointment.lecturerId == currentUserId;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: profileImageUrl != null
                      ? NetworkImage(profileImageUrl!)
                      : NetworkImage(
                          "https://avatar.iran.liara.run/public/?username=$userName",
                        ),
                  backgroundColor: Colors.grey.shade300,
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName ?? 'User',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user?.email ?? 'email',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      Row(
                        spacing: 4.0,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey),
                          Text(
                            '${DateFormat('MMM dd').format(widget.appointment.appointmentDate)} • ${widget.appointment.timeSlot}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  _getStatusIcon(widget.appointment.status),
                  color: _getStatusColor(widget.appointment.status),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Text(
              widget.appointment.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4.0),
            Text(
              widget.appointment.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4.0),
            if (widget.appointment.location.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.appointment.location,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            if (widget.appointment.lecturerName != null &&
                widget.appointment.lecturerName!.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.person_2, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Lecturer: ${widget.appointment.lecturerName!}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8.0),
            Row(
              spacing: 8.0,
              children: [
                if (isForMe && !isMyAppointment)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'With you'.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      widget.appointment.status,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.appointment.status.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(widget.appointment.status),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: AppointmentService.canDeleteAppointment(widget.appointment)
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    _showDeleteConfirmation(context);
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
                icon: const Icon(Icons.more_vert),
              )
            : null,
        onTap: widget.onTap,
      ),
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.booked:
        return Colors.green;
      case AppointmentStatus.done:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Icons.schedule;
      case AppointmentStatus.booked:
        return Icons.check_circle;
      case AppointmentStatus.done:
        return Icons.done_all;
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Appointment'),
          content: const Text(
            'Are you sure you want to delete this appointment? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAppointment();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAppointment() async {
    try {
      await AppointmentService.deleteAppointment(
        widget.appointment.appointmentId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
