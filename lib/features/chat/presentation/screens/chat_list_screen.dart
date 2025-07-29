import 'package:animated_icon/animated_icon.dart';
import 'package:flutter/material.dart';
import 'package:ting/features/chat/presentation/screens/chat_screen.dart';
import 'package:ting/features/chat/presentation/widgets/chat_list_item.dart';
import 'package:ting/shared/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:ting/core/services/api_client.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController controller = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      setState(() {});
      print('Search input: ${controller.text}');
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final diff = today.difference(messageDay).inDays;
    if (diff == 0) {
      return DateFormat('h:mm a').format(dateTime);
    } else if (diff == 1) {
      return 'Yesterday';
    } else if (dateTime.year == now.year) {
      return DateFormat('MMM d').format(dateTime);
    } else {
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }

  Future<String> _getOrCreateConversation(
    String userId1,
    String userId2,
  ) async {
    final sortedIds = [userId1, userId2]..sort();
    final conversationId = '${sortedIds[0]}_${sortedIds[1]}';
    final conversationRef = _firestore
        .collection('conversations')
        .doc(conversationId);
    final doc = await conversationRef.get();
    if (!doc.exists) {
      await conversationRef.set({
        'participants': sortedIds,
        'createdAt': FieldValue.serverTimestamp(),
        'typingUsers': {},
      });
    }
    return conversationId;
  }

  void _showUnreadMessagesBottomSheet(String conversationId, String userName) {
    final currentUserId = _auth.currentUser?.uid ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Messages summary
            Expanded(
              child: FutureBuilder<List<QueryDocumentSnapshot>>(
                future: _firestore
                    .collection('conversations')
                    .doc(conversationId)
                    .collection('messages')
                    .where('read', isEqualTo: false)
                    .where('senderId', isNotEqualTo: currentUserId)
                    .orderBy('senderId') // Required for inequality filter
                    .orderBy('timestamp', descending: false)
                    .get()
                    .then((snapshot) => snapshot.docs),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimateIcon(
                            key: UniqueKey(),
                            onTap: () {},
                            iconType: IconType.continueAnimation,
                            height: 70,
                            width: 70,
                            color: AppTheme.primary,
                            animateIcon: AnimateIcons.chatMessage,
                          ),
                          const SizedBox(height: 16),
                          const Text('Generating summary...'),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Error: ${snapshot.error}'),
                        ],
                      ),
                    );
                  }

                  final messages = snapshot.data ?? [];

                  if (messages.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.mark_email_read,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No recent messages to summarize',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  // Extract message texts for API call
                  final messageTexts = messages
                      .map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final text = data['text']?.toString() ?? '';
                        return text.isNotEmpty ? text : '[Attachment]';
                      })
                      .where((text) => text.isNotEmpty)
                      .toList();

                  return FutureBuilder<ChatSummaryResponse>(
                    future: _getSummary(messageTexts),
                    builder: (context, summarySnapshot) {
                      if (summarySnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimateIcon(
                                key: UniqueKey(),
                                onTap: () {},
                                iconType: IconType.continueAnimation,
                                height: 70,
                                width: 70,
                                color: AppTheme.primary,
                                animateIcon: AnimateIcons.chatMessage,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Summarizing ${messageTexts.length} messages...',
                              ),
                            ],
                          ),
                        );
                      }

                      if (summarySnapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.orange,
                              ),
                              const SizedBox(height: 16),
                              const Text('Failed to generate summary'),
                              const SizedBox(height: 8),
                              Text(
                                summarySnapshot.error.toString(),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {});
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      final summary = summarySnapshot.data!;

                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    color: Colors.purple[600],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'AI Summary',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                summary.summary,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.5,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<ChatSummaryResponse> _getSummary(List<String> messages) async {
    try {
      return await ApiClient.instance.summarizeMessages(messages);
    } catch (e) {
      throw Exception('Failed to get summary: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        surfaceTintColor: AppTheme.surface,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: const TextStyle(color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: controller.text.isNotEmpty
                    ? GestureDetector(
                        child: const Icon(Icons.clear, color: Colors.grey),
                        onTap: () {
                          controller.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: controller.text.isEmpty
                ? StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('conversations')
                        .where('participants', arrayContains: currentUserId)
                        .snapshots(),
                    builder: (context, convSnapshot) {
                      if (!convSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final convDocs = convSnapshot.data!.docs;
                      if (convDocs.isEmpty) {
                        return const Center(child: Text('No chats yet.'));
                      }
                      final filteredConvDocs = convDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return (data['lastMessage'] != null &&
                            (data['lastMessage'] as String).isNotEmpty);
                      }).toList();

                      filteredConvDocs.sort((a, b) {
                        final aData = a.data() as Map<String, dynamic>;
                        final bData = b.data() as Map<String, dynamic>;
                        final aTime = aData['lastMessageTime'] as Timestamp?;
                        final bTime = bData['lastMessageTime'] as Timestamp?;

                        if (aTime == null && bTime == null) return 0;
                        if (aTime == null) return 1;
                        if (bTime == null) return -1;

                        return bTime.compareTo(aTime);
                      });

                      final otherUserIds = filteredConvDocs
                          .map((doc) {
                            final participants = (doc['participants'] as List)
                                .cast<String>();
                            return participants.firstWhere(
                              (id) => id != currentUserId,
                              orElse: () => '',
                            );
                          })
                          .where((id) => id.isNotEmpty)
                          .toSet()
                          .toList();
                      return ListView.builder(
                        itemCount: otherUserIds.length,
                        itemBuilder: (context, index) {
                          final otherUserId = otherUserIds[index];
                          return StreamBuilder<DocumentSnapshot>(
                            stream: _firestore
                                .collection('users')
                                .doc(otherUserId)
                                .snapshots(),
                            builder: (context, userSnapshot) {
                              if (!userSnapshot.hasData ||
                                  !userSnapshot.data!.exists) {
                                return const SizedBox.shrink();
                              }
                              final data =
                                  userSnapshot.data!.data()
                                      as Map<String, dynamic>;
                              final lastSeen = data['lastSeen'] as Timestamp?;
                              final isOnline = data['online'] ?? false;
                              final userName = data['displayName'] ?? "No Name";
                              final avatarUrl =
                                  data['profilePictureUrl'] ??
                                  "https://avatar.iran.liara.run/public/?username=${data['uid']}";
                              // Find the conversation doc for this user
                              final convDoc = convDocs.firstWhere(
                                (doc) => (doc['participants'] as List).contains(
                                  otherUserId,
                                ),
                              );
                              String lastMessage = '';
                              String messageTime = '';
                              int unreadCount = 0;
                              bool isTyping = false;
                              final convData =
                                  convDoc.data() as Map<String, dynamic>;
                              lastMessage = convData['lastMessage'] ?? '';
                              final lastMessageTime =
                                  convData['lastMessageTime'] as Timestamp?;
                              if (lastMessageTime != null) {
                                messageTime = formatTimestamp(lastMessageTime);
                              }
                              final unreadMessages =
                                  convData['unreadMessages']
                                      as Map<String, dynamic>?;
                              if (unreadMessages != null) {
                                unreadCount =
                                    unreadMessages[currentUserId] ?? 0;
                              }
                              final typingUsers =
                                  convData['typingUsers']
                                      as Map<String, dynamic>?;
                              if (typingUsers != null) {
                                isTyping = typingUsers[otherUserId] == true;
                              }
                              return ChatListItem(
                                userName: userName,
                                lastMessage: isTyping
                                    ? 'typing...'
                                    : lastMessage.isNotEmpty
                                    ? lastMessage
                                    : isOnline
                                    ? 'Online'
                                    : lastSeen != null
                                    ? 'Last seen: ${formatTimestamp(lastSeen)}'
                                    : '',
                                time: messageTime,
                                avatarUrl: avatarUrl,
                                newMessages: unreadCount,
                                isOnline: isOnline,
                                onTap: () async {
                                  final convId = convDoc.id;
                                  if (unreadCount > 0) {
                                    await _firestore
                                        .collection('conversations')
                                        .doc(convId)
                                        .set({
                                          'unreadMessages': {currentUserId: 0},
                                        }, SetOptions(merge: true));
                                  }
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        userName: userName,
                                        lastActiveTime: lastSeen != null
                                            ? formatTimestamp(lastSeen)
                                            : '',
                                        avatarUrl: avatarUrl,
                                        isOnline: isOnline,
                                        conversationId: convId,
                                        otherUserId: otherUserId,
                                      ),
                                    ),
                                  );
                                },
                                onLongPress: () {
                                  // Show unread messages summary bottom sheet
                                  _showUnreadMessagesBottomSheet(
                                    convDoc.id,
                                    userName,
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('users').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final users = snapshot.data!.docs
                          .where((doc) => doc.id != currentUserId)
                          .toList();
                      final searchText = controller.text.toLowerCase();
                      final filteredUsers = users.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final email = (data['email'] ?? '')
                            .toString()
                            .toLowerCase();
                        final displayName = (data['displayName'] ?? '')
                            .toString()
                            .toLowerCase();
                        return email.contains(searchText) ||
                            displayName.contains(searchText);
                      }).toList();
                      if (filteredUsers.isEmpty) {
                        return const Center(child: Text('No users found.'));
                      }
                      return ListView.builder(
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final doc = filteredUsers[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final uid = doc.id;
                          final lastSeen = data['lastSeen'] as Timestamp?;
                          final isOnline = data['online'] ?? false;
                          final userName = data['displayName'] ?? "No Name";
                          final avatarUrl =
                              data['avatarUrl'] ??
                              "https://avatar.iran.liara.run/public/?username=$userName";
                          return ChatListItem(
                            userName: userName,
                            lastMessage: isOnline
                                ? 'Online'
                                : lastSeen != null
                                ? 'Last seen: ${formatTimestamp(lastSeen)}'
                                : '',
                            time: '',
                            avatarUrl: avatarUrl,
                            newMessages: 0,
                            isOnline: isOnline,
                            onTap: () async {
                              final convId = await _getOrCreateConversation(
                                currentUserId,
                                uid,
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    userName: userName,
                                    lastActiveTime: lastSeen != null
                                        ? formatTimestamp(lastSeen)
                                        : '',
                                    avatarUrl: avatarUrl,
                                    isOnline: isOnline,
                                    conversationId: convId,
                                    otherUserId: uid,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
