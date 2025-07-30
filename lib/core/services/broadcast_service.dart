import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ting/core/models/broadcast_model.dart';
import 'package:ting/core/models/user_model.dart';
import 'package:ting/core/models/group_model.dart';
import 'package:ting/core/services/notification_service.dart';
import 'package:ting/shared/services/attachment_service.dart';

class BroadcastService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  static String get currentUserId => _auth.currentUser?.uid ?? '';

  // Create a new broadcast
  static Future<String> createBroadcast({
    required String broadcastName,
    String? broadcastDescription,
    required List<String> userIds,
    required List<String> groupIds,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    final broadcastRef = _firestore.collection('broadcasts').doc();

    final broadcastData = Broadcast(
      broadcastId: broadcastRef.id,
      broadcastName: broadcastName,
      broadcastDescription: broadcastDescription,
      userIds: userIds,
      groupIds: groupIds,
      createdBy: currentUser.uid,
      createdAt: Timestamp.now(),
    );

    await broadcastRef.set(broadcastData.toMap());

    // Initialize unread messages for all recipients
    final unreadMessages = <String, int>{};

    // Add individual users
    for (String userId in userIds) {
      unreadMessages[userId] = 0;
    }

    // Add group members
    for (String groupId in groupIds) {
      final group = await getGroupById(groupId);
      if (group != null) {
        for (String memberId in group.memberIds) {
          unreadMessages[memberId] = 0;
        }
      }
    }

    await broadcastRef.update({'unreadMessages': unreadMessages});

    return broadcastRef.id;
  }

  // Get user's broadcasts (only broadcasts created by the user)
  static Stream<List<Broadcast>> getUserBroadcasts() {
    return _firestore
        .collection('broadcasts')
        .where('createdBy', isEqualTo: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Broadcast.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Send broadcast message
  static Future<void> sendBroadcastMessage({
    required String broadcastId,
    required String messageText,
    String? fileUrl,
    String? fileType,
    String? fileName,
    required String originalText,
    required bool isAppropriate,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    // Get broadcast details
    final broadcast = await getBroadcastById(broadcastId);
    if (broadcast == null) throw Exception('Broadcast not found');

    final messageRef = _firestore
        .collection('broadcasts')
        .doc(broadcastId)
        .collection('messages')
        .doc();

    final message = BroadcastMessage(
      messageId: messageRef.id,
      senderId: currentUser.uid,
      broadcastId: broadcastId,
      text: messageText,
      timestamp: Timestamp.now(),
      fileUrl: fileUrl,
      fileType: fileType,
      fileName: fileName,
      isAppropriate: isAppropriate,
      originalText: originalText,
    );

    await messageRef.set(message.toMap());

    // Update broadcast's last message
    String lastMessagePreview = messageText.isNotEmpty
        ? messageText
        : '${fileType?.toUpperCase() ?? 'File'} attachment';

    await _firestore.collection('broadcasts').doc(broadcastId).update({
      'lastMessage': lastMessagePreview,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    // Create individual conversations for each recipient
    await _createIndividualConversations(
      broadcast: broadcast,
      messageText: messageText,
      fileUrl: fileUrl,
      fileType: fileType,
      fileName: fileName,
      originalText: originalText,
      isAppropriate: isAppropriate,
    );
  }

  // Send broadcast message with attachment
  static Future<void> sendBroadcastMessageWithAttachment({
    required String broadcastId,
    required String messageText,
    required File file,
    required String fileName,
    required String fileType,
    required String originalText,
    required bool isAppropriate,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    // Upload file first
    final fileUrl = await AttachmentService.uploadFile(
      file: file,
      fileName: fileName,
      fileType: fileType,
      folderPath: 'broadcast/$broadcastId',
      customMetadata: {
        'senderId': currentUser.uid,
        'broadcastId': broadcastId,
        'fileName': fileName,
        'fileType': fileType,
      },
    );

    if (fileUrl == null) {
      throw Exception('Failed to upload file');
    }

    // Send message with file URL
    await sendBroadcastMessage(
      broadcastId: broadcastId,
      messageText: messageText,
      fileUrl: fileUrl,
      fileType: fileType,
      fileName: fileName,
      originalText: originalText,
      isAppropriate: isAppropriate,
    );
  }

  // Create individual conversations for broadcast recipients
  static Future<void> _createIndividualConversations({
    required Broadcast broadcast,
    required String messageText,
    String? fileUrl,
    String? fileType,
    String? fileName,
    required String originalText,
    required bool isAppropriate,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final currentUserId = currentUser.uid;

    // Handle individual users
    for (String userId in broadcast.userIds) {
      if (userId != currentUserId) {
        await _createConversationMessage(
          receiverId: userId,
          messageText: messageText,
          fileUrl: fileUrl,
          fileType: fileType,
          fileName: fileName,
          isAppropriate: isAppropriate,
          originalText: originalText,
        );
      }
    }

    // Handle groups - send to all group members
    for (String groupId in broadcast.groupIds) {
      final group = await getGroupById(groupId);
      if (group != null) {
        for (String memberId in group.memberIds) {
          if (memberId != currentUserId) {
            await _createConversationMessage(
              receiverId: memberId,
              messageText: messageText,
              fileUrl: fileUrl,
              fileType: fileType,
              fileName: fileName,
              isAppropriate: isAppropriate,
              originalText: originalText,
            );
          }
        }
      }
    }
  }

  // Create individual conversation message
  static Future<void> _createConversationMessage({
    required String receiverId,
    required String messageText,
    String? fileUrl,
    String? fileType,
    String? fileName,
    required String originalText,
    required bool isAppropriate,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final currentUserId = currentUser.uid;

    // Create or get conversation
    final conversationId = ([currentUserId, receiverId]..sort()).join('_');

    final messageRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc();

    await messageRef.set({
      'messageId': messageRef.id,
      'senderId': currentUserId,
      'receiverId': receiverId,
      'text': messageText,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sent',
      'delivered': false,
      'deliveredAt': null,
      'read': false,
      'readAt': null,
      'deletedFor': [],
      'isDeletedForEveryone': false,
      'replyToMessageId': null,
      'replyToText': null,
      'replyToSenderId': null,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'fileName': fileName,
      'originalText': originalText,
      'isAppropriate': isAppropriate,
    });

    // Update conversation metadata
    String lastMessagePreview = messageText.isNotEmpty
        ? messageText
        : '${fileType?.toUpperCase() ?? 'File'} attachment';

    await _firestore.collection('conversations').doc(conversationId).set({
      'lastMessage': lastMessagePreview,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'participants': [currentUserId, receiverId],
      'unreadMessages': {receiverId: 1, currentUserId: 0},
    }, SetOptions(merge: true));

    // Send notification
    try {
      await NotificationService.instance.sendMessageNotification(
        receiverId: receiverId,
        messageText: lastMessagePreview,
        senderEmail: currentUser.email ?? 'Unknown',
      );
    } catch (e) {
      print('Error sending notification to $receiverId: $e');
    }
  }

  // Get broadcast messages stream
  static Stream<QuerySnapshot> getBroadcastMessagesStream(String broadcastId) {
    return _firestore
        .collection('broadcasts')
        .doc(broadcastId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Get broadcast details
  static Future<Broadcast?> getBroadcastById(String broadcastId) async {
    final doc = await _firestore
        .collection('broadcasts')
        .doc(broadcastId)
        .get();
    if (doc.exists) {
      return Broadcast.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // Get group details (helper method)
  static Future<GroupChat?> getGroupById(String groupId) async {
    final doc = await _firestore.collection('groups').doc(groupId).get();
    if (doc.exists) {
      return GroupChat.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // Get all users for broadcast creation
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

  // Get user's groups for broadcast creation
  static Stream<List<GroupChat>> getUserGroups() {
    return _firestore
        .collection('groups')
        .where('memberIds', arrayContains: currentUserId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GroupChat.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Delete broadcast (only creator can delete)
  static Future<void> deleteBroadcast(String broadcastId) async {
    // Delete all messages first
    final messagesSnapshot = await _firestore
        .collection('broadcasts')
        .doc(broadcastId)
        .collection('messages')
        .get();

    final batch = _firestore.batch();
    for (var doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete the broadcast
    batch.delete(_firestore.collection('broadcasts').doc(broadcastId));

    await batch.commit();
  }

  // Update broadcast info (only creator can update)
  static Future<void> updateBroadcastInfo({
    required String broadcastId,
    String? broadcastName,
    String? broadcastDescription,
    List<String>? userIds,
    List<String>? groupIds,
  }) async {
    final updateData = <String, dynamic>{};

    if (broadcastName != null) updateData['broadcastName'] = broadcastName;
    if (broadcastDescription != null) {
      updateData['broadcastDescription'] = broadcastDescription;
    }
    if (userIds != null) updateData['userIds'] = userIds;
    if (groupIds != null) updateData['groupIds'] = groupIds;

    if (updateData.isNotEmpty) {
      await _firestore
          .collection('broadcasts')
          .doc(broadcastId)
          .update(updateData);
    }
  }

  // Get broadcast users by IDs
  static Future<List<AppUser>> getBroadcastUsers(List<String> userIds) async {
    if (userIds.isEmpty) return [];

    final userDocs = await Future.wait(
      userIds.map((id) => _firestore.collection('users').doc(id).get()),
    );

    return userDocs
        .where((doc) => doc.exists)
        .map((doc) => AppUser.fromMap(doc.data()!, doc.id))
        .toList();
  }

  // Get broadcast groups by IDs
  static Future<List<GroupChat>> getBroadcastGroups(
    List<String> groupIds,
  ) async {
    if (groupIds.isEmpty) return [];

    final groupDocs = await Future.wait(
      groupIds.map((id) => _firestore.collection('groups').doc(id).get()),
    );

    return groupDocs
        .where((doc) => doc.exists)
        .map((doc) => GroupChat.fromMap(doc.data()!, doc.id))
        .toList();
  }
}
