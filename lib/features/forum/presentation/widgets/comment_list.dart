import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ting/features/forum/presentation/widgets/comment_item.dart';

class CommentList extends StatelessWidget {
  final String postId;
  final int commentCount;
  final Function(int) onCommentCountChanged;

  const CommentList({
    Key? key,
    required this.postId,
    required this.commentCount,
    required this.onCommentCountChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Comments section title
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Comments ($commentCount)',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),

        // Comments list
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('forum_posts')
              .doc(postId)
              .collection('comments')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error loading comments: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            }

            final comments = snapshot.data?.docs ?? [];

            if (comments.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No comments yet. Be the first to comment!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }

            return ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              itemCount: comments.length,
              separatorBuilder: (context, index) =>
                  Divider(color: Colors.grey.shade300),
              itemBuilder: (context, index) {
                final comment = comments[index].data() as Map<String, dynamic>;
                return CommentItem(
                  userName: comment['userName'] ?? 'Anonymous',
                  userPhotoUrl: comment['userPhotoUrl'],
                  text: comment['text'] ?? '',
                  timestamp: comment['createdAt'] as Timestamp?,
                  userId: comment['userId'] ?? '',
                  commentId: comments[index].id,
                  postId: postId,
                  onCommentDeleted: () {
                    onCommentCountChanged(commentCount - 1);
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}
