import 'package:flutter/material.dart';
import 'package:ting/features/chat/presentation/widgets/message_bubble.dart';
import 'package:ting/shared/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ting/Components/services/notification_service.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart'; // Updated import

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
  final FirebaseStorage _storage = FirebaseStorage.instance;
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

  File? _selectedFile;
  String? _selectedFileType;
  String? _selectedFileName;

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

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppTheme.primary,
                ),
                title: const Text('Photo from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppTheme.primary),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: AppTheme.primary),
                title: const Text('Video from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.video_camera_back,
                  color: AppTheme.primary,
                ),
                title: const Text('Record a Video'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.insert_drive_file,
                  color: AppTheme.primary,
                ),
                title: const Text('Document'),
                onTap: () {
                  Navigator.pop(context);
                  _pickDocument();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() {
        _selectedFile = File(image.path);
        _selectedFileType = 'image';
        _selectedFileName = image.name;
      });
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(
      source: source,
      maxDuration: const Duration(minutes: 1),
    );

    if (video != null) {
      setState(() {
        _selectedFile = File(video.path);
        _selectedFileType = 'video';
        _selectedFileName = video.name;
      });
    }
  }

  // Updated _pickDocument method using file_picker
  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'txt',
          'rtf',
          'xls',
          'xlsx',
          'ppt',
          'pptx',
          'zip',
          'rar',
          '7z',
        ],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        PlatformFile file = result.files.first;

        // Check file size (limit to 10MB)
        final fileSizeInMB = (file.size) / (1024 * 1024);

        if (fileSizeInMB > 10) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File size must be less than 10MB'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedFile = File(file.path!);
          _selectedFileType = 'document';
          _selectedFileName = file.name;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Document "${file.name}" selected'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> sendMessage() async {
    if (_messageController.text.isEmpty && _selectedFile == null) return;

    String messageText = _messageController.text;
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

      if (_selectedFile != null) {
        final String timestamp = DateTime.now().millisecondsSinceEpoch
            .toString();
        final String filename =
            'chat/${conversationId}/${senderId}_${timestamp}_${_selectedFileName ?? 'file'}';

        final storageRef = _storage.ref().child(filename);

        final SettableMetadata metadata = SettableMetadata(
          contentType: _getContentType(),
          customMetadata: {
            'senderId': senderId,
            'conversationId': conversationId,
            'fileName': _selectedFileName ?? 'file',
            'fileType': _selectedFileType ?? 'unknown',
          },
        );

        final uploadTask = storageRef.putFile(_selectedFile!, metadata);
        final snapshot = await uploadTask;
        fileUrl = await snapshot.ref.getDownloadURL();
        fileType = _selectedFileType;
        fileName = _selectedFileName;
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
          : '${_selectedFileType?.toUpperCase() ?? 'File'} attachment';

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

      _messageController.clear();
      _removeSelectedFile();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

      setState(() {
        _replyToMessageId = null;
        _replyToText = null;
        _replyToSenderId = null;
        _isSending = false;
      });
    } catch (e) {
      setState(() {
        _isSending = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
    }
  }

  String _getContentType() {
    switch (_selectedFileType) {
      case 'image':
        return 'image/jpeg';
      case 'video':
        return 'video/mp4';
      case 'document':
        if (_selectedFileName != null) {
          final extension = _selectedFileName!.toLowerCase();
          if (extension.endsWith('.pdf')) return 'application/pdf';
          if (extension.endsWith('.doc')) return 'application/msword';
          if (extension.endsWith('.docx')) {
            return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          }
          if (extension.endsWith('.txt')) return 'text/plain';
          if (extension.endsWith('.rtf')) return 'application/rtf';
          if (extension.endsWith('.xls')) return 'application/vnd.ms-excel';
          if (extension.endsWith('.xlsx')) {
            return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
          }
          if (extension.endsWith('.ppt')) {
            return 'application/vnd.ms-powerpoint';
          }
          if (extension.endsWith('.pptx')) {
            return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
          }
          if (extension.endsWith('.zip')) return 'application/zip';
          if (extension.endsWith('.rar')) return 'application/vnd.rar';
          if (extension.endsWith('.7z')) return 'application/x-7z-compressed';
        }
        return 'application/octet-stream';
      default:
        return 'application/octet-stream';
    }
  }

  void _removeSelectedFile() {
    setState(() {
      _selectedFile = null;
      _selectedFileType = null;
      _selectedFileName = null;
    });
  }

  Color _getFileTypeColor() {
    switch (_selectedFileType) {
      case 'image':
        return Colors.green;
      case 'video':
        return Colors.purple;
      case 'document':
        if (_selectedFileName != null) {
          final extension = _selectedFileName!.toLowerCase();
          if (extension.endsWith('.pdf')) return Colors.red;
          if (extension.endsWith('.doc') || extension.endsWith('.docx'))
            return Colors.blue;
          if (extension.endsWith('.xls') || extension.endsWith('.xlsx'))
            return Colors.green;
          if (extension.endsWith('.ppt') || extension.endsWith('.pptx'))
            return Colors.orange;
        }
        return AppTheme.primary;
      default:
        return AppTheme.primary;
    }
  }

  IconData _getFileTypeIcon() {
    switch (_selectedFileType) {
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.videocam;
      case 'document':
        if (_selectedFileName != null) {
          final extension = _selectedFileName!.toLowerCase();
          if (extension.endsWith('.pdf')) return Icons.picture_as_pdf;
          if (extension.endsWith('.doc') || extension.endsWith('.docx'))
            return Icons.description;
          if (extension.endsWith('.xls') || extension.endsWith('.xlsx'))
            return Icons.table_chart;
          if (extension.endsWith('.ppt') || extension.endsWith('.pptx'))
            return Icons.slideshow;
          if (extension.endsWith('.txt')) return Icons.text_snippet;
          if (extension.contains('zip') ||
              extension.contains('rar') ||
              extension.contains('7z'))
            return Icons.archive;
        }
        return Icons.insert_drive_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getFileSizeText() {
    if (_selectedFile != null) {
      final bytes = _selectedFile!.lengthSync();
      if (bytes < 1024) {
        return '$bytes B';
      } else if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)} KB';
      } else {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    }
    return '';
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
              backgroundImage: NetworkImage(widget.avatarUrl),
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
          if (_replyToText != null)
            Container(
              color: Colors.grey[200],
              padding: EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(child: Text(_replyToText!)),
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
          Column(
            children: [
              if (_selectedFile != null)
                Container(
                  color: Colors.grey[200],
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      _selectedFileType == 'image'
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _selectedFile!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: _getFileTypeColor(),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getFileTypeIcon(),
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedFileType?.toUpperCase() ?? 'FILE',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getFileTypeColor(),
                              ),
                            ),
                            Text(
                              _selectedFileName ?? 'Attachment',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_selectedFileType == 'document')
                              Text(
                                _getFileSizeText(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _removeSelectedFile,
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 16.0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: _showAttachmentOptions,
                      icon: Icon(Icons.attach_file_outlined),
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
                    SizedBox(width: 8),
                    _isSending
                        ? Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: AppTheme.surface,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : IconButton(
                            onPressed: sendMessage,
                            icon: const Icon(Icons.send),
                            style: ButtonStyle(
                              iconColor: WidgetStatePropertyAll(
                                AppTheme.surface,
                              ),
                              backgroundColor: WidgetStatePropertyAll(
                                AppTheme.primary,
                              ),
                              padding: WidgetStatePropertyAll(
                                EdgeInsets.all(10),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
