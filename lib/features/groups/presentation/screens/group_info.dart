import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ting/core/models/group_model.dart';
import 'package:ting/core/models/user_model.dart';
import 'package:ting/core/services/group_chat_service.dart';
import 'package:ting/features/groups/data/group_image_service.dart';
import 'package:ting/features/groups/presentation/widgets/add_group_members_dialog.dart';
import 'package:ting/features/groups/presentation/widgets/group_member_item.dart';
import 'package:ting/shared/theme.dart';
import 'package:ting/shared/widgets/custom_clip_path.dart';

class GroupInfo extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String? groupImageUrl;

  const GroupInfo({
    super.key,
    required this.groupId,
    required this.groupName,
    this.groupImageUrl,
  });

  @override
  State<GroupInfo> createState() => _GroupInfoState();
}

class _GroupInfoState extends State<GroupInfo> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = true;
  bool isNameEditing = false;
  bool isImageUploading = false;
  bool isAdmin = false;
  GroupChat? groupData;
  List<AppUser> members = [];
  final TextEditingController _groupNameController = TextEditingController();

  String get currentUserId => _auth.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadGroupData();
  }

  Future<void> _loadGroupData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Get group data
      final group = await GroupChatService.getGroupById(widget.groupId);
      if (group != null && mounted) {
        groupData = group;
        _groupNameController.text = group.groupName;

        // Check if current user is admin
        isAdmin = group.admins.contains(currentUserId);

        // Load members
        members = await GroupChatService.getGroupMembers(widget.groupId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading group data: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _updateGroupName() async {
    final newName = _groupNameController.text.trim();
    if (newName.isEmpty || newName == groupData?.groupName) {
      setState(() {
        isNameEditing = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await GroupChatService.updateGroupInfo(
        groupId: widget.groupId,
        groupName: newName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group name updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating group name: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          isNameEditing = false;
        });
        _loadGroupData();
      }
    }
  }

  Future<void> _handleImageUpload() async {
    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only admins can change the group icon')),
      );
      return;
    }

    setState(() {
      isImageUploading = true;
    });

    try {
      // Pick image directly from gallery
      final imageFile = await GroupImageService.pickAndValidateImage(
        context,
        source: ImageSource.gallery,
      );

      if (imageFile == null) {
        setState(() {
          isImageUploading = false;
        });
        return;
      }

      // Upload image
      final downloadUrl = await GroupImageService.uploadGroupImage(
        imageFile,
        widget.groupId,
      );

      if (downloadUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image')),
          );
        }
        return;
      }

      // Update group image URL in Firestore
      await GroupChatService.updateGroupInfo(
        groupId: widget.groupId,
        groupImageUrl: downloadUrl,
      );

      await _loadGroupData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group image updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          isImageUploading = false;
        });
      }
    }
  }

  Future<void> _showAddMembersDialog() async {
    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only admins can add members')),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddGroupMembersDialog(
        groupId: widget.groupId,
        existingMemberIds: members.map((m) => m.uid).toList(),
      ),
    );

    if (result == true) {
      await _loadGroupData();
    }
  }

  Future<void> _toggleAdminStatus(AppUser user) async {
    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only admins can manage admin privileges'),
        ),
      );
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      final isUserAdmin = groupData!.admins.contains(user.uid);

      if (isUserAdmin) {
        // Prevent removing the last admin
        if (groupData!.admins.length <= 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot remove the last admin')),
          );
          return;
        }
        await GroupChatService.removeAdminPrivileges(widget.groupId, user.uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Removed admin privileges from ${user.displayName}',
              ),
            ),
          );
        }
      } else {
        await GroupChatService.makeUserAdmin(widget.groupId, user.uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Made ${user.displayName} an admin')),
          );
        }
      }

      await _loadGroupData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating admin status: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _removeMember(AppUser user) async {
    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only admins can remove members')),
      );
      return;
    }

    if (user.uid == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot remove yourself. Use Leave Group instead.'),
        ),
      );
      return;
    }

    // Confirm removal
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove ${user.displayName} from the group?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() {
        isLoading = true;
      });

      await GroupChatService.removeMemberFromGroup(widget.groupId, user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${user.displayName} has been removed from the group',
            ),
          ),
        );
      }

      await _loadGroupData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error removing member: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _leaveGroup() async {
    // Confirm leaving
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text('Are you sure you want to leave this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Check if user is the last admin
    if (isAdmin && groupData!.admins.length <= 1) {
      final assignNewAdmin = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Assign New Admin'),
          content: const Text(
            'You are the last admin. You must assign another admin before leaving.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Assign'),
            ),
          ],
        ),
      );

      if (assignNewAdmin != true) return;

      // Filter out current user to show potential new admins
      final potentialAdmins = members
          .where((m) => m.uid != currentUserId)
          .toList();
      if (potentialAdmins.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('There are no other members to make admin'),
          ),
        );
        return;
      }

      // Show dialog to select new admin
      final selectedUser = await showDialog<AppUser?>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select New Admin'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: potentialAdmins.length,
              itemBuilder: (context, index) {
                final user = potentialAdmins[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user.avatarUrl != null
                        ? CachedNetworkImageProvider(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl == null
                        ? Text(user.displayName[0].toUpperCase())
                        : null,
                  ),
                  title: Text(user.displayName),
                  onTap: () => Navigator.of(context).pop(user),
                );
              },
            ),
          ),
        ),
      );

      if (selectedUser == null) return;

      // Make selected user an admin
      try {
        await GroupChatService.makeUserAdmin(widget.groupId, selectedUser.uid);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error assigning new admin: $e')),
          );
        }
        return;
      }
    }

    // Leave the group
    try {
      setState(() {
        isLoading = true;
      });

      await GroupChatService.removeMemberFromGroup(
        widget.groupId,
        currentUserId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have left the group')),
        );
        Navigator.of(context).pop(); // Go back to previous screen
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error leaving group: $e')));
      }
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(groupData?.groupName ?? widget.groupName),
        backgroundColor: AppTheme.primary100,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group icon and name section
                  ClipPath(
                    clipper: CustomClipPath(),
                    child: _buildGroupHeader(),
                  ),

                  // Group members section
                  _buildMembersSection(),

                  // Admin actions
                  if (isAdmin)
                    ListTile(
                      leading: const Icon(Icons.person_add),
                      title: const Text('Add members'),
                      onTap: _showAddMembersDialog,
                    ),

                  // Leave group option
                  ListTile(
                    leading: const Icon(Icons.exit_to_app, color: Colors.red),
                    title: const Text(
                      'Leave Group',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: _leaveGroup,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildGroupHeader() {
    return Container(
      color: AppTheme.primary100,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Group icon
          GestureDetector(
            onTap: isAdmin ? _handleImageUpload : null,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.primary,
                  backgroundImage:
                      (groupData?.groupImageUrl != null && !isImageUploading)
                      ? CachedNetworkImageProvider(groupData!.groupImageUrl!)
                      : null,
                  child: isImageUploading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : (groupData?.groupImageUrl == null
                            ? const Icon(
                                Icons.group,
                                color: Colors.white,
                                size: 50,
                              )
                            : null),
                ),
                if (isAdmin)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Group name
          _buildGroupNameSection(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildGroupNameSection() {
    if (isNameEditing) {
      return Row(
        children: [
          Expanded(
            child: TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                hintText: 'Enter group name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _updateGroupName,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _groupNameController.text = groupData!.groupName;
                isNameEditing = false;
              });
            },
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              groupData?.groupName ?? widget.groupName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  isNameEditing = true;
                });
              },
            ),
        ],
      );
    }
  }

  Widget _buildMembersSection() {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          '${members.length} members',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
        childrenPadding: EdgeInsets.zero,
        children: [
          // Members list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              final isMemberAdmin =
                  groupData?.admins.contains(member.uid) ?? false;
              final isCurrentUser = member.uid == currentUserId;

              return GroupMemberItem(
                member: member,
                isMemberAdmin: isMemberAdmin,
                isCurrentUser: isCurrentUser,
                isUserAdmin: isAdmin,
                onToggleAdmin: _toggleAdminStatus,
                onRemoveMember: _removeMember,
              );
            },
          ),
        ],
      ),
    );
  }
}
