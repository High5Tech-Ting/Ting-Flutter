import 'package:flutter/material.dart';
import 'package:ting/shared/theme.dart';
import 'package:ting/Components/services/message_service.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isSender;
  final String time;
  final Widget? statusIcon;
  final String conversationId;
  final String messageId;
  final String senderId;
  final String currentUserId;
  final bool isDeletedForEveryone;
  final List<String> deletedFor;
  final String? replyToMessageId;
  final String? replyToText;
  final String? replyToSenderId;
  final void Function(String messageId, String text, String senderId)? onReply;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isSender,
    required this.time,
    this.statusIcon,
    required this.conversationId,
    required this.messageId,
    required this.senderId,
    required this.currentUserId,
    required this.isDeletedForEveryone,
    required this.deletedFor,
    this.replyToMessageId,
    this.replyToText,
    this.replyToSenderId,
    this.onReply,
  });

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Delete message?'),
        children: [
          SimpleDialogOption(
            child: Text('Delete for me'),
            onPressed: () async {
              Navigator.pop(context);
              await deleteMessageForMe(conversationId, messageId, currentUserId);
            },
          ),
          if (senderId == currentUserId)
            SimpleDialogOption(
              child: Text('Delete for everyone'),
              onPressed: () async {
                Navigator.pop(context);
                await deleteMessageForEveryone(conversationId, messageId);
              },
            ),
          SimpleDialogOption(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isDeletedForEveryone) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "This message was deleted",
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[700]),
              ),
            ),
          ],
        ),
      );
    } else if (deletedFor.contains(currentUserId)) {
      return const SizedBox.shrink();
    }

    Widget content = Text(
      message,
      style: TextStyle(
        color: isSender ? Colors.white : Colors.black,
        fontSize: 16,
      ),
    );

    return GestureDetector(
      onLongPress: () {
        _showDeleteDialog(context);
      },
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0 && onReply != null) { 
          onReply!(messageId, message, senderId);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: isSender
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: IntrinsicWidth(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  decoration: BoxDecoration(
                    color: isSender ? AppTheme.primary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(8),
                      bottomLeft: Radius.circular(isSender ? 8 : 0),
                      bottomRight: Radius.circular(isSender ? 0 : 8),
                      topRight: const Radius.circular(8),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (replyToText != null)
                        Container(
                          margin: EdgeInsets.only(bottom: 4),
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(replyToText!, style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black87)),
                        ),
                      content,
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              time,
                              style: TextStyle(
                                color: isSender ? Colors.white : Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                            if (statusIcon != null) ...[
                              const SizedBox(width: 4),
                              statusIcon!,
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
