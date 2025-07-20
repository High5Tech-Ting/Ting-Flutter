import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';

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
      .map((snapshot) => snapshot.docs
      .map((doc) => Message.fromMap(doc.data()))
      .toList());
}

Future<void> deleteMessageForMe(String conversationId, String messageId, String userId) async {
  await FirebaseFirestore.instance
      .collection('conversations')
      .doc(conversationId)
      .collection('messages')
      .doc(messageId)
      .update({
        'deletedFor': FieldValue.arrayUnion([userId])
      });
}

Future<void> deleteMessageForEveryone(String conversationId, String messageId) async {
  await FirebaseFirestore.instance
      .collection('conversations')
      .doc(conversationId)
      .collection('messages')
      .doc(messageId)
      .update({
        'isDeletedForEveryone': true
      });
}

