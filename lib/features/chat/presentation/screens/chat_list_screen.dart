import 'package:flutter/material.dart';
import 'package:ting/features/chat/presentation/screens/chat_screen.dart';
import 'package:ting/features/chat/presentation/widgets/chat_list_item.dart';
import 'package:ting/shared/theme.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      setState(() {});
      print('Search input: ${controller.text}');
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        surfaceTintColor: AppTheme.surface,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: const TextStyle(color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: controller.text.isNotEmpty
                    ? GestureDetector(
                        child: const Icon(Icons.clear, color: Colors.grey),
                        onTap: () {
                          controller.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 25,
              itemBuilder: (context, index) {
                return ChatListItem(
                  userName: 'User $index',
                  lastMessage: 'Last message from user $index',
                  time: '12:34 PM',
                  avatarUrl: 'https://avatar.iran.liara.run/public',
                  newMessages: 5,
                  isOnline: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          userName: 'User $index',
                          lastActiveTime: '12:30 PM',
                          avatarUrl: 'https://avatar.iran.liara.run/public',
                          isOnline: false,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
