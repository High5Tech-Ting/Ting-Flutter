import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:ting/features/forum/presentation/screens/view_post.dart';
import 'package:ting/features/chat/presentation/screens/chat_screen.dart';
import 'package:ting/shared/theme.dart';

class ForumPost extends StatefulWidget {
  final String postId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String? text;
  final String? imageUrl;
  final int likes;
  final int dislikes;
  final int comments;
  final Timestamp? timestamp;
  final List<String> likedBy;
  final List<String> dislikedBy;

  const ForumPost({
    super.key,
    required this.postId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    this.text,
    this.imageUrl,
    required this.likes,
    required this.dislikes,
    required this.comments,
    this.timestamp,
    required this.likedBy,
    required this.dislikedBy,
  });

  // Factory constructor to create from Firestore document
  factory ForumPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Extract liked and disliked users as List<String>
    List<String> likedBy = [];
    if (data['likedBy'] != null) {
      likedBy = List<String>.from(data['likedBy']);
    }

    List<String> dislikedBy = [];
    if (data['dislikedBy'] != null) {
      dislikedBy = List<String>.from(data['dislikedBy']);
    }

    return ForumPost(
      postId: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      userPhotoUrl: data['userPhotoUrl'],
      text: data['text'],
      imageUrl: data['imageUrl'],
      likes: data['likes'] ?? 0,
      dislikes: data['dislikes'] ?? 0,
      comments: data['comments'] ?? 0,
      timestamp: data['createdAt'],
      likedBy: likedBy,
      dislikedBy: dislikedBy,
    );
  }

  @override
  State<ForumPost> createState() => _ForumPostState();
}

class _ForumPostState extends State<ForumPost> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _commentController = TextEditingController();

  late int _likes;
  late int _dislikes;
  late bool _hasLiked;
  late bool _hasDisliked;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _likes = widget.likes;
    _dislikes = widget.dislikes;

    // Check if current user has liked or disliked this post
    final currentUserId = _auth.currentUser?.uid;
    _hasLiked = currentUserId != null && widget.likedBy.contains(currentUserId);
    _hasDisliked =
        currentUserId != null && widget.dislikedBy.contains(currentUserId);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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

  Future<void> _handleLike() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to like posts')),
      );
      return;
    }

    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final postRef = _firestore.collection('forum_posts').doc(widget.postId);

      if (_hasLiked) {
        await postRef.update({
          'likes': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([currentUser.uid]),
        });

        setState(() {
          _likes--;
          _hasLiked = false;
        });
      } else {
        final batch = _firestore.batch();

        if (_hasDisliked) {
          batch.update(postRef, {
            'dislikes': FieldValue.increment(-1),
            'dislikedBy': FieldValue.arrayRemove([currentUser.uid]),
          });

          setState(() {
            _dislikes--;
            _hasDisliked = false;
          });
        }

        // Then add to likes
        batch.update(postRef, {
          'likes': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([currentUser.uid]),
        });

        await batch.commit();

        setState(() {
          _likes++;
          _hasLiked = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _handleDislike() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to dislike posts')),
      );
      return;
    }

    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final postRef = _firestore.collection('forum_posts').doc(widget.postId);

      if (_hasDisliked) {
        await postRef.update({
          'dislikes': FieldValue.increment(-1),
          'dislikedBy': FieldValue.arrayRemove([currentUser.uid]),
        });

        setState(() {
          _dislikes--;
          _hasDisliked = false;
        });
      } else {
        final batch = _firestore.batch();

        if (_hasLiked) {
          batch.update(postRef, {
            'likes': FieldValue.increment(-1),
            'likedBy': FieldValue.arrayRemove([currentUser.uid]),
          });

          setState(() {
            _likes--;
            _hasLiked = false;
          });
        }

        batch.update(postRef, {
          'dislikes': FieldValue.increment(1),
          'dislikedBy': FieldValue.arrayUnion([currentUser.uid]),
        });

        await batch.commit();

        setState(() {
          _dislikes++;
          _hasDisliked = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
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
          // Post header with user info and timestamp
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
                      Text(
                        widget.userName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _formatTimeAgo(widget.timestamp),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  // Show post options menu
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

          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionButton(
                icon: _hasLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                label: '$_likes',
                color: _hasLiked ? AppTheme.primary : Colors.grey[700],
                onPressed: _handleLike,
              ),
              _buildActionButton(
                icon: _hasDisliked
                    ? Icons.thumb_down
                    : Icons.thumb_down_alt_outlined,
                label: '$_dislikes',
                color: _hasDisliked ? Colors.red : Colors.grey[700],
                onPressed: _handleDislike,
              ),
              _buildActionButton(
                icon: Icons.comment_outlined,
                label: '${widget.comments}',
                color: Colors.grey[700],
                onPressed: () {
                  _showComments(context);
                },
              ),
              _buildActionButton(
                icon: Icons.message_outlined,
                label: 'Message',
                color: AppTheme.primary,
                onPressed: () {
                  _messageUser(context);
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
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
                    'Message User',
                    style: TextStyle(color: AppTheme.primary),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _messageUser(context);
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
      await _firestore.collection('forum_posts').doc(widget.postId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting post: $e')));
    }
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return CommentsBottomSheet(
              postId: widget.postId,
              controller: scrollController,
              commentController: _commentController,
              onCommentAdded: () {
                setState(() {});
              },
            );
          },
        );
      },
    );
  }

  void _messageUser(BuildContext context) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to message users')),
      );
      return;
    }

    // Don't allow messaging yourself
    if (currentUser.uid == widget.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot message yourself')),
      );
      return;
    }

    try {
      // Get the user data for the post owner
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
}

class CommentsBottomSheet extends StatefulWidget {
  final String postId;
  final ScrollController controller;
  final TextEditingController commentController;
  final VoidCallback onCommentAdded;

  const CommentsBottomSheet({
    super.key,
    required this.postId,
    required this.controller,
    required this.commentController,
    required this.onCommentAdded,
  });

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          // Handle and title
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Comments',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
          ),

          // Comments list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('forum_posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading comments: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final comments = snapshot.data?.docs ?? [];

                if (comments.isEmpty) {
                  return const Center(
                    child: Text(
                      'No comments yet. Be the first to comment!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.separated(
                  controller: widget.controller,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: comments.length,
                  separatorBuilder: (context, index) =>
                      Divider(color: Colors.grey.shade300),
                  itemBuilder: (context, index) {
                    final comment =
                        comments[index].data() as Map<String, dynamic>;

                    // Extract likes and likedBy from comment data
                    int likes = comment['likes'] ?? 0;
                    List<String> likedBy = [];
                    if (comment['likedBy'] != null) {
                      likedBy = List<String>.from(comment['likedBy']);
                    }

                    return CommentItem(
                      userName: comment['userName'] ?? 'Anonymous',
                      userPhotoUrl: comment['userPhotoUrl'],
                      text: comment['text'] ?? '',
                      timestamp: comment['createdAt'] as Timestamp?,
                      userId: comment['userId'] ?? '',
                      commentId: comments[index].id,
                      postId: widget.postId,
                      likes: likes,
                      likedBy: likedBy,
                    );
                  },
                );
              },
            ),
          ),

          // Comment input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 8),
                _isSubmitting
                    ? const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send),
                        color: AppTheme.primary,
                        onPressed: _submitComment,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitComment() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to comment')),
      );
      return;
    }

    final commentText = widget.commentController.text.trim();
    if (commentText.isEmpty) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get user data
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final userData = userDoc.data();
      final userName =
          userData?['displayName'] ?? currentUser.email ?? 'Anonymous';
      final userPhotoUrl = userData?['photoURL'];

      // Create a new comment
      await _firestore
          .collection('forum_posts')
          .doc(widget.postId)
          .collection('comments')
          .add({
            'userId': currentUser.uid,
            'userName': userName,
            'userPhotoUrl': userPhotoUrl,
            'text': commentText,
            'createdAt': FieldValue.serverTimestamp(),
            'likes': 0,
            'likedBy': [],
          });

      // Update the comment count in the post document
      await _firestore.collection('forum_posts').doc(widget.postId).update({
        'comments': FieldValue.increment(1),
      });

      // Clear the comment input
      widget.commentController.clear();

      // Notify parent about comment added
      widget.onCommentAdded();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error posting comment: $e')));
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}

class CommentItem extends StatefulWidget {
  final String userName;
  final String? userPhotoUrl;
  final String text;
  final Timestamp? timestamp;
  final String userId;
  final String commentId;
  final String postId;
  final int likes;
  final List<String> likedBy;

  const CommentItem({
    super.key,
    required this.userName,
    this.userPhotoUrl,
    required this.text,
    this.timestamp,
    required this.userId,
    required this.commentId,
    required this.postId,
    this.likes = 0,
    this.likedBy = const [],
  });

  @override
  State<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late int _likes;
  late bool _hasLiked;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _likes = widget.likes;

    // Check if current user has liked this comment
    final currentUserId = _auth.currentUser?.uid;
    _hasLiked = currentUserId != null && widget.likedBy.contains(currentUserId);
  }

  Future<void> _handleLikeComment() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to like comments')),
      );
      return;
    }

    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final commentRef = _firestore
          .collection('forum_posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(widget.commentId);

      if (_hasLiked) {
        // User is unliking the comment
        await commentRef.update({
          'likes': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([currentUser.uid]),
        });

        setState(() {
          _likes--;
          _hasLiked = false;
        });
      } else {
        // User is liking the comment
        await commentRef.update({
          'likes': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([currentUser.uid]),
        });

        setState(() {
          _likes++;
          _hasLiked = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isProcessing = false;
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

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid;
    final isMyComment = widget.userId == currentUserId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User avatar
          CircleAvatar(
            radius: 16,
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

          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.userName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _formatTimeAgo(widget.timestamp),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(widget.text),

                // Comment actions
                Row(
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: _handleLikeComment,
                      child: Row(
                        children: [
                          Icon(
                            _hasLiked
                                ? Icons.thumb_up
                                : Icons.thumb_up_alt_outlined,
                            size: 14,
                            color: _hasLiked
                                ? AppTheme.primary
                                : Colors.grey[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _likes > 0 ? 'Like · $_likes' : 'Like',
                            style: TextStyle(
                              fontSize: 14,
                              color: _hasLiked
                                  ? AppTheme.primary
                                  : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isMyComment)
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        onPressed: () {
                          _confirmDeleteComment(context);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteComment(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteComment(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteComment(BuildContext context) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Delete the comment
      await firestore
          .collection('forum_posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(widget.commentId)
          .delete();

      // Update the comment count in the post document
      await firestore.collection('forum_posts').doc(widget.postId).update({
        'comments': FieldValue.increment(-1),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Comment deleted')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting comment: $e')));
    }
  }
}
