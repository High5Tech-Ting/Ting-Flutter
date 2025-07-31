import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ting/core/models/user_model.dart';

/// Service for managing admin user authentication and permissions
///
/// This service now checks the 'userType' field in the users collection
/// instead of using hardcoded admin user IDs. Users with userType: "admin"
/// are considered administrators.
///
/// Usage:
/// - Call AdminService.initialize() after Firebase initialization
/// - Use isCurrentUserAdminAsync() for accurate async admin checks
/// - Use isCurrentUserAdmin() for cached sync checks (may be inaccurate initially)
class AdminService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache for admin status to avoid repeated database calls
  static BaseUser? _currentUserCache;
  static bool? _currentUserAdminCache;

  /// Get current user from users database
  static Future<BaseUser?> getCurrentUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        _currentUserCache = UserFactory.createUser(userData, currentUser.uid);
        return _currentUserCache;
      }
      return null;
    } catch (e) {
      print('Error fetching current user: $e');
      return null;
    }
  }

  /// Initialize admin service - call this at app startup
  /// This will cache the current user's admin status for sync methods
  static Future<void> initialize() async {
    try {
      final user = await getCurrentUser();
      _currentUserAdminCache = user?.userType.toLowerCase() == 'admin';
    } catch (e) {
      print('Error initializing admin service: $e');
      _currentUserAdminCache = false;
    }
  }

  /// Clear cache when user signs out
  static void clearCache() {
    _currentUserCache = null;
    _currentUserAdminCache = null;
  }

  /// Check if current user is admin based on userType field (async)
  /// This is the most accurate method and should be preferred
  static Future<bool> isCurrentUserAdminAsync() async {
    final currentUser = await getCurrentUser();
    final isAdmin = currentUser?.userType.toLowerCase() == 'admin';
    _currentUserAdminCache = isAdmin;
    return isAdmin;
  }

  /// Check if current user is admin (sync - uses cache)
  /// This method uses cached data and may not be accurate on first call
  /// For accurate results, call initialize() first or use isCurrentUserAdminAsync()
  static bool isCurrentUserAdmin() {
    return _currentUserAdminCache ?? false;
  }

  /// Check if a specific user ID is admin based on userType field (async)
  /// This is the most accurate method for checking other users' admin status
  static Future<bool> isAdminAsync(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final userType = userData['userType'] as String?;
        return userType?.toLowerCase() == 'admin';
      }
      return false;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  /// Check if a specific user ID is admin (sync - for backward compatibility)
  /// This method only works accurately for the current user if cache is available
  /// Use isAdminAsync() for accurate results for any user
  static bool isAdmin(String userId) {
    // For the current user, use cache if available
    final currentUser = _auth.currentUser;
    if (currentUser?.uid == userId && _currentUserAdminCache != null) {
      return _currentUserAdminCache!;
    }

    // For other users or if no cache, return false to be safe
    // In production, consider migrating to async methods
    return false;
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
  static Future<void> assignTicket(
    String ticketId,
    String assigneeId,
    String assigneeName,
  ) async {
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

  /// Update user's admin status (promote/demote user)
  /// Only current admins should be able to call this method
  static Future<void> updateUserAdminStatus(String userId, bool isAdmin) async {
    // Check if current user is admin first
    final currentUserIsAdmin = await isCurrentUserAdminAsync();
    if (!currentUserIsAdmin) {
      throw Exception('Only administrators can modify admin status');
    }

    try {
      await _firestore.collection('users').doc(userId).update({
        'userType': isAdmin
            ? 'admin'
            : 'student', // Default to student if not admin
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // If we're updating the current user, refresh the cache
      final currentUser = _auth.currentUser;
      if (currentUser?.uid == userId) {
        _currentUserAdminCache = isAdmin;
      }
    } catch (e) {
      throw Exception('Failed to update user admin status: $e');
    }
  }

  /// Get user by ID with their admin status
  static Future<Map<String, dynamic>?> getUserWithAdminStatus(
    String userId,
  ) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return {
          ...userData,
          'isAdmin': userData['userType']?.toString().toLowerCase() == 'admin',
        };
      }
      return null;
    } catch (e) {
      print('Error fetching user: $e');
      return null;
    }
  }
}
