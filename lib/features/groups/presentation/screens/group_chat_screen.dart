import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:ting/core/services/ai_engine.dart';
import 'package:ting/core/services/group_chat_service.dart';
import 'package:ting/core/models/group_model.dart';
import 'package:ting/core/services/types.dart';
import 'package:ting/features/chat/presentation/widgets/message_bubble.dart';
import 'package:ting/features/chat/presentation/widgets/chat_input_widget.dart';
import 'package:ting/shared/theme.dart';
import 'package:ting/features/groups/presentation/screens/group_info.dart';
import 'package:ting/shared/services/attachment_service.dart';

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
  bool _isSending = false;

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

  void _sendMessage(String messageText, AttachmentFile? attachment) async {
    if (messageText.isEmpty && attachment == null) return;

    setState(() {
      _isSending = true;
    });

    ModeratedMessageResponse aiResponse = await AiEngine.moderateMessage(
      messageText,
    );
    final String originalText = messageText;
    messageText = aiResponse.isAppropriate
        ? messageText
        : 'This message violates the community guidelines.';

    try {
      if (attachment != null) {
        // Send message with attachment
        await GroupChatService.sendGroupMessageWithAttachment(
          groupId: widget.groupId,
          messageText: messageText,
          file: attachment.file,
          fileName: attachment.fileName,
          fileType: attachment.fileType,
          replyToMessageId: _replyToMessageId,
          replyToText: _replyToText,
          replyToSenderId: _replyToSenderId,
          originalText: originalText,
          isAppropriate: aiResponse.isAppropriate,
        );
      } else {
        // Send text only message
        await GroupChatService.sendGroupMessage(
          groupId: widget.groupId,
          messageText: messageText,
          replyToMessageId: _replyToMessageId,
          replyToText: _replyToText,
          replyToSenderId: _replyToSenderId,
          originalText: originalText,
          isAppropriate: aiResponse.isAppropriate,
        );
      }

      setState(() {
        _replyToMessageId = null;
        _replyToText = null;
        _replyToSenderId = null;
      });

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

  void _cancelReply() {
    setState(() {
      _replyToMessageId = null;
      _replyToText = null;
      _replyToSenderId = null;
    });
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

  Future<String> _getUserName(String? userId) async {
    if (userId == null) return 'Unknown User';
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
            surfaceTintColor: AppTheme.primary100,
            onSelected: (value) {
              switch (value) {
                case 'info':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupInfo(
                        groupId: widget.groupId,
                        groupName: widget.groupName,
                        groupImageUrl: widget.groupImageUrl,
                      ),
                    ),
                  );
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
                    Text(
                      'Group Info',
                      style: TextStyle(
                        fontFamily: "NunitoSans",
                        fontVariations: [FontVariation('wght', 500)],
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'Leave Group',
                      style: TextStyle(
                        color: Colors.red,
                        fontFamily: "NunitoSans",
                        fontVariations: [FontVariation('wght', 500)],
                      ),
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
                    final isAppropriate = messageData['isAppropriate'] == true;
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
                    } else if (!isAppropriate) {
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
                                  text,
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
                    } else {
                      // Show sender name for group messages (if not current user)
                      Widget messageWidget = MessageBubble(
                        message: text,
                        isSender: isMe,
                        time: formatTime(timestamp),
                        isAppropriate: isAppropriate,
                        statusIcon:
                            null, // Group messages don't show read status
                        conversationId: widget.groupId,
                        messageId: messageData['messageId']?.toString() ?? '',
                        senderId: senderId,
                        currentUserId: currentUserId,
                        isDeletedForEveryone: isDeletedForEveryone,
                        deletedFor: deletedFor,
                        replyToMessageId: messageData['replyToMessageId']
                            ?.toString(),
                        replyToText: messageData['replyToText']?.toString(),
                        replyToSenderId: messageData['replyToSenderId']
                            ?.toString(),
                        fileUrl: messageData['fileUrl']?.toString(),
                        fileType: messageData['fileType']?.toString(),
                        fileName: messageData['fileName']?.toString(),
                        onReply:
                            (replyToMessageId, replyToText, replyToSenderId) {
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
                                padding: const EdgeInsets.only(
                                  left: 0,
                                  bottom: 0,
                                ),
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
          // Chat input widget
          ChatInputWidget(
            messageController: _messageController,
            isSending: _isSending,
            replyToText: _replyToText,
            replyToSenderId: _replyToSenderId,
            onSendMessage: _sendMessage,
            onCancelReply: _cancelReply,
            getUserName: _getUserName,
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
