import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Admin user ID
  static const String adminUserId = "i14bEX30GkT509oJz0pggxsRcs62";
  
  /// Check if current user is admin
  static bool isCurrentUserAdmin() {
    final currentUser = _auth.currentUser;
    return currentUser?.uid == adminUserId;
  }
  
  /// Get all users for assignment dropdown
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'uid': doc.id,
          'displayName': data['displayName'] ?? 'Unknown User',
          'email': data['email'] ?? '',
        };
      }).toList();
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }
  
  /// Assign ticket to a user
  static Future<void> assignTicket(String ticketId, String assigneeId, String assigneeName) async {
    try {
      await _firestore.collection('support_tickets').doc(ticketId).update({
        'assignedTo': assigneeId,
        'assignedToName': assigneeName,
        'assignedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to assign ticket: $e');
    }
  }
  
  /// Update ticket status
  static Future<void> updateTicketStatus(String ticketId, String status) async {
    try {
      await _firestore.collection('support_tickets').doc(ticketId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update ticket status: $e');
    }
  }
}
