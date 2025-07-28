import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ting/core/models/support_ticket_model.dart';
import 'package:ting/core/services/admin_service.dart';
import 'package:ting/shared/theme.dart';

class StatusUpdateWidget extends StatelessWidget {
  final SupportTicket ticket;
  final VoidCallback onStatusUpdated;

  const StatusUpdateWidget({
    super.key,
    required this.ticket,
    required this.onStatusUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    // Only show for admin or assigned user
    if (!AdminService.isCurrentUserAdmin() && 
        ticket.assignedTo != currentUser?.uid) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.admin_panel_settings, color: Colors.blue[700]),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Update Status',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (status) => _updateStatus(context, status),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'resolved',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Mark as Resolved'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'closed',
                child: Row(
                  children: [
                    Icon(Icons.cancel, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Mark as Closed'),
                  ],
                ),
              ),
              if (ticket.status != TicketStatus.pending)
                const PopupMenuItem(
                  value: 'pending',
                  child: Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Mark as Pending'),
                    ],
                  ),
                ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Update Status',
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, color: Colors.white),
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
      await AdminService.updateTicketStatus(ticket.ticketId, status);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ticket status updated to ${status.toUpperCase()}'),
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
