import 'package:flutter/material.dart';
import 'package:ting/core/models/support_ticket_model.dart';
import 'package:ting/core/models/user_model.dart';
import 'package:ting/core/services/support_ticket_service.dart';
import 'package:ting/core/services/admin_service.dart';
import 'package:ting/core/services/user_service.dart';
import 'package:intl/intl.dart';

class TicketCard extends StatefulWidget {
  final SupportTicket ticket;
  final VoidCallback? onTap;

  const TicketCard({super.key, required this.ticket, this.onTap});

  @override
  State<TicketCard> createState() => _TicketCardState();
}

class _TicketCardState extends State<TicketCard> {
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
      user = await UserService.getUserById(widget.ticket.userId);
      final profilePictureUrl = await UserService.getProfilePictureUrl(
        widget.ticket.userId,
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
    final currentUserId = AdminService.isCurrentUserAdmin()
        ? AdminService.adminUserId
        : SupportTicketService.currentUserId;

    final isAssignedToMe = widget.ticket.assignedTo == currentUserId;
    final isMyTicket = widget.ticket.userId == currentUserId;

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
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey,
                          ),
                          Text(
                            _formatDate(widget.ticket.createdAt.toDate()),
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
                  _getStatusIcon(widget.ticket.status),
                  color: _getStatusColor(widget.ticket.status),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Text(
              widget.ticket.title,
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
              widget.ticket.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8.0),
            Row(
              spacing: 8.0,
              children: [
                if (isAssignedToMe && !isMyTicket)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Assigned to you'.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[800],
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
                      widget.ticket.status,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.ticket.status.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(widget.ticket.status),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: widget.onTap,
      ),
    );
  }

  Color _getStatusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.pending:
        return Colors.orange;
      case TicketStatus.resolved:
        return Colors.green;
      case TicketStatus.closed:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(TicketStatus status) {
    switch (status) {
      case TicketStatus.pending:
        return Icons.schedule;
      case TicketStatus.resolved:
        return Icons.check_circle;
      case TicketStatus.closed:
        return Icons.cancel;
    }
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(dateTime);
    } else {
      return DateFormat('MMM dd').format(dateTime);
    }
  }
}
