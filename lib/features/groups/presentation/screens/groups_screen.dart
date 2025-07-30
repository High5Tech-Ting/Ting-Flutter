import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:ting/core/models/group_model.dart';
import 'package:ting/core/models/broadcast_model.dart';
import 'package:ting/core/services/ai_engine.dart';
import 'package:ting/core/services/group_chat_service.dart';
import 'package:ting/core/services/broadcast_service.dart';
import 'package:ting/core/services/types.dart';
import 'package:ting/shared/theme.dart';
import 'create_group_screen.dart';
import 'create_broadcast_screen.dart';
import 'group_chat_screen.dart';
import 'broadcast_chat_screen.dart';
import 'package:animated_icon/animated_icon.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showGroups = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTimestamp(Timestamp? timestamp) {
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

  void _showGroupUnreadMessagesBottomSheet(String groupId, String groupName) {
    final currentUserId = GroupChatService.currentUserId;

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
                future: FirebaseFirestore.instance
                    .collection('groups')
                    .doc(groupId)
                    .collection('messages')
                    .where('senderId', isNotEqualTo: currentUserId)
                    .orderBy('senderId') // Required for inequality filter
                    .orderBy('timestamp', descending: false)
                    .get()
                    .then((snapshot) {
                      // Filter messages that are recent (last 24 hours) from other users
                      final now = DateTime.now();
                      final cutoffTime = now.subtract(const Duration(days: 1));

                      return snapshot.docs.where((doc) {
                        final data = doc.data();
                        final timestamp = data['timestamp'] as Timestamp?;
                        if (timestamp == null) return false;

                        // Include messages from the last 24 hours from other users
                        return timestamp.toDate().isAfter(cutoffTime);
                      }).toList();
                    }),
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

                  return FutureBuilder<List<String>>(
                    future: _formatGroupMessagesForSummary(messages),
                    builder: (context, formattedSnapshot) {
                      if (formattedSnapshot.connectionState ==
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
                              const Text('Formatting messages...'),
                            ],
                          ),
                        );
                      }

                      if (formattedSnapshot.hasError ||
                          !formattedSnapshot.hasData) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error,
                                size: 64,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error formatting messages: ${formattedSnapshot.error}',
                              ),
                            ],
                          ),
                        );
                      }

                      final formattedMessages = formattedSnapshot.data!;

                      return FutureBuilder<ChatSummaryResponse>(
                        future: _getGroupSummary(formattedMessages),
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
                                    'Summarizing ${formattedMessages.length} messages...',
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
                            padding: const EdgeInsets.all(16),
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
                                        Icons.auto_awesome_outlined,
                                        color: AppTheme.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'AI Summary',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primary,
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<String>> _formatGroupMessagesForSummary(
    List<QueryDocumentSnapshot> messages,
  ) async {
    final List<String> formattedMessages = [];

    for (final doc in messages) {
      final data = doc.data() as Map<String, dynamic>;
      final text = data['text']?.toString() ?? '';
      final senderId = data['senderId']?.toString() ?? '';
      final timestamp = data['timestamp'] as Timestamp?;

      if (text.isNotEmpty) {
        // Get sender display name
        String senderName = 'Unknown User';
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(senderId)
              .get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            senderName = userData['displayName'] ?? 'Unknown User';
          }
        } catch (e) {
          print('Error getting user name: $e');
        }

        // Format timestamp
        String timeString = '';
        if (timestamp != null) {
          final dateTime = timestamp.toDate();
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final messageDay = DateTime(
            dateTime.year,
            dateTime.month,
            dateTime.day,
          );
          final diff = today.difference(messageDay).inDays;

          if (diff == 0) {
            timeString = DateFormat('h:mm a').format(dateTime);
          } else if (diff == 1) {
            timeString = 'Yesterday ${DateFormat('h:mm a').format(dateTime)}';
          } else {
            timeString = DateFormat('MMM d, h:mm a').format(dateTime);
          }
        }

        // Format message with sender name and time
        final formattedMessage = '$senderName ($timeString): $text';
        formattedMessages.add(formattedMessage);
      } else {
        // Handle attachments
        final fileType = data['fileType']?.toString();
        if (fileType != null) {
          String senderName = 'Unknown User';
          try {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(senderId)
                .get();
            if (userDoc.exists) {
              final userData = userDoc.data() as Map<String, dynamic>;
              senderName = userData['displayName'] ?? 'Unknown User';
            }
          } catch (e) {
            print('Error getting user name: $e');
          }

          String timeString = '';
          if (timestamp != null) {
            final dateTime = timestamp.toDate();
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final messageDay = DateTime(
              dateTime.year,
              dateTime.month,
              dateTime.day,
            );
            final diff = today.difference(messageDay).inDays;

            if (diff == 0) {
              timeString = DateFormat('h:mm a').format(dateTime);
            } else if (diff == 1) {
              timeString = 'Yesterday ${DateFormat('h:mm a').format(dateTime)}';
            } else {
              timeString = DateFormat('MMM d, h:mm a').format(dateTime);
            }
          }

          final formattedMessage =
              '$senderName ($timeString): [${fileType.toUpperCase()} attachment]';
          formattedMessages.add(formattedMessage);
        }
      }
    }

    return formattedMessages;
  }

  Future<ChatSummaryResponse> _getGroupSummary(List<String> messages) async {
    try {
      return await AiEngine.summarizeMessages(messages);
    } catch (e) {
      throw Exception('Failed to get summary: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_showGroups ? 'Groups' : 'Broadcasts')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search groups...',
                hintStyle: const TextStyle(color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? GestureDetector(
                        child: const Icon(Icons.clear, color: Colors.grey),
                        onTap: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              spacing: 8.0,
              children: [
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _showGroups = true;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.primary),
                    backgroundColor: _showGroups
                        ? AppTheme.primary
                        : Colors.transparent,
                  ),
                  child: Text(
                    'Groups',
                    style: TextStyle(
                      fontFamily: "NunitoSans",
                      fontSize: 14.0,
                      fontVariations: [FontVariation('wght', 700)],
                      color: _showGroups ? Colors.white : AppTheme.primary,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _showGroups = false;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.primary),
                    backgroundColor: !_showGroups
                        ? AppTheme.primary
                        : Colors.transparent,
                  ),
                  child: Text(
                    'Broadcasts',
                    style: TextStyle(
                      fontFamily: "NunitoSans",
                      fontSize: 14.0,
                      fontVariations: [FontVariation('wght', 700)],
                      color: !_showGroups ? Colors.white : AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Groups or Broadcasts list
          Expanded(
            child: _showGroups ? _buildGroupsList() : _buildBroadcastsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => _showGroups
                  ? const CreateGroupScreen()
                  : const CreateBroadcastScreen(),
            ),
          );
        },
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGroupsList() {
    return StreamBuilder<List<GroupChat>>(
      stream: GroupChatService.getUserGroups(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Error loading groups',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final groups = snapshot.data ?? [];

        // Filter groups based on search query
        final filteredGroups = _searchController.text.isEmpty
            ? groups
            : groups.where((group) {
                final query = _searchController.text.toLowerCase();
                return group.groupName.toLowerCase().contains(query);
              }).toList();

        if (filteredGroups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _searchController.text.isEmpty
                      ? Icons.group_outlined
                      : Icons.search_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  _searchController.text.isEmpty
                      ? 'No groups yet'
                      : 'No groups found',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _searchController.text.isEmpty
                      ? 'Create a group to start chatting with multiple people'
                      : 'Try a different search term',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                if (_searchController.text.isEmpty) ...[
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateGroupScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Group'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredGroups.length,
          itemBuilder: (context, index) {
            final group = filteredGroups[index];
            final currentUserId = GroupChatService.currentUserId;
            final unreadCount = group.unreadMessages[currentUserId] ?? 0;

            return ListTile(
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primary,
                backgroundImage: group.groupImageUrl != null
                    ? NetworkImage(group.groupImageUrl!)
                    : null,
                child: group.groupImageUrl == null
                    ? Icon(Icons.group, color: Colors.white, size: 28)
                    : null,
              ),
              title: Text(
                group.groupName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (group.lastMessage != null)
                    Text(
                      group.lastMessage!,
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (group.lastMessageTime != null)
                    Text(
                      _formatTimestamp(group.lastMessageTime),
                      style: TextStyle(
                        color: unreadCount > 0
                            ? AppTheme.primary
                            : Colors.grey[600],
                        fontWeight: unreadCount > 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  if (unreadCount > 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              onTap: () async {
                // Mark messages as read when entering group
                if (unreadCount > 0) {
                  await GroupChatService.markGroupMessagesAsRead(group.groupId);
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupChatScreen(
                      groupId: group.groupId,
                      groupName: group.groupName,
                      groupImageUrl: group.groupImageUrl,
                    ),
                  ),
                );
              },
              onLongPress: () {
                // Show group messages summary bottom sheet
                _showGroupUnreadMessagesBottomSheet(
                  group.groupId,
                  group.groupName,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildBroadcastsList() {
    return StreamBuilder<List<Broadcast>>(
      stream: BroadcastService.getUserBroadcasts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Error loading broadcasts',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final broadcasts = snapshot.data ?? [];

        // Filter broadcasts based on search query
        final filteredBroadcasts = _searchController.text.isEmpty
            ? broadcasts
            : broadcasts.where((broadcast) {
                final query = _searchController.text.toLowerCase();
                return broadcast.broadcastName.toLowerCase().contains(query);
              }).toList();

        if (filteredBroadcasts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _searchController.text.isEmpty
                      ? Icons.broadcast_on_personal
                      : Icons.search_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  _searchController.text.isEmpty
                      ? 'No broadcasts yet'
                      : 'No broadcasts found',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _searchController.text.isEmpty
                      ? 'Create a broadcast to send messages to multiple recipients'
                      : 'Try a different search term',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                if (_searchController.text.isEmpty) ...[
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateBroadcastScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Broadcast'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredBroadcasts.length,
          itemBuilder: (context, index) {
            final broadcast = filteredBroadcasts[index];

            return ListTile(
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primary,
                child: Icon(
                  Icons.broadcast_on_personal,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              title: Text(
                broadcast.broadcastName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${broadcast.totalRecipients} recipients',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  if (broadcast.lastMessage != null)
                    Text(
                      broadcast.lastMessage!,
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
              trailing: broadcast.lastMessageTime != null
                  ? Text(
                      _formatTimestamp(broadcast.lastMessageTime),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    )
                  : null,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BroadcastChatScreen(
                      broadcastId: broadcast.broadcastId,
                      broadcastName: broadcast.broadcastName,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
