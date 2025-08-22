import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:ting/features/lostFound/presentation/screens/view_post.dart';
import 'package:ting/features/chat/presentation/screens/chat_screen.dart';
import 'package:ting/shared/theme.dart';

class LostFoundPost extends StatefulWidget {
  final String postId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String? text;
  final String? imageUrl;
  final int comments;
  final Timestamp? timestamp;
  final String status; // 'open' or 'resolved'
  final String type; // 'lost' or 'found'

  const LostFoundPost({
    super.key,
    required this.postId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    this.text,
    this.imageUrl,
    required this.comments,
    this.timestamp,
    required this.status,
    required this.type,
  });

  // Factory constructor to create from Firestore document
  factory LostFoundPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return LostFoundPost(
      postId: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      userPhotoUrl: data['userPhotoUrl'],
      text: data['text'],
      imageUrl: data['imageUrl'],
      comments: data['comments'] ?? 0,
      timestamp: data['createdAt'],
      status: data['status'] ?? 'open',
      type: data['type'] ?? 'lost',
    );
  }

  @override
  State<LostFoundPost> createState() => _LostFoundPostState();
}

class _LostFoundPostState extends State<LostFoundPost> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _formatTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final dateTime = timestamp.toDate();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('MMM d, yyyy').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Color _getStatusColor() {
    return widget.status == 'resolved' ? Colors.green : Colors.orange;
  }

  IconData _getTypeIcon() {
    return widget.type == 'lost' ? Icons.search : Icons.check_circle;
  }

  Color _getTypeColor() {
    return widget.type == 'lost' ? Colors.red : Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        border: Border.all(color: Colors.grey[300]!),
      ),
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 16.0),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post header with user info, status, and type
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: widget.userPhotoUrl != null
                        ? NetworkImage(widget.userPhotoUrl!)
                        : null,
                    child: widget.userPhotoUrl == null
                        ? Text(
                            widget.userName.isNotEmpty
                                ? widget.userName[0].toUpperCase()
                                : 'A',
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.userName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getTypeColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getTypeColor(),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getTypeIcon(),
                                  size: 12,
                                  color: _getTypeColor(),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.type.toUpperCase(),
                                  style: TextStyle(
                                    color: _getTypeColor(),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            _formatTimeAgo(widget.timestamp),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.status.toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  _showPostOptions(context);
                },
              ),
            ],
          ),

          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewPost(postId: widget.postId),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Post content
                if (widget.text != null && widget.text!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(widget.text!, style: const TextStyle(fontSize: 16)),
                ],

                // Post image if available
                if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: double.infinity,
                          height: 200,
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 200,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Post actions (comment and contact directly)
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: Icons.comment_outlined,
                label: '${widget.comments} Comments',
                color: Colors.grey[700],
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewPost(postId: widget.postId),
                    ),
                  );
                },
              ),
              if (widget.userId != _auth.currentUser?.uid)
                _buildActionButton(
                  icon: Icons.message_outlined,
                  label: 'Contact',
                  color: AppTheme.primary,
                  onPressed: () {
                    _contactUser(context);
                  },
                ),
              if (widget.userId == _auth.currentUser?.uid)
                _buildActionButton(
                  icon: widget.status == 'open' ? Icons.check : Icons.refresh,
                  label: widget.status == 'open' ? 'Mark Resolved' : 'Reopen',
                  color: widget.status == 'open' ? Colors.green : Colors.orange,
                  onPressed: () {
                    _togglePostStatus();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color? color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        decoration: BoxDecoration(
          color: color?.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color ?? Colors.grey, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _contactUser(BuildContext context) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to contact users')),
      );
      return;
    }

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final userName = userData['displayName'] ?? widget.userName;
        final userPhotoUrl = userData['photoURL'] ?? widget.userPhotoUrl ?? '';

        // Navigate to chat screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              userName: userName,
              lastActiveTime: 'Online',
              avatarUrl: userPhotoUrl,
              isOnline: true,
              otherUserId: widget.userId,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error starting chat: $e')));
    }
  }

  void _togglePostStatus() async {
    try {
      final newStatus = widget.status == 'open' ? 'resolved' : 'open';

      await _firestore.collection('lost_found_items').doc(widget.postId).update(
        {'status': newStatus, 'updatedAt': FieldValue.serverTimestamp()},
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Post marked as ${newStatus}')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
    }
  }

  void _showPostOptions(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid;
    final isOwner = currentUserId == widget.userId;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              if (isOwner) ...[
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit Post'),
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to edit post
                  },
                ),
                ListTile(
                  leading: Icon(
                    widget.status == 'open' ? Icons.check : Icons.refresh,
                    color: widget.status == 'open'
                        ? Colors.green
                        : Colors.orange,
                  ),
                  title: Text(
                    widget.status == 'open' ? 'Mark as Resolved' : 'Reopen',
                    style: TextStyle(
                      color: widget.status == 'open'
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _togglePostStatus();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Delete Post',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeletePost(context);
                  },
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.message, color: AppTheme.primary),
                  title: const Text(
                    'Contact User',
                    style: TextStyle(color: AppTheme.primary),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _contactUser(context);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _confirmDeletePost(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePost(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost(BuildContext context) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != widget.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only delete your own posts')),
      );
      return;
    }

    try {
      await _firestore
          .collection('lost_found_items')
          .doc(widget.postId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting post: $e')));
    }
  }
}
