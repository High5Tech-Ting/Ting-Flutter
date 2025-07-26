import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ting/shared/theme.dart';

class CommentInput extends StatefulWidget {
  final String postId;
  final Function()? onCommentAdded;

  const CommentInput({Key? key, required this.postId, this.onCommentAdded})
    : super(key: key);

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isSubmittingComment = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to comment')),
      );
      return;
    }

    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) {
      return;
    }

    setState(() {
      _isSubmittingComment = true;
    });

    try {
      // Get user data
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final userData = userDoc.data() as Map<String, dynamic>?;
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
      _commentController.clear();

      // Notify parent that a comment was added
      if (widget.onCommentAdded != null) {
        widget.onCommentAdded!();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error posting comment: $e')));
    } finally {
      setState(() {
        _isSubmittingComment = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
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
            _isSubmittingComment
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
    );
  }
}
