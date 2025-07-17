import 'package:flutter/material.dart';
import 'package:ting/features/forum/presentation/widgets/forum_bottom_actions.dart';
import 'package:ting/features/forum/presentation/widgets/forum_header.dart';
import 'package:ting/features/forum/presentation/widgets/forum_image.dart';

class ForumPost extends StatelessWidget {
  const ForumPost({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        border: Border.all(color: Colors.grey[300]!),
      ),
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 16.0),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        spacing: 8.0,
        children: [
          ForumHeader(),
          Align(
            alignment: Alignment.topLeft,
            child: Text(
              'This is the content of the forum post. It can be a discussion about various topics, questions, or announcements related to the forum.',
              softWrap: true,
            ),
          ),
          ForumImage(),
          ForumBottomActions(),
        ],
      ),
    );
  }
}
