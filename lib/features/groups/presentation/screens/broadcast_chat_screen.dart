import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:ting/core/services/broadcast_service.dart';
import 'package:ting/features/chat/presentation/widgets/message_bubble.dart';
import 'package:ting/features/chat/presentation/widgets/chat_input_widget.dart';
import 'package:ting/shared/theme.dart';
import 'package:ting/shared/services/attachment_service.dart';
import 'broadcast_info.dart';

class BroadcastChatScreen extends StatefulWidget {
  final String broadcastId;
  final String broadcastName;

  const BroadcastChatScreen({
    super.key,
    required this.broadcastId,
    required this.broadcastName,
  });

  @override
  State<BroadcastChatScreen> createState() => _BroadcastChatScreenState();
}

class _BroadcastChatScreenState extends State<BroadcastChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage(String messageText, AttachmentFile? attachment) async {
    if (messageText.isEmpty && attachment == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      if (attachment != null) {
        // Send message with attachment
        await BroadcastService.sendBroadcastMessageWithAttachment(
          broadcastId: widget.broadcastId,
          messageText: messageText,
          file: attachment.file,
          fileName: attachment.fileName,
          fileType: attachment.fileType,
        );
      } else {
        // Send text only message
        await BroadcastService.sendBroadcastMessage(
          broadcastId: widget.broadcastId,
          messageText: messageText,
        );
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  String formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final DateTime dateTime = timestamp.toDate();
    final hour = dateTime.hour > 12
        ? dateTime.hour - 12
        : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final ampm = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute $ampm';
  }

  String formatDayLabel(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final diff = today.difference(messageDay).inDays;

    if (diff == 0) {
      return 'Today';
    } else if (diff == 1) {
      return 'Yesterday';
    } else if (dateTime.year == now.year) {
      return DateFormat('MMM d').format(dateTime);
    } else {
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.broadcastName),
            const Text(
              'Broadcast',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        backgroundColor: AppTheme.primary100,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'info') {
                _showBroadcastInfo();
              } else if (value == 'delete') {
                _showDeleteDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 8),
                    Text('Broadcast Info'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'Delete Broadcast',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/chat_background.jpg'),
                  repeat: ImageRepeat.repeat,
                  opacity: 0.25,
                ),
                color: AppTheme.primary100,
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: BroadcastService.getBroadcastMessagesStream(
                  widget.broadcastId,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading messages: ${snapshot.error}'),
                    );
                  }

                  final messages = snapshot.data?.docs ?? [];

                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broadcast_on_personal,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Start broadcasting',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Send a message to all recipients',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  List<Widget> messageWidgets = [];
                  String lastDayLabel = '';

                  for (int i = 0; i < messages.length; i++) {
                    final messageData =
                        messages[i].data() as Map<String, dynamic>;
                    final timestamp = messageData['timestamp'] as Timestamp?;
                    String dayLabel = formatDayLabel(timestamp);

                    if (dayLabel != lastDayLabel) {
                      messageWidgets.add(
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                dayLabel,
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                      lastDayLabel = dayLabel;
                    }

                    final senderId = messageData['senderId']?.toString() ?? '';
                    final text = messageData['text']?.toString() ?? '';
                    final isMe = senderId == currentUserId;

                    messageWidgets.add(
                      MessageBubble(
                        message: text,
                        isSender: isMe,
                        time: formatTime(timestamp),
                        statusIcon:
                            null, // Broadcast messages don't show read status
                        conversationId: widget.broadcastId,
                        messageId: messageData['messageId']?.toString() ?? '',
                        senderId: senderId,
                        currentUserId: currentUserId,
                        isDeletedForEveryone: false,
                        deletedFor: const [],
                        replyToMessageId: null,
                        replyToText: null,
                        replyToSenderId: null,
                        fileUrl: messageData['fileUrl']?.toString(),
                        fileType: messageData['fileType']?.toString(),
                        fileName: messageData['fileName']?.toString(),
                        onReply: null, // Disable reply for broadcast messages
                      ),
                    );
                  }

                  return ListView(
                    controller: _scrollController,
                    children: messageWidgets,
                  );
                },
              ),
            ),
          ),
          // Chat input widget
          ChatInputWidget(
            messageController: _messageController,
            isSending: _isSending,
            replyToText: null,
            replyToSenderId: null,
            onSendMessage: _sendMessage,
            onCancelReply: () {},
          ),
        ],
      ),
    );
  }

  void _showBroadcastInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BroadcastInfo(
          broadcastId: widget.broadcastId,
          broadcastName: widget.broadcastName,
        ),
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Broadcast'),
        content: const Text(
          'Are you sure you want to delete this broadcast? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await BroadcastService.deleteBroadcast(widget.broadcastId);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Broadcast deleted')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting broadcast: $e')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
