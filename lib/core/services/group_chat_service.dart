import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ting/core/models/group_model.dart';
import 'package:ting/core/models/user_model.dart';
import 'package:ting/shared/services/attachment_service.dart';
import 'package:ting/shared/services/base_message_service.dart';
import 'notification_service.dart';

class GroupChatService implements BaseMessageService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  static String get currentUserId => _auth.currentUser?.uid ?? '';

  // Create a new group
  static Future<String> createGroup({
    required String groupName,
    String? groupDescription,
    required List<String> memberIds,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    // Add current user to members if not already included
    final allMemberIds = Set<String>.from(memberIds);
    allMemberIds.add(currentUser.uid);

    final groupRef = _firestore.collection('groups').doc();

    final groupData = GroupChat(
      groupId: groupRef.id,
      groupName: groupName,
      groupDescription: groupDescription,
      memberIds: allMemberIds.toList(),
      createdBy: currentUser.uid,
      createdAt: Timestamp.now(),
      admins: [currentUser.uid], // Creator is admin by default
    );

    await groupRef.set(groupData.toMap());

    // Initialize unread messages for all members
    final unreadMessages = <String, int>{};
    for (String memberId in allMemberIds) {
      unreadMessages[memberId] = 0;
    }

    await groupRef.update({'unreadMessages': unreadMessages});

    return groupRef.id;
  }

  // Get user's groups
  static Stream<List<GroupChat>> getUserGroups() {
    return _firestore
        .collection('groups')
        .where('memberIds', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GroupChat.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Get all users for group creation
  static Stream<List<AppUser>> getAllUsers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) => doc.id != currentUserId)
              .map((doc) => AppUser.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Search users
  static Future<List<AppUser>> searchUsers(String query) async {
    final queryLower = query.toLowerCase();

    final snapshot = await _firestore.collection('users').get();

    return snapshot.docs
        .where((doc) => doc.id != currentUserId)
        .map((doc) => AppUser.fromMap(doc.data(), doc.id))
        .where(
          (user) =>
              user.displayName.toLowerCase().contains(queryLower) ||
              user.email.toLowerCase().contains(queryLower),
        )
        .toList();
  }

  // Send group message
  static Future<void> sendGroupMessage({
    required String groupId,
    required String messageText,
    String? replyToMessageId,
    String? replyToText,
    String? replyToSenderId,
    String? fileUrl,
    String? fileType,
    String? fileName,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    final messageRef = _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .doc();

    final message = GroupMessage(
      messageId: messageRef.id,
      senderId: currentUser.uid,
      groupId: groupId,
      text: messageText,
      timestamp: Timestamp.now(),
      replyToMessageId: replyToMessageId,
      replyToText: replyToText,
      replyToSenderId: replyToSenderId,
      fileUrl: fileUrl,
      fileType: fileType,
      fileName: fileName,
    );

    await messageRef.set(message.toMap());

    // Update group's last message
    final groupRef = _firestore.collection('groups').doc(groupId);
    final groupDoc = await groupRef.get();

    if (groupDoc.exists) {
      final groupData = groupDoc.data() as Map<String, dynamic>;
      final memberIds = List<String>.from(groupData['memberIds'] ?? []);
      final unreadMessages = Map<String, int>.from(
        groupData['unreadMessages'] ?? {},
      );

      // Update unread count for all members except sender
      for (String memberId in memberIds) {
        if (memberId != currentUser.uid) {
          unreadMessages[memberId] = (unreadMessages[memberId] ?? 0) + 1;
        } else {
          unreadMessages[memberId] = 0;
        }
      }

      String lastMessagePreview = messageText.isNotEmpty
          ? messageText
          : '${fileType?.toUpperCase() ?? 'File'} attachment';

      await groupRef.update({
        'lastMessage': lastMessagePreview,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadMessages': unreadMessages,
      });

      // Send notifications to group members
      await _sendGroupNotifications(
        groupId: groupId,
        groupName: groupData['groupName'] ?? 'Group',
        memberIds: memberIds,
        messageText: lastMessagePreview,
        senderEmail: currentUser.email ?? 'Unknown',
      );
    }
  }

  // Implementation of BaseMessageService interface
  @override
  Future<void> sendTextMessage({
    required String messageText,
    String? replyToMessageId,
    String? replyToText,
    String? replyToSenderId,
  }) async {
    throw UnimplementedError('Use sendGroupMessage with groupId parameter');
  }

  @override
  Future<void> sendAttachmentMessage({
    required String messageText,
    required File file,
    required String fileName,
    required String fileType,
    String? replyToMessageId,
    String? replyToText,
    String? replyToSenderId,
  }) async {
    throw UnimplementedError('Use sendGroupMessageWithAttachment method');
  }

  @override
  Future<String?> uploadFile({
    required File file,
    required String fileName,
    required String fileType,
    Map<String, String>? customMetadata,
  }) async {
    return await AttachmentService.uploadFile(
      file: file,
      fileName: fileName,
      fileType: fileType,
      folderPath: 'group_chat',
      customMetadata: customMetadata,
    );
  }

  // Send group message with attachment
  static Future<void> sendGroupMessageWithAttachment({
    required String groupId,
    required String messageText,
    required File file,
    required String fileName,
    required String fileType,
    String? replyToMessageId,
    String? replyToText,
    String? replyToSenderId,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    // Upload file first
    final fileUrl = await AttachmentService.uploadFile(
      file: file,
      fileName: fileName,
      fileType: fileType,
      folderPath: 'group_chat/$groupId',
      customMetadata: {
        'senderId': currentUser.uid,
        'groupId': groupId,
        'fileName': fileName,
        'fileType': fileType,
      },
    );

    if (fileUrl == null) {
      throw Exception('Failed to upload file');
    }

    // Send message with file URL
    await sendGroupMessage(
      groupId: groupId,
      messageText: messageText,
      replyToMessageId: replyToMessageId,
      replyToText: replyToText,
      replyToSenderId: replyToSenderId,
      fileUrl: fileUrl,
      fileType: fileType,
      fileName: fileName,
    );
  }

  // Get group messages stream
  static Stream<QuerySnapshot> getGroupMessagesStream(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Mark group messages as read
  static Future<void> markGroupMessagesAsRead(String groupId) async {
    final groupRef = _firestore.collection('groups').doc(groupId);

    await groupRef.update({'unreadMessages.$currentUserId': 0});
  }

  // Delete group message for user
  static Future<void> deleteGroupMessageForMe(
    String groupId,
    String messageId,
  ) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .doc(messageId)
        .update({
          'deletedFor': FieldValue.arrayUnion([currentUserId]),
        });
  }

  // Delete group message for everyone (admin only)
  static Future<void> deleteGroupMessageForEveryone(
    String groupId,
    String messageId,
  ) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .doc(messageId)
        .update({'isDeletedForEveryone': true});
  }

  // Add member to group (admin only)
  static Future<void> addMemberToGroup(String groupId, String userId) async {
    final groupRef = _firestore.collection('groups').doc(groupId);

    await groupRef.update({
      'memberIds': FieldValue.arrayUnion([userId]),
      'unreadMessages.$userId': 0,
    });
  }

  // Remove member from group (admin only)
  static Future<void> removeMemberFromGroup(
    String groupId,
    String userId,
  ) async {
    final groupRef = _firestore.collection('groups').doc(groupId);

    await groupRef.update({
      'memberIds': FieldValue.arrayRemove([userId]),
      'unreadMessages.$userId': FieldValue.delete(),
    });
  }

  // Leave group
  static Future<void> leaveGroup(String groupId) async {
    await removeMemberFromGroup(groupId, currentUserId);
  }

  // Get group details
  static Future<GroupChat?> getGroupById(String groupId) async {
    final doc = await _firestore.collection('groups').doc(groupId).get();
    if (doc.exists) {
      return GroupChat.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // Get group members
  static Future<List<AppUser>> getGroupMembers(String groupId) async {
    final group = await getGroupById(groupId);
    if (group == null) return [];

    final memberDocs = await Future.wait(
      group.memberIds.map((id) => _firestore.collection('users').doc(id).get()),
    );

    return memberDocs
        .where((doc) => doc.exists)
        .map((doc) => AppUser.fromMap(doc.data()!, doc.id))
        .toList();
  }

  // Update group info (admin only)
  static Future<void> updateGroupInfo({
    required String groupId,
    String? groupName,
    String? groupDescription,
    String? groupImageUrl,
  }) async {
    final updateData = <String, dynamic>{};

    if (groupName != null) updateData['groupName'] = groupName;
    if (groupDescription != null)
      updateData['groupDescription'] = groupDescription;
    if (groupImageUrl != null) updateData['groupImageUrl'] = groupImageUrl;

    if (updateData.isNotEmpty) {
      await _firestore.collection('groups').doc(groupId).update(updateData);
    }
  }

  // Private method to send notifications to group members
  static Future<void> _sendGroupNotifications({
    required String groupId,
    required String groupName,
    required List<String> memberIds,
    required String messageText,
    required String senderEmail,
  }) async {
    for (String memberId in memberIds) {
      if (memberId != currentUserId) {
        try {
          await NotificationService.instance.sendMessageNotification(
            receiverId: memberId,
            messageText: messageText,
            senderEmail: '$senderEmail (in $groupName)',
          );
        } catch (e) {
          print('Error sending notification to $memberId: $e');
        }
      }
    }
  }

  // Check if user is admin
  static Future<bool> isUserAdmin(String groupId, String userId) async {
    final group = await getGroupById(groupId);
    return group?.admins.contains(userId) ?? false;
  }

  // Make user admin (admin only)
  static Future<void> makeUserAdmin(String groupId, String userId) async {
    await _firestore.collection('groups').doc(groupId).update({
      'admins': FieldValue.arrayUnion([userId]),
    });
  }

  // Remove admin privileges (admin only)
  static Future<void> removeAdminPrivileges(
    String groupId,
    String userId,
  ) async {
    await _firestore.collection('groups').doc(groupId).update({
      'admins': FieldValue.arrayRemove([userId]),
    });
  }
}
