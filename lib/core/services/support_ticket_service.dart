import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:ting/core/models/support_ticket_model.dart';

class SupportTicketService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get current user ID
  static String get currentUserId => _auth.currentUser?.uid ?? '';

  /// Create a new support ticket
  static Future<String> createTicket({
    required String title,
    required String description,
    File? imageFile,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      // Upload image if provided
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await _uploadTicketImage(imageFile);
      }

      // Create ticket document
      final ticketRef = _firestore.collection('support_tickets').doc();
      
      final ticket = SupportTicket(
        ticketId: ticketRef.id,
        userId: currentUser.uid,
        title: title,
        description: description,
        imageUrl: imageUrl,
        status: TicketStatus.pending,
        createdAt: Timestamp.now(),
      );

      await ticketRef.set(ticket.toMap());

      // Add initial message with the description
      await addTicketMessage(
        ticketId: ticketRef.id,
        message: description,
      );

      return ticketRef.id;
    } catch (e) {
      throw Exception('Failed to create ticket: $e');
    }
  }

  /// Upload ticket image to Firebase Storage
  static Future<String?> _uploadTicketImage(File imageFile) async {
    try {
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filename = 'support_tickets/${currentUserId}_$timestamp';
      
      final storageRef = _storage.ref().child(filename);
      
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'userId': currentUserId},
      );

      final uploadTask = storageRef.putFile(imageFile, metadata);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading ticket image: $e');
      return null;
    }
  }

  /// Get user's support tickets (includes own tickets and assigned tickets)
  static Stream<List<SupportTicket>> getUserTickets() {
    return _firestore
        .collection('support_tickets')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          // Filter tickets that belong to user or are assigned to user
          final tickets = snapshot.docs
              .map((doc) => SupportTicket.fromMap(doc.data(), doc.id))
              .where((ticket) => 
                  ticket.userId == currentUserId || 
                  ticket.assignedTo == currentUserId)
              .toList();
          
          return tickets;
        });
  }

  /// Get tickets filtered by status (includes user's own tickets and assigned tickets)
  static Stream<List<SupportTicket>> getTicketsByStatus(TicketStatus status) {
    return _firestore
        .collection('support_tickets')
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          // Filter tickets that belong to user or are assigned to user
          final tickets = snapshot.docs
              .map((doc) => SupportTicket.fromMap(doc.data(), doc.id))
              .where((ticket) => 
                  ticket.userId == currentUserId || 
                  ticket.assignedTo == currentUserId)
              .toList();
          
          return tickets;
        });
  }

  /// Get all tickets filtered by status (for admin)
  static Stream<List<SupportTicket>> getAllTicketsByStatus(TicketStatus status) {
    return _firestore
        .collection('support_tickets')
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupportTicket.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get specific ticket by ID
  static Future<SupportTicket?> getTicketById(String ticketId) async {
    try {
      final doc = await _firestore
          .collection('support_tickets')
          .doc(ticketId)
          .get();
      
      if (doc.exists) {
        return SupportTicket.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error fetching ticket: $e');
      return null;
    }
  }

  /// Update ticket status (for admin use later)
  static Future<void> updateTicketStatus(String ticketId, TicketStatus status) async {
    try {
      await _firestore
          .collection('support_tickets')
          .doc(ticketId)
          .update({
            'status': status.name,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to update ticket status: $e');
    }
  }

  /// Add message to ticket
  static Future<void> addTicketMessage({
    required String ticketId,
    required String message,
    bool? isFromAdmin,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      // Auto-detect if user is admin or assigned to this ticket
      final bool isAdminUser = currentUser.uid == "i14bEX30GkT509oJz0pggxsRcs62";
      
      // Check if user is assigned to this ticket
      bool isAssignedUser = false;
      if (!isAdminUser) {
        final ticketDoc = await _firestore
            .collection('support_tickets')
            .doc(ticketId)
            .get();
        
        if (ticketDoc.exists) {
          final ticketData = ticketDoc.data();
          isAssignedUser = ticketData?['assignedTo'] == currentUser.uid;
        }
      }
      
      // Get user data for sender name
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      final userData = userDoc.data();
      final senderName = userData?['displayName'] ?? 
                        currentUser.displayName ?? 
                        currentUser.email ?? 
                        'Unknown User';

      final messageRef = _firestore
          .collection('support_tickets')
          .doc(ticketId)
          .collection('messages')
          .doc();

      final ticketMessage = TicketMessage(
        messageId: messageRef.id,
        ticketId: ticketId,
        senderId: currentUser.uid,
        senderName: senderName,
        message: message,
        isFromAdmin: isFromAdmin ?? (isAdminUser || isAssignedUser),
        createdAt: Timestamp.now(),
      );

      await messageRef.set(ticketMessage.toMap());

      // Update ticket's updatedAt timestamp
      await _firestore
          .collection('support_tickets')
          .doc(ticketId)
          .update({
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to add message: $e');
    }
  }

  /// Get ticket messages
  static Stream<List<TicketMessage>> getTicketMessages(String ticketId) {
    return _firestore
        .collection('support_tickets')
        .doc(ticketId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TicketMessage.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Delete ticket (soft delete - just update status to closed)
  static Future<void> deleteTicket(String ticketId) async {
    try {
      await updateTicketStatus(ticketId, TicketStatus.closed);
    } catch (e) {
      throw Exception('Failed to delete ticket: $e');
    }
  }
}
