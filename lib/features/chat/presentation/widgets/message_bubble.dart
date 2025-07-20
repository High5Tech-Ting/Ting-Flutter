import 'package:flutter/material.dart';
import 'package:ting/shared/theme.dart';
import 'dart:ui'; // Added for launchUrl
import 'package:url_launcher/url_launcher.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isSender;
  final String time;
  final Widget? statusIcon;
  final String? fileUrl; // Add this
  final String type; // Add this
  final String? fileName; // Add this

  const MessageBubble({
    super.key,
    required this.message,
    required this.isSender,
    required this.time,
    this.statusIcon,
    this.fileUrl,
    this.type = 'text',
    this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (type == 'image' && fileUrl != null) {
      content = Image.network(fileUrl!, fit: BoxFit.cover, width: 200, height: 200);
    } else if (type == 'video' && fileUrl != null) {
      content = Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            color: Colors.black12,
            child: Icon(Icons.videocam, size: 64, color: Colors.grey),
          ),
          Icon(Icons.play_circle_fill, size: 64, color: Colors.white70),
        ],
      );
    } else if (type == 'document' && fileUrl != null) {
      content = InkWell(
        onTap: () {
          // Open document URL
          launchUrl(Uri.parse(fileUrl!));
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file, color: Colors.blue),
            const SizedBox(width: 8),
            Flexible(child: Text(fileName ?? 'Document', style: TextStyle(decoration: TextDecoration.underline, color: Colors.blue))),
          ],
        ),
      );
    } else {
      content = Text(
        message,
        style: TextStyle(
          color: isSender ? Colors.white : Colors.black,
          fontSize: 16,
        ),
      );
    }
    return Padding(
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
    );
  }
}
