import 'package:flutter/material.dart';
import 'package:ting/features/chat/presentation/screens/chat_screen.dart';
import 'package:ting/features/chat/presentation/widgets/chat_list_item.dart';
import 'package:ting/shared/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    final isToday = now.year == dateTime.year &&
        now.month == dateTime.month &&
        now.day == dateTime.day;
    if (isToday) {
      return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    } else {
      return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
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
            child: StreamBuilder<QuerySnapshot>(
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
                    return StreamBuilder<DocumentSnapshot>(
                      stream: _firestore
                          .collection('conversations')
                          .doc(([currentUserId, uid]..sort()).join('_'))
                          .snapshots(),
                      builder: (context, convSnapshot) {
                        String lastMessage = '';
                        String messageTime = '';
                        int unreadCount = 0;
                        bool isTyping = false;
                        if (convSnapshot.hasData && convSnapshot.data!.exists) {
                          final convData = convSnapshot.data!.data() as Map<String, dynamic>;
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
                            isTyping = typingUsers[uid] == true;
                          }
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
                            if (currentUserId.isEmpty || uid.isEmpty) {
                              print('User ID is empty!');
                              return;
                            }
                            final convId = await _getOrCreateConversation(currentUserId, uid);
                            // Reset unread counter when entering the chat
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
                                  otherUserId: uid, // <-- Make sure this is set!
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
            ),
          ),
        ],
      ),
    );
  }
}
