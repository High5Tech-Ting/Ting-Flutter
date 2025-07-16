import 'package:flutter/material.dart';
import 'package:ting/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:ting/features/profile/presentation/screens/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  final List<Widget> _pages = [
    const ChatListScreen(),
    Scaffold(body: Center(child: Text('Forum Screen'))),
    Scaffold(body: Center(child: Text('Groups Screen'))),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
            _pageController.jumpToPage(_currentIndex);
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat_outlined), label: 'Chat'),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            label: 'Forum',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            label: 'Groups',
          ),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Me'),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _pages,
      ),
    );
  }
}
