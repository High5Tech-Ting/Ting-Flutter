import 'package:flutter/material.dart';
import 'package:ting/features/forum/presentation/widgets/forum_post.dart';
import 'package:ting/shared/theme.dart';

class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    _searchController.addListener(() {
      setState(() {});
      print('Search input: ${_searchController.text}');
    });
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
    });
  }

  void _handleSearch(String query) {
    print('Searching for: $query');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSearching ? _buildSearchAppBar() : _buildDefaultAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: 2, // Example item count
          itemBuilder: (context, index) {
            return const ForumPost(); // Replace with actual post widget
          },
        ),
      ),
    );
  }

  AppBar _buildDefaultAppBar() {
    return AppBar(
      title: const Text('Forum'),
      surfaceTintColor: AppTheme.surface,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(AppTheme.primary100),
          ),
          onPressed: _startSearch,
        ),
        IconButton(
          icon: const Icon(Icons.add),
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(AppTheme.primary100),
          ),
          onPressed: () {
            print('Create new post tapped');
          },
        ),
      ],
    );
  }

  AppBar _buildSearchAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _stopSearch,
      ),
      leadingWidth: 32.0,
      title: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Search',
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.grey[500]),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? GestureDetector(
                  child: const Icon(Icons.clear, color: Colors.grey),
                  onTap: () {
                    _searchController.clear();
                    _stopSearch();
                  },
                )
              : null,
        ),
        style: const TextStyle(fontSize: 16, color: AppTheme.textPrimary),
        onSubmitted: _handleSearch,
        onChanged: (value) {
          // Optional: real-time search as user types
          // _handleSearch(value);
        },
      ),
    );
  }
}
