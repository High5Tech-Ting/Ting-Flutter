import 'package:flutter/material.dart';
import 'package:ting/shared/theme.dart';

class GroupListItem extends StatelessWidget {
  final String groupName;
  final String lastMessage;
  final String time;
  final String? groupImageUrl;
  final int newMessages;
  final int memberCount;
  final VoidCallback? onTap;

  const GroupListItem({
    super.key,
    required this.groupName,
    required this.lastMessage,
    required this.time,
    this.groupImageUrl,
    required this.newMessages,
    required this.memberCount,
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
            CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.primary,
              backgroundImage: groupImageUrl != null
                  ? NetworkImage(groupImageUrl!)
                  : null,
              child: groupImageUrl == null
                  ? Icon(
                      Icons.group,
                      color: Colors.white,
                      size: 32,
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          groupName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
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
                  const SizedBox(height: 2),
                  Text(
                    '$memberCount members',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lastMessage,
                    style: TextStyle(color: Colors.grey[700]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (newMessages > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '$newMessages new message${newMessages == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
