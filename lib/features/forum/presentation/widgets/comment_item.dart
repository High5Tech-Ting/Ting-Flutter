import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:ting/shared/theme.dart';

class CommentItem extends StatefulWidget {
  final String userName;
  final String? userPhotoUrl;
  final String text;
  final Timestamp? timestamp;
  final String userId;
  final String commentId;
  final String postId;
  final VoidCallback? onCommentDeleted;
  final int likes;
  final List<String> likedBy;

  const CommentItem({
    Key? key,
    required this.userName,
    this.userPhotoUrl,
    required this.text,
    this.timestamp,
    required this.userId,
    required this.commentId,
    required this.postId,
    this.onCommentDeleted,
    this.likes = 0,
    this.likedBy = const [],
  }) : super(key: key);

  @override
  State<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late int _likes;
  late bool _hasLiked;
  bool _isProcessing = false;
  StreamSubscription<DocumentSnapshot>? _commentSubscription;

  @override
  void initState() {
    super.initState();
    _likes = widget.likes;
    _setupInitialState();
    _subscribeToCommentUpdates();
  }

  void _setupInitialState() {
    // Check if current user has liked this comment
    final currentUserId = _auth.currentUser?.uid;
    _hasLiked = currentUserId != null && widget.likedBy.contains(currentUserId);
  }

  void _subscribeToCommentUpdates() {
    final commentRef = _firestore
        .collection('forum_posts')
        .doc(widget.postId)
        .collection('comments')
        .doc(widget.commentId);

    _commentSubscription = commentRef.snapshots().listen(
      (snapshot) {
        if (!snapshot.exists) return;

        final data = snapshot.data() as Map<String, dynamic>;
        final currentUserId = _auth.currentUser?.uid;

        List<String> likedBy = [];
        if (data['likedBy'] != null) {
          likedBy = List<String>.from(data['likedBy']);
        }

        if (mounted) {
          setState(() {
            _likes = data['likes'] ?? 0;
            _hasLiked =
                currentUserId != null && likedBy.contains(currentUserId);
          });
        }
      },
      onError: (error) {
        debugPrint('Error listening to comment updates: $error');
      },
    );
  }

  @override
  void dispose() {
    _commentSubscription?.cancel();
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
      } else {
        // User is liking the comment
        await commentRef.update({
          'likes': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([currentUser.uid]),
        });
      }

      // Note: We don't need to update state here as the listener will handle it
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _deleteComment() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != widget.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only delete your own comments')),
      );
      return;
    }

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

      if (widget.onCommentDeleted != null) {
        widget.onCommentDeleted!();
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Comment deleted')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting comment: $e')));
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
                        onPressed: _deleteComment,
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 14,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Delete',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
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
}
