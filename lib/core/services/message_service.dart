import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ting/core/models/message_model.dart';

Future<void> sendMessage(String receiverPhone, String content) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return;

  await FirebaseFirestore.instance.collection('messages').add({
    'senderId': currentUser.uid,
    'receiverId': receiverPhone,
    'content': content,
    'timestamp': FieldValue.serverTimestamp(),
    'status': 'pending',
  });
}

Stream<List<Message>> getMessagesStream(String userId) {
  return FirebaseFirestore.instance
      .collection('messages')
      .where('receiverId', isEqualTo: userId)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => Message.fromMap(doc.data())).toList(),
      );
}

Future<void> deleteMessageForMe(
  String conversationId,
  String messageId,
  String userId,
) async {
  // Try to delete from conversations first (regular chats)
  try {
    final conversationDoc = await FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .get();

    if (conversationDoc.exists) {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .update({
            'deletedFor': FieldValue.arrayUnion([userId]),
          });
      return;
    }
  } catch (e) {
    print('Not a conversation message, trying groups...');
  }

  // If not found in conversations, try groups
  try {
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({
          'deletedFor': FieldValue.arrayUnion([userId]),
        });
  } catch (e) {
    print('Error deleting message for user: $e');
  }
}

Future<void> deleteMessageForEveryone(
  String conversationId,
  String messageId,
) async {
  // Try to delete from conversations first (regular chats)
  try {
    final conversationDoc = await FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .get();

    if (conversationDoc.exists) {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .update({'isDeletedForEveryone': true});
      return;
    }
  } catch (e) {
    print('Not a conversation message, trying groups...');
  }

  // If not found in conversations, try groups
  try {
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({'isDeletedForEveryone': true});
  } catch (e) {
    print('Error deleting message for everyone: $e');
  }
}
