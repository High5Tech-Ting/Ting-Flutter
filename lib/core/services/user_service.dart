import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ting/core/models/user_model.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<String?> getProfilePictureUrl(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        return userData?['profilePictureUrl'] as String? ??
            userData?['avatarUrl'] as String?;
      }
      return null;
    } catch (e) {
      print('Error fetching profile picture URL: $e');
      return null;
    }
  }

  static Future<Map<String, String?>> getUserProfileData(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        return {
          'profilePictureUrl':
              userData?['profilePictureUrl'] as String? ??
              userData?['avatarUrl'] as String?,
          'displayName': userData?['displayName'] as String?,
        };
      }
      return {'profilePictureUrl': null, 'displayName': null};
    } catch (e) {
      print('Error fetching user profile data: $e');
      return {'profilePictureUrl': null, 'displayName': null};
    }
  }

  static Future<AppUser?> getUserById(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        return AppUser.fromMap(userDoc.data()!, userDoc.id);
      }
      return null;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  static Future<List<AppUser>> getUsersByIds(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return [];

      final userDocs = await Future.wait(
        userIds.map((id) => _firestore.collection('users').doc(id).get()),
      );

      return userDocs
          .where((doc) => doc.exists)
          .map((doc) => AppUser.fromMap(doc.data()!, doc.id))
          .toList();
    } catch (e) {
      print('Error fetching users data: $e');
      return [];
    }
  }
}
