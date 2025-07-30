import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ting/core/models/user_model.dart';

class UserSearchService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Search students by studentId
  static Future<List<BaseUser>> searchStudentsByStudentId(String studentId) async {
    if (studentId.trim().isEmpty) {
      return [];
    }

    try {
      final query = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'student')
          .where('studentId', isGreaterThanOrEqualTo: studentId.toUpperCase())
          .where('studentId', isLessThanOrEqualTo: '${studentId.toUpperCase()}\uf8ff')
          .get();

      return query.docs.map((doc) {
        final userData = doc.data();
        return UserFactory.createUser(userData, doc.id);
      }).toList();
    } catch (e) {
      print('Error searching students: $e');
      return [];
    }
  }

  // Search lecturers by lecturerId
  static Future<List<BaseUser>> searchLecturersByLecturerId(String lecturerId) async {
    if (lecturerId.trim().isEmpty) {
      return [];
    }

    try {
      final query = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'lecturer')
          .where('lecturerId', isGreaterThanOrEqualTo: lecturerId.toUpperCase())
          .where('lecturerId', isLessThanOrEqualTo: '${lecturerId.toUpperCase()}\uf8ff')
          .get();

      return query.docs.map((doc) {
        final userData = doc.data();
        return UserFactory.createUser(userData, doc.id);
      }).toList();
    } catch (e) {
      print('Error searching lecturers: $e');
      return [];
    }
  }

  // Search staff by staffId
  static Future<List<BaseUser>> searchStaffByStaffId(String staffId) async {
    if (staffId.trim().isEmpty) {
      return [];
    }

    try {
      final query = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'staff')
          .where('staffId', isGreaterThanOrEqualTo: staffId.toUpperCase())
          .where('staffId', isLessThanOrEqualTo: '${staffId.toUpperCase()}\uf8ff')
          .get();

      return query.docs.map((doc) {
        final userData = doc.data();
        return UserFactory.createUser(userData, doc.id);
      }).toList();
    } catch (e) {
      print('Error searching staff: $e');
      return [];
    }
  }

  // Search across all user types by their respective IDs
  static Future<List<BaseUser>> searchAllUsersByIds(String searchTerm) async {
    if (searchTerm.trim().isEmpty) {
      return [];
    }

    final futures = [
      searchStudentsByStudentId(searchTerm),
      searchLecturersByLecturerId(searchTerm),
      searchStaffByStaffId(searchTerm),
    ];

    final results = await Future.wait(futures);
    final allUsers = <BaseUser>[];
    
    for (final userList in results) {
      allUsers.addAll(userList);
    }

    return allUsers;
  }

  // Get all users of a specific type (for when search is cleared)
  static Stream<QuerySnapshot> getAllUsersOfType(String userType) {
    return _firestore
        .collection('users')
        .where('userType', isEqualTo: userType)
        .snapshots();
  }
}
