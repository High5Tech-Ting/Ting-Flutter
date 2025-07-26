import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ting/core/models/broadcast_model.dart';
import 'package:ting/core/models/user_model.dart';
import 'package:ting/core/models/group_model.dart';
import 'package:ting/core/services/broadcast_service.dart';
import 'package:ting/shared/theme.dart';
import 'package:ting/shared/widgets/custom_clip_path.dart';

class BroadcastInfo extends StatefulWidget {
  final String broadcastId;
  final String broadcastName;

  const BroadcastInfo({
    super.key,
    required this.broadcastId,
    required this.broadcastName,
  });

  @override
  State<BroadcastInfo> createState() => _BroadcastInfoState();
}

class _BroadcastInfoState extends State<BroadcastInfo> {
  bool isLoading = true;
  Broadcast? broadcastData;
  List<AppUser> selectedUsers = [];
  List<GroupChat> selectedGroups = [];

  @override
  void initState() {
    super.initState();
    _loadBroadcastData();
  }

  Future<void> _loadBroadcastData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Get broadcast data
      final broadcast = await BroadcastService.getBroadcastById(
        widget.broadcastId,
      );
      if (broadcast != null && mounted) {
        broadcastData = broadcast;

        // Load selected users and groups
        final users = await BroadcastService.getBroadcastUsers(
          broadcast.userIds,
        );
        final groups = await BroadcastService.getBroadcastGroups(
          broadcast.groupIds,
        );

        if (mounted) {
          selectedUsers = users;
          selectedGroups = groups;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading broadcast data: $e')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(broadcastData?.broadcastName ?? widget.broadcastName),
        backgroundColor: AppTheme.primary100,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Broadcast header section
                  ClipPath(
                    clipper: CustomClipPath(),
                    child: _buildBroadcastHeader(),
                  ),

                  // Recipients section
                  if (selectedUsers.isNotEmpty) _buildUsersSection(),
                  if (selectedGroups.isNotEmpty) _buildGroupsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildBroadcastHeader() {
    return Container(
      color: AppTheme.primary100,
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      child: Column(
        children: [
          // Broadcast icon
          CircleAvatar(
            radius: 50,
            backgroundColor: AppTheme.primary,
            child: const Icon(
              Icons.broadcast_on_personal,
              color: Colors.white,
              size: 50,
            ),
          ),
          const SizedBox(height: 16),

          // Broadcast name
          Text(
            broadcastData?.broadcastName ?? widget.broadcastName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),

          // Description if available
          if (broadcastData?.broadcastDescription != null &&
              broadcastData!.broadcastDescription!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              broadcastData!.broadcastDescription!,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 16),

          // Creation date and recipient count
          Column(
            children: [
              Text(
                'Created ${DateFormat('MMM d, yyyy').format(broadcastData?.createdAt.toDate() ?? DateTime.now())}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                '${broadcastData?.totalRecipients ?? 0} recipients',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildUsersSection() {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          '${selectedUsers.length} individual users',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
        childrenPadding: EdgeInsets.zero,
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: selectedUsers.length,
            itemBuilder: (context, index) {
              final user = selectedUsers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.avatarUrl != null
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null
                      ? Text(
                          user.displayName.isNotEmpty
                              ? user.displayName[0].toUpperCase()
                              : '?',
                        )
                      : null,
                ),
                title: Text(user.displayName),
                subtitle: Text(user.email),
                trailing: user.online
                    ? Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsSection() {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          '${selectedGroups.length} groups',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
        childrenPadding: EdgeInsets.zero,
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: selectedGroups.length,
            itemBuilder: (context, index) {
              final group = selectedGroups[index];
              return ListTile(
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primary,
                  backgroundImage: group.groupImageUrl != null
                      ? NetworkImage(group.groupImageUrl!)
                      : null,
                  child: group.groupImageUrl == null
                      ? const Icon(Icons.group, color: Colors.white, size: 20)
                      : null,
                ),
                title: Text(group.groupName),
                subtitle: Text('${group.memberIds.length} members'),
              );
            },
          ),
        ],
      ),
    );
  }
}
