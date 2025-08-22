import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:ting/shared/theme.dart';
import 'package:ting/features/lostFound/presentation/widgets/comment_input.dart';
import 'package:ting/features/lostFound/presentation/widgets/comment_list.dart';
import 'package:ting/features/chat/presentation/screens/chat_screen.dart';

class ViewPost extends StatefulWidget {
  final String postId;

  const ViewPost({super.key, required this.postId});

  @override
  State<ViewPost> createState() => _ViewPostState();
}

class _ViewPostState extends State<ViewPost> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Map<String, dynamic>? _postData;

  @override
  void initState() {
    super.initState();
    _loadPostData();
  }

  Future<void> _loadPostData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final postDoc = await _firestore
          .collection('lost_found_items')
          .doc(widget.postId)
          .get();

      if (!postDoc.exists) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Post not found';
        });
        return;
      }

      final data = postDoc.data() as Map<String, dynamic>;

      setState(() {
        _postData = data;
        _postData!['id'] = widget.postId;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Error loading post: $e';
      });
    }
  }

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

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageView(imageUrl: imageUrl),
      ),
    );
  }

  Color _getStatusColor(String status) {
    return status == 'resolved' ? Colors.green : Colors.orange;
  }

  IconData _getTypeIcon(String type) {
    return type == 'lost' ? Icons.search : Icons.check_circle;
  }

  Color _getTypeColor(String type) {
    return type == 'lost' ? Colors.red : Colors.blue;
  }

  void _contactUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to contact users')),
      );
      return;
    }

    try {
      final postOwnerId = _postData!['userId'];
      final userName = _postData!['userName'] ?? 'Anonymous';
      final userPhotoUrl = _postData!['userPhotoUrl'] ?? '';

      // Navigate to chat screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            userName: userName,
            lastActiveTime: 'Online',
            avatarUrl: userPhotoUrl,
            isOnline: true,
            otherUserId: postOwnerId,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error starting chat: $e')));
    }
  }

  void _togglePostStatus() async {
    try {
      final currentStatus = _postData!['status'] ?? 'open';
      final newStatus = currentStatus == 'open' ? 'resolved' : 'open';

      await _firestore.collection('lost_found_items').doc(widget.postId).update(
        {'status': newStatus, 'updatedAt': FieldValue.serverTimestamp()},
      );

      setState(() {
        _postData!['status'] = newStatus;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Post marked as ${newStatus}')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Post')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Post')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPostData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final post = _postData!;
    final String userName = post['userName'] ?? 'Anonymous';
    final String? userPhotoUrl = post['userPhotoUrl'];
    final String? postText = post['text'];
    final String? imageUrl = post['imageUrl'];
    final int comments = post['comments'] ?? 0;
    final Timestamp? timestamp = post['createdAt'];
    final String status = post['status'] ?? 'open';
    final String type = post['type'] ?? 'lost';
    final String postOwnerId = post['userId'] ?? '';
    final String currentUserId = _auth.currentUser?.uid ?? '';
    final bool isOwner = currentUserId == postOwnerId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showPostOptions(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Post content in a scrollable area
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post header with user info
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: userPhotoUrl != null
                              ? NetworkImage(userPhotoUrl)
                              : null,
                          child: userPhotoUrl == null
                              ? Text(
                                  userName.isNotEmpty
                                      ? userName[0].toUpperCase()
                                      : 'A',
                                  style: const TextStyle(fontSize: 20),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    userName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getTypeColor(
                                        type,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _getTypeColor(type),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _getTypeIcon(type),
                                          size: 12,
                                          color: _getTypeColor(type),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          type.toUpperCase(),
                                          style: TextStyle(
                                            color: _getTypeColor(type),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    _formatTimeAgo(timestamp),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                        status,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        color: _getStatusColor(status),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Post text
                  if (postText != null && postText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Text(
                        postText,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),

                  // Post image (tappable for full screen)
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    GestureDetector(
                      onTap: () => _showFullScreenImage(context, imageUrl),
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxHeight: 400),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return SizedBox(
                              height: 300,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return SizedBox(
                              height: 300,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Error loading image',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  // Post actions
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (!isOwner)
                          _buildActionButton(
                            icon: Icons.message_outlined,
                            label: 'Contact',
                            color: AppTheme.primary,
                            onPressed: _contactUser,
                          ),
                        if (isOwner)
                          _buildActionButton(
                            icon: status == 'open'
                                ? Icons.check
                                : Icons.refresh,
                            label: status == 'open'
                                ? 'Mark Resolved'
                                : 'Reopen',
                            color: status == 'open'
                                ? Colors.green
                                : Colors.orange,
                            onPressed: _togglePostStatus,
                          ),
                      ],
                    ),
                  ),

                  CommentList(
                    postId: widget.postId,
                    commentCount: comments,
                    onCommentCountChanged: (newCount) {
                      setState(() {
                        _postData!['comments'] = newCount;
                      });
                    },
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          CommentInput(
            postId: widget.postId,
            onCommentAdded: () {
              setState(() {
                _postData!['comments'] = (_postData!['comments'] ?? 0) + 1;
              });
            },
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
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: color?.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color ?? Colors.grey, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
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

  void _showPostOptions(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid;
    final isOwner = currentUserId == _postData!['userId'];

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
                    _contactUser();
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Close'),
                onTap: () => Navigator.pop(context),
              ),
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
    if (currentUser == null || currentUser.uid != _postData!['userId']) {
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
      Navigator.of(context).pop(); // Go back to previous screen
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting post: $e')));
    }
  }
}

class FullScreenImageView extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageView({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PhotoView(
        imageProvider: NetworkImage(imageUrl),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
        heroAttributes: PhotoViewHeroAttributes(tag: imageUrl),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        loadingBuilder: (context, event) => Center(
          child: CircularProgressIndicator(
            value: event == null
                ? 0
                : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
          ),
        ),
      ),
    );
  }
}
