import 'package:flutter/material.dart';

class ForumBottomActions extends StatelessWidget {
  const ForumBottomActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionButton(
          icon: Icons.thumb_up_alt_outlined,
          onPressed: () {
            print('Liked the post');
          },
        ),
        _buildActionButton(
          icon: Icons.thumb_down_alt_outlined,
          onPressed: () {
            print('Disliked the post');
          },
        ),
        _buildActionButton(
          icon: Icons.comment_outlined,
          onPressed: () {
            print('Commented on the post');
          },
        ),
        _buildActionButton(
          icon: Icons.share_outlined,
          onPressed: () {
            print('Shared the post');
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Row(
      children: [
        IconButton(
          iconSize: 20.0,
          color: Colors.grey[600],
          icon: Icon(icon),
          onPressed: onPressed,
        ),
        Text('12', style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }
}
