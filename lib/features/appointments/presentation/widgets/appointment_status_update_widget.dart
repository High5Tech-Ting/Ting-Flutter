import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ting/core/models/appointment_model.dart';
import 'package:ting/core/services/admin_service.dart';
import 'package:ting/core/services/appointment_service.dart';

class AppointmentStatusUpdateWidget extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback onStatusUpdated;

  const AppointmentStatusUpdateWidget({
    super.key,
    required this.appointment,
    required this.onStatusUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (!AdminService.isCurrentUserAdmin() &&
        appointment.lecturerId != currentUser?.uid) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Icon(Icons.admin_panel_settings_outlined, color: Colors.blue[700]),
          const SizedBox(width: 8),
          const Text(
            'Update Status:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: (status) => _updateStatus(context, status),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'resolved',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Mark as Resolved',
                      style: TextStyle(
                        fontFamily: "NunitoSans",
                        fontVariations: [FontVariation('wght', 500)],
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'closed',
                child: Row(
                  children: [
                    Icon(Icons.cancel, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'Mark as Closed',
                      style: TextStyle(
                        fontFamily: "NunitoSans",
                        fontVariations: [FontVariation('wght', 500)],
                      ),
                    ),
                  ],
                ),
              ),
              if (appointment.status != AppointmentStatus.pending)
                const PopupMenuItem(
                  value: 'pending',
                  child: Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        'Mark as Pending',
                        style: TextStyle(
                          fontFamily: "NunitoSans",
                          fontVariations: [FontVariation('wght', 500)],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(500.00),
                border: Border.all(color: Colors.grey.shade600, width: 1.5),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Update Status'),
                  SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, String status) async {
    try {
      AppointmentStatus appointmentStatus;
      switch (status) {
        case 'pending':
          appointmentStatus = AppointmentStatus.pending;
          break;
        case 'resolved':
          appointmentStatus = AppointmentStatus.resolved;
          break;
        case 'closed':
          appointmentStatus = AppointmentStatus.closed;
          break;
        default:
          return;
      }

      await AppointmentService.updateAppointmentStatus(appointment.appointmentId, appointmentStatus);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment status updated to ${status.toUpperCase()}'),
            backgroundColor: Colors.green,
          ),
        );
        onStatusUpdated();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
