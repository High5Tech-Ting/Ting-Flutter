import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ting/features/lostFound/presentation/screens/create_new_posts.dart';
import 'package:ting/features/lostFound/presentation/widgets/lost_found_post.dart';
import 'package:ting/shared/theme.dart';

class LostFoundScreen extends StatefulWidget {
  const LostFoundScreen({super.key});

  @override
  State<LostFoundScreen> createState() => _LostFoundScreenState();
}

class _LostFoundScreenState extends State<LostFoundScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _searchQuery;

  @override
  void initState() {
    _searchController.addListener(() {
      setState(() {});
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
      _searchQuery = null;
    });
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query.isNotEmpty ? query.toLowerCase() : null;
    });
  }

  Stream<QuerySnapshot> _getPostsStream() {
    Query query = _firestore
        .collection('lost_found_items')
        .orderBy('createdAt', descending: true);

    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      return query
          .where('textLowerCase', isGreaterThanOrEqualTo: _searchQuery)
          .where('textLowerCase', isLessThanOrEqualTo: _searchQuery! + '\uf8ff')
          .snapshots();
    }

    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSearching ? _buildSearchAppBar() : _buildDefaultAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: _getPostsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading lost and found items: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final posts = snapshot.data?.docs ?? [];

            if (posts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'No lost or found items yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add a lost or found item'),
                      onPressed: () => _navigateToCreatePost(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: ListView.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  return LostFoundPost.fromFirestore(posts[index]);
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: !_isSearching
          ? FloatingActionButton(
              onPressed: _navigateToCreatePost,
              backgroundColor: AppTheme.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  void _navigateToCreatePost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateNewPosts()),
    );

    // If post was created successfully, refresh the list
    if (result == true) {
      setState(() {});
    }
  }

  AppBar _buildDefaultAppBar() {
    return AppBar(
      title: const Text('Lost & Found Items'),
      surfaceTintColor: AppTheme.surface,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          style: ButtonStyle(
            backgroundColor: const WidgetStatePropertyAll(AppTheme.primary100),
          ),
          onPressed: _startSearch,
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
          // Enable this for real-time search
          // _handleSearch(value);
        },
      ),
    );
  }
}
