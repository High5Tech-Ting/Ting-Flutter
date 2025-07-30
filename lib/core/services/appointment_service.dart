import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ting/core/models/appointment_model.dart';

class AppointmentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  static String get currentUserId => _auth.currentUser?.uid ?? '';

  /// Create a new appointment
  static Future<String> createAppointment({
    required String title,
    required String description,
    String? lecturerId,
    String? lecturerName,
    required DateTime appointmentDate,
    required String timeSlot,
    required String location,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      // Create appointment document
      final appointmentRef = _firestore.collection('appointments').doc();
      
      final appointment = Appointment(
        appointmentId: appointmentRef.id,
        userId: currentUser.uid,
        title: title,
        description: description,
        lecturerId: lecturerId,
        lecturerName: lecturerName,
        appointmentDate: appointmentDate,
        timeSlot: timeSlot,
        location: location,
        status: AppointmentStatus.pending,
        createdAt: Timestamp.now(),
      );

      await appointmentRef.set(appointment.toMap());

      // Add initial message with the description
      await addAppointmentMessage(
        appointmentId: appointmentRef.id,
        message: description,
      );

      return appointmentRef.id;
    } catch (e) {
      throw Exception('Failed to create appointment: $e');
    }
  }

  /// Get user's appointments (includes own appointments and lecturer appointments)
  static Stream<List<Appointment>> getUserAppointments() {
    return _firestore
        .collection('appointments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          // Filter appointments that belong to user or lecturerId matches user
          final appointments = snapshot.docs
              .map((doc) => Appointment.fromMap(doc.data(), doc.id))
              .where((appointment) => 
                  appointment.userId == currentUserId || 
                  appointment.lecturerId == currentUserId)
              .toList();
          
          return appointments;
        });
  }

  /// Get appointments filtered by status (includes user's own appointments and lecturer appointments)
  static Stream<List<Appointment>> getAppointmentsByStatus(AppointmentStatus status) {
    return _firestore
        .collection('appointments')
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          // Filter appointments that belong to user or lecturerId matches user
          final appointments = snapshot.docs
              .map((doc) => Appointment.fromMap(doc.data(), doc.id))
              .where((appointment) => 
                  appointment.userId == currentUserId || 
                  appointment.lecturerId == currentUserId)
              .toList();
          
          return appointments;
        });
  }

  /// Get all appointments filtered by status (for admin)
  static Stream<List<Appointment>> getAllAppointmentsByStatus(AppointmentStatus status) {
    return _firestore
        .collection('appointments')
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Appointment.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get specific appointment by ID
  static Future<Appointment?> getAppointmentById(String appointmentId) async {
    try {
      final doc = await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .get();
      
      if (doc.exists) {
        return Appointment.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error fetching appointment: $e');
      return null;
    }
  }

  /// Update appointment status
  static Future<void> updateAppointmentStatus(String appointmentId, AppointmentStatus status) async {
    try {
      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .update({
            'status': status.name,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to update appointment status: $e');
    }
  }

  /// Add message to appointment
  static Future<void> addAppointmentMessage({
    required String appointmentId,
    required String message,
    bool? isFromLecturer,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      // Check if current user is a lecturer
      bool isLecturerUser = false;
      
      // Get appointment data to check if user is the lecturer
      final appointmentDoc = await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .get();
      
      if (appointmentDoc.exists) {
        final appointmentData = appointmentDoc.data();
        isLecturerUser = appointmentData?['lecturerId'] == currentUser.uid;
      }
      
      // Also check if user's type is lecturer from users collection
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      final userData = userDoc.data();
      final userType = userData?['userType'] as String?;
      if (userType == 'lecturer') {
        isLecturerUser = true;
      }
      
      final senderName = userData?['displayName'] ?? 
                        currentUser.displayName ?? 
                        currentUser.email ?? 
                        'Unknown User';

      final messageRef = _firestore
          .collection('appointments')
          .doc(appointmentId)
          .collection('messages')
          .doc();

      final appointmentMessage = AppointmentMessage(
        messageId: messageRef.id,
        appointmentId: appointmentId,
        senderId: currentUser.uid,
        senderName: senderName,
        message: message,
        isFromLecturer: isFromLecturer ?? isLecturerUser,
        createdAt: Timestamp.now(),
      );

      await messageRef.set(appointmentMessage.toMap());

      // Update appointment's updatedAt timestamp
      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .update({
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to add message: $e');
    }
  }

  /// Get appointment messages
  static Stream<List<AppointmentMessage>> getAppointmentMessages(String appointmentId) {
    return _firestore
        .collection('appointments')
        .doc(appointmentId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppointmentMessage.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Delete appointment (hard delete)
  static Future<void> deleteAppointment(String appointmentId) async {
    try {
      // Delete all messages first
      final messagesQuery = await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .collection('messages')
          .get();
      
      for (final doc in messagesQuery.docs) {
        await doc.reference.delete();
      }
      
      // Delete the appointment document
      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete appointment: $e');
    }
  }

  /// Check if current user can delete appointment
  static bool canDeleteAppointment(Appointment appointment) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    // User can delete if they created it or if they are the lecturer
    return appointment.userId == currentUser.uid || 
           appointment.lecturerId == currentUser.uid;
  }

  /// Get all lecturers for dropdown selection
  static Future<List<Map<String, dynamic>>> getAllLecturers() async {
    try {
      final lecturersSnapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'lecturer')
          .get();

      return lecturersSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'uid': doc.id,
          'displayName': data['displayName'] ?? 'Unknown Lecturer',
          'lecturerId': data['lecturerId'] ?? '',
        };
      }).toList();
    } catch (e) {
      print('Error fetching lecturers: $e');
      return [];
    }
  }
}
