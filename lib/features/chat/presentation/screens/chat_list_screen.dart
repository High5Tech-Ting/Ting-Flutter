import 'package:flutter/material.dart';
import 'package:ting/features/chat/presentation/screens/chat_screen.dart';
import 'package:ting/features/chat/presentation/widgets/chat_list_item.dart';
import 'package:ting/shared/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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
      // Today: show time with AM/PM
      return DateFormat('h:mm a').format(dateTime);
    } else if (diff == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (dateTime.year == now.year) {
      // This year: show month (short) and day
      return DateFormat('MMM d').format(dateTime);
    } else {
      // Previous years: show month (short), day, and year
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }

  Future<String> _getOrCreateConversation(String userId1, String userId2) async {
    final sortedIds = [userId1, userId2]..sort();
    final conversationId = '${sortedIds[0]}_${sortedIds[1]}';
    final conversationRef = _firestore.collection('conversations').doc(conversationId);
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
                      if (!convSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final convDocs = convSnapshot.data!.docs;
                      if (convDocs.isEmpty) {
                        return const Center(child: Text('No chats yet.'));
                      }
                      final filteredConvDocs = convDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return (data['lastMessage'] != null && (data['lastMessage'] as String).isNotEmpty);
                      }).toList();

                      final otherUserIds = filteredConvDocs.map((doc) {
                        final participants = (doc['participants'] as List).cast<String>();
                        return participants.firstWhere((id) => id != currentUserId, orElse: () => '');
                      }).where((id) => id.isNotEmpty).toSet().toList();
                      return ListView.builder(
                        itemCount: otherUserIds.length,
                        itemBuilder: (context, index) {
                          final otherUserId = otherUserIds[index];
                          return StreamBuilder<DocumentSnapshot>(
                            stream: _firestore.collection('users').doc(otherUserId).snapshots(),
                            builder: (context, userSnapshot) {
                              if (!userSnapshot.hasData || !userSnapshot.data!.exists) return const SizedBox.shrink();
                              final data = userSnapshot.data!.data() as Map<String, dynamic>;
                              final email = data['email'] ?? 'No Email';
                              final lastSeen = data['lastSeen'] as Timestamp?;
                              final isOnline = data['online'] ?? false;
                              final avatarUrl = data['avatarUrl'] ?? 'https://avatar.iran.liara.run/public';
                              // Find the conversation doc for this user
                              final convDoc = convDocs.firstWhere((doc) => (doc['participants'] as List).contains(otherUserId));
                              String lastMessage = '';
                              String messageTime = '';
                              int unreadCount = 0;
                              bool isTyping = false;
                              final convData = convDoc.data() as Map<String, dynamic>;
                              lastMessage = convData['lastMessage'] ?? '';
                              final lastMessageTime = convData['lastMessageTime'] as Timestamp?;
                              if (lastMessageTime != null) {
                                messageTime = formatTimestamp(lastMessageTime);
                              }
                              final unreadMessages = convData['unreadMessages'] as Map<String, dynamic>?;
                              if (unreadMessages != null) {
                                unreadCount = unreadMessages[currentUserId] ?? 0;
                              }
                              final typingUsers = convData['typingUsers'] as Map<String, dynamic>?;
                              if (typingUsers != null) {
                                isTyping = typingUsers[otherUserId] == true;
                              }
                              return ChatListItem(
                                userName: email,
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
                                    await _firestore.collection('conversations').doc(convId).set({
                                      'unreadMessages': {
                                        currentUserId: 0
                                      }
                                    }, SetOptions(merge: true));
                                  }
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        userName: email,
                                        lastActiveTime: lastSeen != null ? formatTimestamp(lastSeen) : '',
                                        avatarUrl: avatarUrl,
                                        isOnline: isOnline,
                                        conversationId: convId,
                                        otherUserId: otherUserId,
                                      ),
                                    ),
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
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final users = snapshot.data!.docs.where((doc) => doc.id != currentUserId).toList();
                      final searchText = controller.text.toLowerCase();
                      final filteredUsers = users.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final email = (data['email'] ?? '').toString().toLowerCase();
                        return email.contains(searchText);
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
                          final email = data['email'] ?? 'No Email';
                          final lastSeen = data['lastSeen'] as Timestamp?;
                          final isOnline = data['online'] ?? false;
                          final avatarUrl = data['avatarUrl'] ?? 'https://avatar.iran.liara.run/public';
                          return ChatListItem(
                            userName: email,
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
                              final convId = await _getOrCreateConversation(currentUserId, uid);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    userName: email,
                                    lastActiveTime: lastSeen != null ? formatTimestamp(lastSeen) : '',
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
