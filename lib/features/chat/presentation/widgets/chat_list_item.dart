import 'package:flutter/material.dart';
import 'package:ting/shared/theme.dart';

class ChatListItem extends StatelessWidget {
  final String userName;
  final String lastMessage;
  final String time;
  final String avatarUrl;
  final int newMessages;
  final bool isOnline;
  final VoidCallback? onTap;

  const ChatListItem({
    super.key,
    required this.userName,
    required this.lastMessage,
    required this.time,
    required this.avatarUrl,
    required this.newMessages,
    required this.isOnline,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(avatarUrl),
                  backgroundColor: Colors.grey.shade300,
                ),
                if (isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        userName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          color: newMessages > 0
                              ? AppTheme.primary
                              : Colors.grey[600],
                          fontVariations: const [FontVariation('wght', 600)],
                        ),
                      ),
                    ],
                  ),
                  Text(lastMessage, style: TextStyle(color: Colors.grey)),
                  newMessages > 0
                      ? Text(
                          '$newMessages new messages',
                          style: TextStyle(color: AppTheme.primary),
                        )
                      : const SizedBox.shrink(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
