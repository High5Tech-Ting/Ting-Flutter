import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:ting/Components/services/group_chat_service.dart';
import 'package:ting/Components/models/group_model.dart';
import 'package:ting/features/chat/presentation/widgets/message_bubble.dart';
import 'package:ting/shared/theme.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String? groupImageUrl;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    this.groupImageUrl,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';
  String? _replyToMessageId;
  String? _replyToText;
  String? _replyToSenderId;

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
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

  void _markMessagesAsRead() async {
    await GroupChatService.markGroupMessagesAsRead(widget.groupId);
  }

  void _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final messageText = _messageController.text;
    _messageController.clear();

    try {
      await GroupChatService.sendGroupMessage(
        groupId: widget.groupId,
        messageText: messageText,
        replyToMessageId: _replyToMessageId,
        replyToText: _replyToText,
        replyToSenderId: _replyToSenderId,
      );

      setState(() {
        _replyToMessageId = null;
        _replyToText = null;
        _replyToSenderId = null;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
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

  Future<String> _getUserName(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['displayName'] ?? 'Unknown User';
      }
    } catch (e) {
      print('Error getting user name: $e');
    }
    return 'Unknown User';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 32.0,
        backgroundColor: AppTheme.primary100,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.primary,
              backgroundImage: widget.groupImageUrl != null
                  ? NetworkImage(widget.groupImageUrl!)
                  : null,
              child: widget.groupImageUrl == null
                  ? Icon(Icons.group, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.groupName,
                    style: TextStyle(fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                  FutureBuilder<GroupChat?>(
                    future: GroupChatService.getGroupById(widget.groupId),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        final memberCount = snapshot.data!.memberIds.length;
                        return Text(
                          '$memberCount members',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        );
                      }
                      return Text(
                        'Loading...',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'info':
                  // TODO: Navigate to group info screen
                  break;
                case 'leave':
                  _showLeaveGroupDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 8),
                    Text('Group Info'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Leave Group', style: TextStyle(color: Colors.red)),
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
                stream: GroupChatService.getGroupMessagesStream(widget.groupId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }

                  var messages = snapshot.data?.docs ?? [];
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });

                  List<Widget> messageWidgets = [];
                  String? lastDayLabel;

                  for (int index = 0; index < messages.length; index++) {
                    var messageData =
                        messages[index].data() as Map<String, dynamic>;
                    var timestamp = messageData['timestamp'] as Timestamp?;
                    String dayLabel = formatDayLabel(timestamp);

                    // Add day label if different from previous message
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
                    final bool isDeletedForEveryone =
                        messageData['isDeletedForEveryone'] == true;
                    final List<dynamic> rawDeletedFor =
                        messageData['deletedFor'] ?? [];
                    final List<String> deletedFor = rawDeletedFor
                        .whereType<String>()
                        .toList();

                    if (isDeletedForEveryone) {
                      messageWidgets.add(
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: isMe
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "This message was deleted",
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else if (deletedFor.contains(currentUserId)) {
                      // Skip messages deleted for current user
                    } else {
                      // Show sender name for group messages (if not current user)
                      Widget messageWidget = MessageBubble(
                        message: text,
                        isSender: isMe,
                        time: formatTime(timestamp),
                        statusIcon: null, // Group messages don't show read status
                        conversationId: widget.groupId,
                        messageId: messageData['messageId']?.toString() ?? '',
                        senderId: senderId,
                        currentUserId: currentUserId,
                        isDeletedForEveryone: isDeletedForEveryone,
                        deletedFor: deletedFor,
                        replyToMessageId: messageData['replyToMessageId']?.toString(),
                        replyToText: messageData['replyToText']?.toString(),
                        replyToSenderId: messageData['replyToSenderId']?.toString(),
                        onReply: (replyToMessageId, replyToText, replyToSenderId) {
                          setState(() {
                            _replyToMessageId = replyToMessageId;
                            _replyToText = replyToText;
                            _replyToSenderId = replyToSenderId;
                          });
                        },
                      );

                      // Add sender name for group messages
                      if (!isMe) {
                        messageWidgets.add(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 16, bottom: 4),
                                child: FutureBuilder<String>(
                                  future: _getUserName(senderId),
                                  builder: (context, snapshot) {
                                    return Text(
                                      snapshot.data ?? 'Loading...',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              messageWidget,
                            ],
                          ),
                        );
                      } else {
                        messageWidgets.add(messageWidget);
                      }
                    }
                  }

                  return ListView(
                    controller: _scrollController,
                    children: messageWidgets,
                  );
                },
              ),
            ),
          ),
          if (_replyToText != null)
            Container(
              color: Colors.grey[200],
              padding: EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<String>(
                          future: _getUserName(_replyToSenderId ?? ''),
                          builder: (context, snapshot) {
                            return Text(
                              'Replying to ${snapshot.data ?? 'Unknown'}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppTheme.primary,
                              ),
                            );
                          },
                        ),
                        Text(
                          _replyToText!,
                          style: TextStyle(fontStyle: FontStyle.italic),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _replyToMessageId = null;
                        _replyToText = null;
                        _replyToSenderId = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          // Message input field
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    maxLines: 5,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  style: ButtonStyle(
                    iconColor: WidgetStatePropertyAll(AppTheme.surface),
                    backgroundColor: WidgetStatePropertyAll(AppTheme.primary),
                    padding: WidgetStatePropertyAll(EdgeInsets.all(10)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLeaveGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Leave Group'),
        content: Text('Are you sure you want to leave this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await GroupChatService.leaveGroup(widget.groupId);
                Navigator.pop(context); // Go back to groups list
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Left group successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error leaving group: $e')),
                );
              }
            },
            child: Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
