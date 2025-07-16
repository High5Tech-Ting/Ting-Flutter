import 'package:flutter/material.dart';
import 'package:ting/features/chat/presentation/widgets/message_bubble.dart';
import 'package:ting/shared/theme.dart';

class ChatScreen extends StatelessWidget {
  final String userName;
  final String lastActiveTime;
  final String avatarUrl;
  final bool isOnline;

  const ChatScreen({
    super.key,
    required this.userName,
    required this.lastActiveTime,
    required this.avatarUrl,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 32,
        backgroundColor: AppTheme.primary100,
        title: Row(
          children: [
            CircleAvatar(radius: 20, backgroundImage: NetworkImage(avatarUrl)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName, style: TextStyle(fontSize: 20)),
                isOnline
                    ? const Text(
                        'Online',
                        style: TextStyle(color: Colors.green, fontSize: 14),
                      )
                    : Text(
                        'Last active: $lastActiveTime',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/chat_background.jpg'),
                  repeat: ImageRepeat.repeat,
                  opacity: 0.25,
                ),
                color: AppTheme.primary100,
              ),
              child: ListView.builder(
                itemCount: 20, // Example message count
                itemBuilder: (context, index) {
                  return MessageBubble(
                    message: 'Message $index',
                    isSender: index % 2 == 0,
                    time: '12:${index % 60} PM',
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              spacing: 8.0,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    maxLines: 5,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.send),
                  style: ButtonStyle(
                    iconColor: WidgetStatePropertyAll(AppTheme.surface),
                    backgroundColor: WidgetStatePropertyAll(AppTheme.primary),
                    padding: WidgetStatePropertyAll(EdgeInsets.all(10)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
