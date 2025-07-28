import 'package:flutter/material.dart';
import 'package:ting/core/models/support_ticket_model.dart';
import 'package:ting/core/services/admin_service.dart';
import 'package:ting/shared/theme.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUsers();
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
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assignment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            if (widget.ticket.assignedTo != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assigned to: ${widget.ticket.assignedToName}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                          if (widget.ticket.assignedAt != null)
                            Text(
                              'Assigned on: ${_formatDate(widget.ticket.assignedAt!.toDate())}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[600],
                              ),
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
              ),
            ] else if (AdminService.isCurrentUserAdmin()) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_outline, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Not assigned yet',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _showAssignDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Assign'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
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
