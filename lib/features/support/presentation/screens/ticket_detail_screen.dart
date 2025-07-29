import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ting/core/models/support_ticket_model.dart';
import 'package:ting/core/services/support_ticket_service.dart';
import 'package:ting/core/services/admin_service.dart';
import 'package:ting/features/support/presentation/widgets/assignee_section.dart';
import 'package:ting/features/support/presentation/widgets/status_update_widget.dart';
import 'package:ting/shared/theme.dart';
import 'package:intl/intl.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final _messageController = TextEditingController();
  SupportTicket? _ticket;
  bool _isLoading = true;
  bool _isSendingMessage = false;

  @override
  void initState() {
    super.initState();
    _loadTicket();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadTicket() async {
    try {
      final ticket = await SupportTicketService.getTicketById(widget.ticketId);
      setState(() {
        _ticket = ticket;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading ticket: $e')));
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _isSendingMessage = true;
    });

    try {
      await SupportTicketService.addTicketMessage(
        ticketId: widget.ticketId,
        message: _messageController.text.trim(),
      );

      _messageController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingMessage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Loading...',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_ticket == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Ticket Not Found',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: Text(
            'Ticket not found or you don\'t have permission to view it',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ticket #${_ticket!.ticketId.substring(0, 8)}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _ticket!.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(_ticket!.status),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _ticket!.status.name.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Created: ${DateFormat('MMM dd, yyyy HH:mm').format(_ticket!.createdAt.toDate())}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          if (_ticket!.updatedAt != null)
                            Text(
                              'Last updated: ${DateFormat('MMM dd, yyyy HH:mm').format(_ticket!.updatedAt!.toDate())}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          const SizedBox(height: 12),
                          Text(
                            _ticket!.description,
                            style: const TextStyle(fontSize: 14),
                          ),
                          if (_ticket!.imageUrl != null) ...[
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () => _showImageDialog(_ticket!.imageUrl!),
                              child: Container(
                                height: 200,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _ticket!.imageUrl!,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return const Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        },
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Icon(
                                          Icons.error,
                                          color: Colors.red,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    if (_ticket!.assignedTo != null ||
                        AdminService.isCurrentUserAdmin())
                      AssigneeSection(
                        ticket: _ticket!,
                        onAssigned: () => _loadTicket(),
                      ),

                    if (AdminService.isCurrentUserAdmin() ||
                        _ticket!.assignedTo ==
                            FirebaseAuth.instance.currentUser?.uid)
                      StatusUpdateWidget(
                        ticket: _ticket!,
                        onStatusUpdated: () => _loadTicket(),
                      ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Divider(color: Colors.grey.shade300),
                    ),

                    StreamBuilder<List<TicketMessage>>(
                      stream: SupportTicketService.getTicketMessages(
                        widget.ticketId,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: Text('Error: ${snapshot.error}'),
                            ),
                          );
                        }

                        final messages = snapshot.data ?? [];

                        if (messages.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: Text('No messages yet')),
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: messages
                                .map(
                                  (message) => _MessageBubble(message: message),
                                )
                                .toList(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),

            if (_ticket!.status != TicketStatus.closed)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type your message...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _isSendingMessage ? null : _sendMessage,
                      icon: _isSendingMessage
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text('Image', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.black,
            automaticallyImplyLeading: false,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.error, color: Colors.red, size: 50),
                  );
                },
              ),
            ),
          ),
        ),
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
}

class _MessageBubble extends StatelessWidget {
  final TicketMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isFromSupport = message.isFromAdmin;

    final bool isActualAdmin =
        message.senderId == "i14bEX30GkT509oJz0pggxsRcs62";

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isFromSupport
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isFromSupport ? Colors.grey[200] : AppTheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isFromSupport)
                    Text(
                      isActualAdmin ? 'Support Team' : 'Support Assistant',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isActualAdmin
                            ? Colors.red[800]
                            : Colors.blue[800],
                      ),
                    ),
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isFromSupport ? Colors.black : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat(
                      'MMM dd, HH:mm',
                    ).format(message.createdAt.toDate()),
                    style: TextStyle(
                      fontSize: 10,
                      color: isFromSupport ? Colors.grey[500] : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
