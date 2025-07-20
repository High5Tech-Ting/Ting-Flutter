import 'package:flutter/material.dart';
import 'package:ting/features/chat/presentation/widgets/message_bubble.dart';
import 'package:ting/shared/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:ting/Components/services/notification_service.dart';

import 'dart:io';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String userName;
  final String lastActiveTime;
  final String avatarUrl;
  final bool isOnline;
  // Add conversation id and participants for real chat
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

  String get currentUserId => _auth.currentUser?.uid ?? '';
  String get otherUserId => widget.otherUserId ?? '';
  String get conversationId => widget.conversationId ?? ([currentUserId, otherUserId]..sort()).join('_');

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
      'unreadMessages': {
        currentUserId: 0
      }
    }, SetOptions(merge: true));
    
    // Simplified query to avoid complex index requirements
    QuerySnapshot unreadMessages = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('read', isEqualTo: false)
        .get();
    
    WriteBatch batch = _firestore.batch();
    for (var doc in unreadMessages.docs) {
      final messageData = doc.data() as Map<String, dynamic>?;
      // Only mark messages as read if they're from other users
      if (messageData?['senderId'] != currentUserId) {
        batch.update(doc.reference, {'read': true, 'readAt': FieldValue.serverTimestamp()});
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

  void sendMessage() async {
    if (_messageController.text.isEmpty) return;
    String messageText = _messageController.text;
    String senderId = currentUserId;
    String receiverId = otherUserId;
    setTypingStatus(false);
    final messageRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc();
    await messageRef.set({
      'messageId': messageRef.id, // instead of 'id'
      'senderId': senderId,
      'receiverId': receiverId,
      'text': messageText,        // instead of 'body'
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sent',
      'delivered': false,
      'deliveredAt': null,
      'read': false,
      'readAt': null,
      'deletedFor': [],
      'isDeletedForEveryone': false,
    });
    DocumentSnapshot convDoc = await _firestore.collection('conversations').doc(conversationId).get();
    Map<String, dynamic> unreadMessages = {};
    if (convDoc.exists) {
      final data = convDoc.data() as Map<String, dynamic>?;
      unreadMessages = data?['unreadMessages'] as Map<String, dynamic>? ?? {};
    }
    int currentUnread = unreadMessages[receiverId] as int? ?? 0;
    unreadMessages[receiverId] = currentUnread + 1;
    unreadMessages[senderId] = 0;
    await _firestore.collection('conversations').doc(conversationId).set({
      'lastMessage': messageText,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'participants': [currentUserId, receiverId],
      'unreadMessages': unreadMessages,
    }, SetOptions(merge: true));
    
    // Send notification to receiver
    final currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.email != null) {
      await NotificationService.instance.sendMessageNotification(
        receiverId: receiverId,
        messageText: messageText,
        senderEmail: currentUser.email!,
      );
    }
    
    _messageController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
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
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
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

  Future<String?> _uploadFile(String path, String fileName) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('chat_files/$fileName');
      final uploadTask = await ref.putFile(File(path));
      return await ref.getDownloadURL();
    } catch (e) {
      print('File upload error: $e');
      return null;
    }
  }

  void _sendFileMessage({required String fileUrl, required String type, String? fileName}) async {
    String senderId = currentUserId;
    String receiverId = otherUserId;
    final messageRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc();
    await messageRef.set({
      'messageId': messageRef.id, // instead of 'id'
      'senderId': senderId,
      'receiverId': receiverId,
      'text': '', // For file messages, body is empty
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sent',
      'delivered': false,
      'deliveredAt': null,
      'read': false,
      'readAt': null,
      'fileUrl': fileUrl,
      'type': type,
      'fileName': fileName ?? '',
      'deletedFor': [],
      'isDeletedForEveryone': false,
    });
    // Update conversation doc as in sendMessage
    DocumentSnapshot convDoc = await _firestore.collection('conversations').doc(conversationId).get();
    Map<String, dynamic> unreadMessages = {};
    if (convDoc.exists) {
      final data = convDoc.data() as Map<String, dynamic>?;
      unreadMessages = data?['unreadMessages'] as Map<String, dynamic>? ?? {};
    }
    int currentUnread = unreadMessages[receiverId] as int? ?? 0;
    unreadMessages[receiverId] = currentUnread + 1;
    unreadMessages[senderId] = 0;
    await _firestore.collection('conversations').doc(conversationId).set({
      'lastMessage': type == 'text' ? '' : '[${type.toUpperCase()}]',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'participants': [currentUserId, receiverId],
      'unreadMessages': unreadMessages,
    }, SetOptions(merge: true));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _onPickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final url = await _uploadFile(pickedFile.path, pickedFile.name);
      if (url != null) {
        _sendFileMessage(fileUrl: url, type: 'image', fileName: pickedFile.name);
      }
    }
  }

  void _onPickVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      final url = await _uploadFile(pickedFile.path, pickedFile.name);
      if (url != null) {
        _sendFileMessage(fileUrl: url, type: 'video', fileName: pickedFile.name);
      }
    }
  }

  void _onPickDocument() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      final file = result.files.single;
      final url = await _uploadFile(file.path!, file.name);
      if (url != null) {
        _sendFileMessage(fileUrl: url, type: 'document', fileName: file.name);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 32,
        backgroundColor: AppTheme.primary100,
        title: Row(
          children: [
            CircleAvatar(radius: 20, backgroundImage: NetworkImage(widget.avatarUrl)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.userName, style: TextStyle(fontSize: 20)),
                StreamBuilder<DocumentSnapshot>(
                  stream: _firestore.collection('users').doc(otherUserId).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data == null) {
                      return const Text('Loading...', style: TextStyle(color: Colors.grey, fontSize: 14));
                    }
                    final userData = snapshot.data!.data() as Map<String, dynamic>?;
                    final isOnline = userData?['online'] ?? false;
                    final lastSeen = userData?['lastSeen'] as Timestamp?;
                    return isOnline
                        ? const Text('Online', style: TextStyle(color: Colors.green, fontSize: 14))
                        : Text(
                            lastSeen != null
                                ? 'Last active: ${formatTime(lastSeen)}'
                                : 'Offline',
                            style: const TextStyle(color: Colors.grey, fontSize: 14),
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
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error:  [snapshot.error]"));
                  }
                  var messages = snapshot.data?.docs ?? [];
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });
                  List<Widget> messageWidgets = [];
                  String? lastDayLabel;
                  for (int index = 0; index < messages.length; index++) {
                    var messageData = messages[index].data() as Map<String, dynamic>;
                    var timestamp = messageData['timestamp'] as Timestamp?;
                    String dayLabel = formatDayLabel(timestamp);
                    if (dayLabel != lastDayLabel) {
                      messageWidgets.add(
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(dayLabel, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      );
                      lastDayLabel = dayLabel;
                    }
                    final senderId = messageData['senderId']?.toString() ?? '';
                    final text = messageData['text']?.toString() ?? '';
                    final isMe = senderId == currentUserId;
                    final fileUrl = messageData['fileUrl']?.toString();
                    final type = messageData['type']?.toString() ?? 'text';
                    final fileName = messageData['fileName']?.toString();
                    final bool isDeletedForEveryone = messageData['isDeletedForEveryone'] == true;
                    final List<dynamic> rawDeletedFor = messageData['deletedFor'] ?? [];
                    final List<String> deletedFor = rawDeletedFor.whereType<String>().toList();

                    if (!isMe && messageData['read'] == false) {
                      _firestore
                          .collection('conversations')
                          .doc(conversationId)
                          .collection('messages')
                          .doc(messageData['messageId'])
                          .update({
                        'read': true,
                        'readAt': FieldValue.serverTimestamp(),
                        'status': 'read'
                      });
                    }

                    if (isDeletedForEveryone) {
                      messageWidgets.add(
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "This message was deleted",
                                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[700]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else if (deletedFor.contains(currentUserId)) {
                      // Do nothing, the message will be skipped
                    } else {
                      messageWidgets.add(
                        MessageBubble(
                          message: text,
                          isSender: isMe,
                          time: formatTime(timestamp),
                          statusIcon: getMessageStatusIcon(messageData),
                          fileUrl: fileUrl,
                          type: type,
                          fileName: fileName,
                          conversationId: conversationId,
                          messageId: messageData['messageId'],
                          senderId: senderId,
                          currentUserId: currentUserId,
                          isDeletedForEveryone: isDeletedForEveryone,
                          deletedFor: deletedFor,
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
          // Typing indicator
          StreamBuilder<DocumentSnapshot>(
            stream: _firestore.collection('conversations').doc(conversationId).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data == null) {
                return const SizedBox.shrink();
              }
              final data = snapshot.data!.data() as Map<String, dynamic>?;
              if (data == null) return const SizedBox.shrink();
              final typingUsers = data['typingUsers'] as Map<String, dynamic>? ?? {};
              bool isOtherUserTyping = false;
              for (var entry in typingUsers.entries) {
                if (entry.key != currentUserId && entry.value == true) {
                  isOtherUserTyping = true;
                  break;
                }
              }
              return isOtherUserTyping
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40,
                            height: 20,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: List.generate(
                                3,
                                (index) => Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Text("typing...", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),
          // Message input field
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _onPickDocument,
                ),
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _onPickImage,
                ),
                IconButton(
                  icon: const Icon(Icons.videocam),
                  onPressed: _onPickVideo,
                ),
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
                  onPressed: sendMessage,
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
}
