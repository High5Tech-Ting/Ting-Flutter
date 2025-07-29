import 'package:cloud_firestore/cloud_firestore.dart';

class UserDataMigrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Migrate existing users to new structure
  static Future<void> migrateExistingUsers() async {
    try {
      print('Starting user data migration...');
      
      // Get all users
      final usersSnapshot = await _firestore.collection('users').get();
      
      for (var doc in usersSnapshot.docs) {
        final userData = doc.data();
        final userType = userData['userType'] as String? ?? 'student';
        
        Map<String, dynamic> updates = {};
        
        switch (userType.toLowerCase()) {
          case 'student':
            updates = await _getStudentUpdates(userData, doc.id);
            break;
          case 'lecturer':
            updates = await _getLecturerUpdates(userData, doc.id);
            break;
          case 'staff':
            updates = await _getStaffUpdates(userData, doc.id);
            break;
        }
        
        if (updates.isNotEmpty) {
          await doc.reference.update(updates);
          print('Updated ${userType}: ${userData['displayName']} (${doc.id})');
        }
      }
      
      print('Migration completed successfully!');
    } catch (e) {
      print('Error during migration: $e');
    }
  }

  static Future<Map<String, dynamic>> _getStudentUpdates(Map<String, dynamic> userData, String userId) async {
    Map<String, dynamic> updates = {};
    
    // Add studentId if missing
    if (!userData.containsKey('studentId') || userData['studentId'] == null || userData['studentId'] == '') {
      updates['studentId'] = 'STU${userId.substring(0, 6).toUpperCase()}'; // Generate from user ID
    }
    
    // Add batchNo if missing (try to use existing batch fields first)
    if (!userData.containsKey('batchNo') || userData['batchNo'] == null || userData['batchNo'] == '') {
      String? existingBatch = userData['batch_no'] ?? userData['batchNumber'] ?? userData['Batch No'] ?? userData['batch'];
      updates['batchNo'] = existingBatch ?? 'Batch 2024'; // Default batch
    }
    
    // Add optional fields with defaults
    if (!userData.containsKey('course')) {
      updates['course'] = 'Computer Science'; // Default course
    }
    
    if (!userData.containsKey('academicYear')) {
      updates['academicYear'] = 1; // Default academic year
    }
    
    return updates;
  }

  static Future<Map<String, dynamic>> _getLecturerUpdates(Map<String, dynamic> userData, String userId) async {
    Map<String, dynamic> updates = {};
    
    // Add lecturerId if missing
    if (!userData.containsKey('lecturerId') || userData['lecturerId'] == null || userData['lecturerId'] == '') {
      updates['lecturerId'] = 'LEC${userId.substring(0, 6).toUpperCase()}';
    }
    
    // Add modules if missing
    if (!userData.containsKey('modules') || userData['modules'] == null) {
      updates['modules'] = ['General Studies']; // Default module
    }
    
    // Add department if missing
    if (!userData.containsKey('department')) {
      updates['department'] = 'IT'; // Default department
    }
    
    // Add qualification if missing
    if (!userData.containsKey('qualification')) {
      updates['qualification'] = 'Bachelor\'s Degree'; // Default qualification
    }
    
    return updates;
  }

  static Future<Map<String, dynamic>> _getStaffUpdates(Map<String, dynamic> userData, String userId) async {
    Map<String, dynamic> updates = {};
    
    // Add staffId if missing
    if (!userData.containsKey('staffId') || userData['staffId'] == null || userData['staffId'] == '') {
      updates['staffId'] = 'STF${userId.substring(0, 6).toUpperCase()}';
    }
    
    // Add department if missing (using enum values)
    if (!userData.containsKey('department') || userData['department'] == null || userData['department'] == '') {
      updates['department'] = 'other'; // Default department
    }
    
    // Add position if missing
    if (!userData.containsKey('position')) {
      updates['position'] = 'Staff Member'; // Default position
    }
    
    return updates;
  }

  /// Update specific user manually
  static Future<void> updateStudentManually({
    required String userId,
    required String studentId,
    required String batchNo,
    String? course,
    int? academicYear,
  }) async {
    try {
      Map<String, dynamic> updates = {
        'studentId': studentId,
        'batchNo': batchNo,
        'userType': 'student',
      };
      
      if (course != null) updates['course'] = course;
      if (academicYear != null) updates['academicYear'] = academicYear;
      
      await _firestore.collection('users').doc(userId).update(updates);
      print('Student updated successfully: $userId');
    } catch (e) {
      print('Error updating student: $e');
    }
  }

  static Future<void> updateLecturerManually({
    required String userId,
    required String lecturerId,
    required List<String> modules,
    String? department,
    String? qualification,
  }) async {
    try {
      Map<String, dynamic> updates = {
        'lecturerId': lecturerId,
        'modules': modules,
        'userType': 'lecturer',
      };
      
      if (department != null) updates['department'] = department;
      if (qualification != null) updates['qualification'] = qualification;
      
      await _firestore.collection('users').doc(userId).update(updates);
      print('Lecturer updated successfully: $userId');
    } catch (e) {
      print('Error updating lecturer: $e');
    }
  }

  static Future<void> updateStaffManually({
    required String userId,
    required String staffId,
    required String department, // Use: 'it', 'studentSupport', 'finance', 'hr', 'admissions', 'library', 'maintenance', 'security', 'other'
    String? position,
    String? supervisor,
  }) async {
    try {
      Map<String, dynamic> updates = {
        'staffId': staffId,
        'department': department,
        'userType': 'staff',
      };
      
      if (position != null) updates['position'] = position;
      if (supervisor != null) updates['supervisor'] = supervisor;
      
      await _firestore.collection('users').doc(userId).update(updates);
      print('Staff updated successfully: $userId');
    } catch (e) {
      print('Error updating staff: $e');
    }
  }

  /// Example usage functions - call these from your app
  static Future<void> runExampleUpdates() async {
    // Example: Update a specific student
    await updateStudentManually(
      userId: 'your_student_user_id_here',
      studentId: 'STU001',
      batchNo: 'Batch 2024',
      course: 'Computer Science',
      academicYear: 2,
    );

    // Example: Update a specific lecturer
    await updateLecturerManually(
      userId: 'your_lecturer_user_id_here',
      lecturerId: 'LEC001',
      modules: ['Programming Fundamentals', 'Database Systems', 'Web Development'],
      department: 'Computer Science',
      qualification: 'PhD in Computer Science',
    );

    // Example: Update a specific staff member
    await updateStaffManually(
      userId: 'your_staff_user_id_here',
      staffId: 'STF001',
      department: 'it', // Use lowercase enum values
      position: 'System Administrator',
      supervisor: 'IT Manager',
    );
  }
}
