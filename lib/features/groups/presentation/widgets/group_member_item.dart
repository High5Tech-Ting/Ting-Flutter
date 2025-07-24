import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ting/Components/models/user_model.dart';
import 'package:ting/shared/theme.dart';

class GroupMemberItem extends StatelessWidget {
  final AppUser member;
  final bool isMemberAdmin;
  final bool isCurrentUser;
  final bool isUserAdmin;
  final Function(AppUser)? onToggleAdmin;
  final Function(AppUser)? onRemoveMember;

  const GroupMemberItem({
    super.key,
    required this.member,
    required this.isMemberAdmin,
    required this.isCurrentUser,
    required this.isUserAdmin,
    this.onToggleAdmin,
    this.onRemoveMember,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: member.avatarUrl != null
            ? CachedNetworkImageProvider(member.avatarUrl!)
            : null,
        child: member.avatarUrl == null
            ? Text(
                member.displayName.isNotEmpty
                    ? member.displayName[0].toUpperCase()
                    : '?',
              )
            : null,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(member.displayName, overflow: TextOverflow.ellipsis),
          ),
          if (isMemberAdmin)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Admin',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
        ],
      ),
      subtitle: Text(
        isCurrentUser ? 'You' : member.email,
        style: const TextStyle(fontSize: 12),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isUserAdmin && !isCurrentUser
          ? PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'toggle_admin') {
                  onToggleAdmin?.call(member);
                } else if (value == 'remove') {
                  onRemoveMember?.call(member);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'toggle_admin',
                  child: Row(
                    children: [
                      Icon(
                        isMemberAdmin
                            ? Icons.person_remove
                            : Icons.admin_panel_settings,
                        color: isMemberAdmin ? Colors.red : Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isMemberAdmin ? 'Remove admin status' : 'Make admin',
                        style: TextStyle(
                          color: isMemberAdmin ? Colors.red : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      const Icon(Icons.remove_circle, color: Colors.red),
                      const SizedBox(width: 8),
                      const Text(
                        'Remove from group',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : null,
    );
  }
}
