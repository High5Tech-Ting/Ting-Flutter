import 'package:flutter/material.dart';

class ForumHeader extends StatelessWidget {
  const ForumHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 20.0,
              backgroundImage: NetworkImage(
                'https://avatar.iran.liara.run/public',
              ),
            ),
            SizedBox(width: 8.0),
            Text('Olivia Brown', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        Text(
          '2 hours ago',
          style: TextStyle(color: Colors.grey[600], fontSize: 14.0),
        ),
      ],
    );
  }
}
