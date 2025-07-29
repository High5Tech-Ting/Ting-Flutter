import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ting/core/models/support_ticket_model.dart';
import 'package:ting/core/services/admin_service.dart';
import 'package:ting/shared/widgets/primary_button.dart';

class AssigneeSection extends StatefulWidget {
  final SupportTicket ticket;
  final VoidCallback onAssigned;

  const AssigneeSection({
    super.key,
    required this.ticket,
    required this.onAssigned,
  });

  @override
  State<AssigneeSection> createState() => _AssigneeSectionState();
}

class _AssigneeSectionState extends State<AssigneeSection> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;
  String? _selectedUserId;

  String? _assignedUserProfileImageUrl;
  String? _assignedUserEmail;
  bool _isLoadingAssignedUser = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadAssignedUserData();
  }

  @override
  void didUpdateWidget(AssigneeSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ticket.assignedTo != widget.ticket.assignedTo) {
      _loadAssignedUserData();
    }
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await AdminService.getAllUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAssignedUserData() async {
    if (widget.ticket.assignedTo == null) {
      setState(() {
        _assignedUserProfileImageUrl = null;
        _assignedUserEmail = null;
        _isLoadingAssignedUser = false;
      });
      return;
    }

    setState(() {
      _isLoadingAssignedUser = true;
    });

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.ticket.assignedTo!)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _assignedUserProfileImageUrl =
              userData['profilePictureUrl'] ?? userData['avatarUrl'];
          _assignedUserEmail = userData['email'] ?? '';
          _isLoadingAssignedUser = false;
        });
      } else {
        setState(() {
          _assignedUserProfileImageUrl = null;
          _assignedUserEmail = '';
          _isLoadingAssignedUser = false;
        });
      }
    } catch (e) {
      print('Error loading assigned user data: $e');
      setState(() {
        _assignedUserProfileImageUrl = null;
        _assignedUserEmail = '';
        _isLoadingAssignedUser = false;
      });
    }
  }

  Future<void> _assignTicket() async {
    if (_selectedUserId == null) return;

    final selectedUser = _users.firstWhere(
      (user) => user['uid'] == _selectedUserId,
    );

    try {
      await AdminService.assignTicket(
        widget.ticket.ticketId,
        _selectedUserId!,
        selectedUser['displayName'],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket assigned successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onAssigned();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error assigning ticket: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assignees',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          if (widget.ticket.assignedTo != null) ...[
            _isLoadingAssignedUser
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: _assignedUserProfileImageUrl != null
                            ? NetworkImage(_assignedUserProfileImageUrl!)
                            : NetworkImage(
                                "https://avatar.iran.liara.run/public/?username=${widget.ticket.assignedToName ?? 'User'}",
                              ),
                        backgroundColor: Colors.grey.shade300,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.ticket.assignedToName ?? 'User',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _assignedUserEmail ?? 'email',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            if (widget.ticket.assignedAt != null)
                              Text(
                                'Assigned on: ${_formatDate(widget.ticket.assignedAt!.toDate())}',
                                style: const TextStyle(fontSize: 14),
                              ),
                          ],
                        ),
                      ),
                      if (AdminService.isCurrentUserAdmin())
                        IconButton(
                          onPressed: () => _showAssignDialog(),
                          icon: const Icon(Icons.edit),
                          tooltip: 'Reassign',
                        ),
                    ],
                  ),
          ] else if (AdminService.isCurrentUserAdmin()) ...[
            PrimaryButton(
              onPressed: () => _showAssignDialog(),
              child: const Text('Assign a user to this ticket'),
            ),
          ],
        ],
      ),
    );
  }

  void _showAssignDialog() {
    _selectedUserId = null;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Assign Ticket'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select a user to assign this ticket to:'),
              const SizedBox(height: 16),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                DropdownButtonFormField<String>(
                  value: _selectedUserId,
                  hint: const Text('Select user'),
                  items: _users.map((user) {
                    return DropdownMenuItem<String>(
                      value: user['uid'],
                      child: Text(user['displayName']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedUserId = value;
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _selectedUserId != null
                  ? () {
                      Navigator.pop(context);
                      _assignTicket();
                    }
                  : null,
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
