import 'package:flutter/material.dart';
import 'package:ting/core/models/user_model.dart';
import 'package:ting/core/models/group_model.dart';
import 'package:ting/core/services/broadcast_service.dart';
import 'package:ting/shared/theme.dart';

class CreateBroadcastScreen extends StatefulWidget {
  const CreateBroadcastScreen({super.key});

  @override
  State<CreateBroadcastScreen> createState() => _CreateBroadcastScreenState();
}

class _CreateBroadcastScreenState extends State<CreateBroadcastScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<AppUser> _selectedUsers = [];
  List<GroupChat> _selectedGroups = [];
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _createBroadcast() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a broadcast name')),
      );
      return;
    }

    if (_selectedUsers.isEmpty && _selectedGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one recipient')),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final userIds = _selectedUsers.map((user) => user.uid).toList();
      final groupIds = _selectedGroups.map((group) => group.groupId).toList();

      await BroadcastService.createBroadcast(
        broadcastName: _nameController.text.trim(),
        broadcastDescription: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        userIds: userIds,
        groupIds: groupIds,
      );

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Broadcast created successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating broadcast: $e')));
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Broadcast'),
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _createBroadcast,
            child: _isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Create',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Broadcast info section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Broadcast Name',
                    hintText: 'Enter broadcast name',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 50,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Enter broadcast description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  maxLength: 200,
                ),
              ],
            ),
          ),

          // Selected recipients summary
          if (_selectedUsers.isNotEmpty || _selectedGroups.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.primary.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.people, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedUsers.length + _selectedGroups.length} recipients selected',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users and groups...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),

          // Recipients list
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    labelColor: AppTheme.primary,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppTheme.primary,
                    dividerColor: Colors.grey[300],
                    tabs: const [
                      Tab(text: 'Users'),
                      Tab(text: 'Groups'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Users tab
                        StreamBuilder<List<AppUser>>(
                          stream: BroadcastService.getAllUsers(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Text('Error: ${snapshot.error}'),
                              );
                            }

                            final users = snapshot.data ?? [];
                            final searchQuery = _searchController.text
                                .toLowerCase();
                            final filteredUsers = users.where((user) {
                              if (searchQuery.isEmpty) return true;
                              return user.displayName.toLowerCase().contains(
                                    searchQuery,
                                  ) ||
                                  user.email.toLowerCase().contains(
                                    searchQuery,
                                  );
                            }).toList();

                            if (filteredUsers.isEmpty) {
                              return const Center(
                                child: Text('No users found'),
                              );
                            }

                            return ListView.builder(
                              itemCount: filteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = filteredUsers[index];
                                final isSelected = _selectedUsers.any(
                                  (u) => u.uid == user.uid,
                                );

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: user.avatarUrl != null
                                        ? NetworkImage(user.avatarUrl!)
                                        : null,
                                    child: user.avatarUrl == null
                                        ? Text(
                                            user.displayName.isNotEmpty
                                                ? user.displayName[0]
                                                      .toUpperCase()
                                                : '?',
                                          )
                                        : null,
                                  ),
                                  title: Text(user.displayName),
                                  subtitle: Text(user.email),
                                  trailing: Checkbox(
                                    value: isSelected,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        if (value == true) {
                                          _selectedUsers.add(user);
                                        } else {
                                          _selectedUsers.removeWhere(
                                            (u) => u.uid == user.uid,
                                          );
                                        }
                                      });
                                    },
                                  ),
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedUsers.removeWhere(
                                          (u) => u.uid == user.uid,
                                        );
                                      } else {
                                        _selectedUsers.add(user);
                                      }
                                    });
                                  },
                                );
                              },
                            );
                          },
                        ),

                        // Groups tab
                        StreamBuilder<List<GroupChat>>(
                          stream: BroadcastService.getUserGroups(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Text('Error: ${snapshot.error}'),
                              );
                            }

                            final groups = snapshot.data ?? [];
                            final searchQuery = _searchController.text
                                .toLowerCase();
                            final filteredGroups = groups.where((group) {
                              if (searchQuery.isEmpty) return true;
                              return group.groupName.toLowerCase().contains(
                                searchQuery,
                              );
                            }).toList();

                            if (filteredGroups.isEmpty) {
                              return const Center(
                                child: Text('No groups found'),
                              );
                            }

                            return ListView.builder(
                              itemCount: filteredGroups.length,
                              itemBuilder: (context, index) {
                                final group = filteredGroups[index];
                                final isSelected = _selectedGroups.any(
                                  (g) => g.groupId == group.groupId,
                                );

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppTheme.primary,
                                    backgroundImage: group.groupImageUrl != null
                                        ? NetworkImage(group.groupImageUrl!)
                                        : null,
                                    child: group.groupImageUrl == null
                                        ? const Icon(
                                            Icons.group,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                  title: Text(group.groupName),
                                  subtitle: Text(
                                    '${group.memberIds.length} members',
                                  ),
                                  trailing: Checkbox(
                                    value: isSelected,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        if (value == true) {
                                          _selectedGroups.add(group);
                                        } else {
                                          _selectedGroups.removeWhere(
                                            (g) => g.groupId == group.groupId,
                                          );
                                        }
                                      });
                                    },
                                  ),
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedGroups.removeWhere(
                                          (g) => g.groupId == group.groupId,
                                        );
                                      } else {
                                        _selectedGroups.add(group);
                                      }
                                    });
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
