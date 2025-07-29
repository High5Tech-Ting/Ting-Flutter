import 'package:flutter/material.dart';
import 'package:ting/features/chat/presentation/widgets/message_bubble.dart';
import 'package:ting/features/chat/presentation/widgets/chat_input_widget.dart';
import 'package:ting/shared/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ting/core/services/notification_service.dart';
import 'package:ting/shared/services/attachment_service.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String userName;
  final String lastActiveTime;
  final String avatarUrl;
  final bool isOnline;
  final String? conversationId;
  final String? otherUserId;

  const ChatScreen({
    super.key,
    required this.userName,
    required this.lastActiveTime,
    required this.avatarUrl,
    required this.isOnline,
    this.conversationId,
    this.otherUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  bool _isSending = false;

  String get currentUserId => _auth.currentUser?.uid ?? '';
  String get otherUserId => widget.otherUserId ?? '';
  String get conversationId =>
      widget.conversationId ?? ([currentUserId, otherUserId]..sort()).join('_');

  String? _replyToMessageId;
  String? _replyToText;
  String? _replyToSenderId;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTypingChanged);
    _updateUserStatus(true);
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
    await _firestore.collection('conversations').doc(conversationId).set({
      'unreadMessages': {currentUserId: 0},
    }, SetOptions(merge: true));

    QuerySnapshot unreadMessages = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('read', isEqualTo: false)
        .get();

    WriteBatch batch = _firestore.batch();
    for (var doc in unreadMessages.docs) {
      final messageData = doc.data() as Map<String, dynamic>?;
      if (messageData?['senderId'] != currentUserId) {
        batch.update(doc.reference, {
          'read': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
    }
    if (unreadMessages.docs.isNotEmpty) {
      await batch.commit();
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTypingChanged);
    setTypingStatus(false);
    _updateUserStatus(false);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _updateUserStatus(bool isOnline) async {
    await _firestore.collection('users').doc(currentUserId).update({
      'online': isOnline,
      'lastSeen': isOnline ? null : FieldValue.serverTimestamp(),
    });
  }

  void _onTypingChanged() {
    bool isCurrentlyTyping = _messageController.text.isNotEmpty;
    if (_isTyping != isCurrentlyTyping) {
      _isTyping = isCurrentlyTyping;
      setTypingStatus(_isTyping);
    }
  }

  Stream<QuerySnapshot> getMessagesStream() {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  void setTypingStatus(bool isTyping) async {
    await _firestore.collection('conversations').doc(conversationId).set({
      'typingUsers': isTyping ? {currentUserId: true} : {currentUserId: false},
      'participants': [currentUserId, otherUserId],
    }, SetOptions(merge: true));
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

  Widget getMessageStatusIcon(Map<String, dynamic> messageData) {
    final isMe = messageData['senderId'] == currentUserId;
    if (!isMe) return const SizedBox.shrink();
    if (messageData['read'] == true) {
      return const Icon(Icons.done_all, size: 16, color: Colors.white);
    } else if (messageData['delivered'] == true) {
      return const Icon(Icons.done_all, size: 16, color: Colors.grey);
    } else {
      return const Icon(Icons.done, size: 16, color: Colors.grey);
    }
  }

  // New unified send message method
  void _sendMessage(String messageText, AttachmentFile? attachment) async {
    if (messageText.isEmpty && attachment == null) return;

    String senderId = currentUserId;
    String receiverId = otherUserId;
    setTypingStatus(false);

    setState(() {
      _isSending = true;
    });

    try {
      String? fileUrl;
      String? fileType;
      String? fileName;

      if (attachment != null) {
        // Use AttachmentService to upload file
        fileUrl = await AttachmentService.uploadFile(
          file: attachment.file,
          fileName: attachment.fileName,
          fileType: attachment.fileType,
          folderPath: 'chat/$conversationId',
          customMetadata: {
            'senderId': senderId,
            'conversationId': conversationId,
          },
        );

        if (fileUrl == null) {
          throw Exception('Failed to upload file');
        }

        fileType = attachment.fileType;
        fileName = attachment.fileName;
      }

      final messageRef = _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc();

      await messageRef.set({
        'messageId': messageRef.id,
        'senderId': senderId,
        'receiverId': receiverId,
        'text': messageText,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'sent',
        'delivered': false,
        'deliveredAt': null,
        'read': false,
        'readAt': null,
        'deletedFor': [],
        'isDeletedForEveryone': false,
        'replyToMessageId': _replyToMessageId,
        'replyToText': _replyToText,
        'replyToSenderId': _replyToSenderId,
        'fileUrl': fileUrl,
        'fileType': fileType,
        'fileName': fileName,
      });

      DocumentSnapshot convDoc = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .get();

      Map<String, dynamic> unreadMessages = {};
      if (convDoc.exists) {
        final data = convDoc.data() as Map<String, dynamic>?;
        unreadMessages = data?['unreadMessages'] as Map<String, dynamic>? ?? {};
      }

      int currentUnread = unreadMessages[receiverId] as int? ?? 0;
      unreadMessages[receiverId] = currentUnread + 1;
      unreadMessages[senderId] = 0;

      String lastMessagePreview = messageText.isNotEmpty
          ? messageText
          : '${fileType?.toUpperCase() ?? 'File'} attachment';

      await _firestore.collection('conversations').doc(conversationId).set({
        'lastMessage': lastMessagePreview,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'participants': [currentUserId, receiverId],
        'unreadMessages': unreadMessages,
      }, SetOptions(merge: true));

      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.email != null) {
        await NotificationService.instance.sendMessageNotification(
          receiverId: receiverId,
          messageText: lastMessagePreview,
          senderEmail: currentUser.email!,
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
              backgroundImage: widget.avatarUrl.isNotEmpty
                  ? NetworkImage(widget.avatarUrl)
                  : NetworkImage(
                      "https://avatar.iran.liara.run/public/?username=${widget.userName}",
                    ),
              backgroundColor: Colors.grey[300],
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.userName, style: TextStyle(fontSize: 20)),
                StreamBuilder<DocumentSnapshot>(
                  stream: _firestore
                      .collection('users')
                      .doc(otherUserId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data == null) {
                      return const Text(
                        'Loading...',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      );
                    }
                    final userData =
                        snapshot.data!.data() as Map<String, dynamic>?;
                    final isOnline = userData?['online'] ?? false;
                    final lastSeen = userData?['lastSeen'] as Timestamp?;
                    return isOnline
                        ? const Text(
                            'Online',
                            style: TextStyle(color: Colors.green, fontSize: 14),
                          )
                        : Text(
                            lastSeen != null
                                ? 'Last active: ${formatTime(lastSeen)}'
                                : 'Offline',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          );
                  },
                ),
              ],
            ),
          ],
        ),
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
                stream: getMessagesStream(),
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

                    if (!isMe && messageData['read'] == false) {
                      _firestore
                          .collection('conversations')
                          .doc(conversationId)
                          .collection('messages')
                          .doc(messageData['messageId']?.toString())
                          .update({
                            'read': true,
                            'readAt': FieldValue.serverTimestamp(),
                            'status': 'read',
                          });
                    }

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
                    } else {
                      messageWidgets.add(
                        MessageBubble(
                          message: text,
                          isSender: isMe,
                          time: formatTime(timestamp),
                          statusIcon: getMessageStatusIcon(messageData),
                          conversationId: conversationId,
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
                        ),
                      );
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
          ),
        ],
      ),
    );
  }
}
