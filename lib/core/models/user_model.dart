import 'package:cloud_firestore/cloud_firestore.dart';

// Base User class with common properties
abstract class BaseUser {
  final String uid;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final bool online;
  final Timestamp? lastSeen;
  final String? fcmToken;
  final String userType; // 'student', 'lecturer', 'staff'

  BaseUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.online = false,
    this.lastSeen,
    this.fcmToken,
    required this.userType,
  });

  // Common toMap method that all subclasses will use
  Map<String, dynamic> toBaseMap() {
    return {
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'online': online,
      'lastSeen': lastSeen,
      'fcmToken': fcmToken,
      'userType': userType,
    };
  }
}

// AppUser class that extends BaseUser (for backward compatibility)
class AppUser extends BaseUser {
  // Legacy fields for backward compatibility
  final String? studentId;
  final String? batchNo;

  AppUser({
    required String uid,
    required String email,
    required String displayName,
    String? avatarUrl,
    bool online = false,
    Timestamp? lastSeen,
    String? fcmToken,
    required String userType,
    this.studentId,
    this.batchNo,
  }) : super(
          uid: uid,
          email: email,
          displayName: displayName,
          avatarUrl: avatarUrl,
          online: online,
          lastSeen: lastSeen,
          fcmToken: fcmToken,
          userType: userType,
        );

  factory AppUser.fromMap(Map<String, dynamic> data, String uid) {
    return AppUser(
      uid: uid,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? 'Unknown User',
      // Priority: profilePictureUrl (uploaded images) -> avatarUrl (fallback)
      avatarUrl: data['profilePictureUrl'] as String? ?? data['avatarUrl'] as String?,
      online: data['online'] as bool? ?? false,
      lastSeen: data['lastSeen'] as Timestamp?,
      fcmToken: data['fcmToken'] as String?,
      userType: data['userType'] as String? ?? 'student',
      // Try different possible field names for batch number
      batchNo: data['batchNo'] as String? ?? 
               data['batch_no'] as String? ?? 
               data['batchNumber'] as String? ?? 
               data['Batch No'] as String? ?? 
               data['batch'] as String?,
      studentId: data['studentId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = toBaseMap();
    map.addAll({
      'studentId': studentId,
      'batchNo': batchNo,
    });
    return map;
  }
}

// Student model with specific fields
class Student extends BaseUser {
  final String studentId;
  final String batchNo;
  final String? course;
  final int? academicYear;

  Student({
    required String uid,
    required String email,
    required String displayName,
    String? avatarUrl,
    bool online = false,
    Timestamp? lastSeen,
    String? fcmToken,
    required this.studentId,
    required this.batchNo,
    this.course,
    this.academicYear,
  }) : super(
          uid: uid,
          email: email,
          displayName: displayName,
          avatarUrl: avatarUrl,
          online: online,
          lastSeen: lastSeen,
          fcmToken: fcmToken,
          userType: 'student',
        );

  factory Student.fromMap(Map<String, dynamic> data, String uid) {
    return Student(
      uid: uid,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? 'Unknown User',
      avatarUrl: data['profilePictureUrl'] as String? ?? data['avatarUrl'] as String?,
      online: data['online'] as bool? ?? false,
      lastSeen: data['lastSeen'] as Timestamp?,
      fcmToken: data['fcmToken'] as String?,
      studentId: data['studentId'] as String? ?? '',
      batchNo: data['batchNo'] as String? ?? 
               data['batch_no'] as String? ?? 
               data['batchNumber'] as String? ?? 
               data['Batch No'] as String? ?? 
               data['batch'] as String? ?? '',
      course: data['course'] as String?,
      academicYear: data['academicYear'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = toBaseMap();
    map.addAll({
      'studentId': studentId,
      'batchNo': batchNo,
      'course': course,
      'academicYear': academicYear,
    });
    return map;
  }
}

// Lecturer model with specific fields
class Lecturer extends BaseUser {
  final String lecturerId;
  final List<String> modules;
  final String? department;
  final String? qualification;

  Lecturer({
    required String uid,
    required String email,
    required String displayName,
    String? avatarUrl,
    bool online = false,
    Timestamp? lastSeen,
    String? fcmToken,
    required this.lecturerId,
    required this.modules,
    this.department,
    this.qualification,
  }) : super(
          uid: uid,
          email: email,
          displayName: displayName,
          avatarUrl: avatarUrl,
          online: online,
          lastSeen: lastSeen,
          fcmToken: fcmToken,
          userType: 'lecturer',
        );

  factory Lecturer.fromMap(Map<String, dynamic> data, String uid) {
    return Lecturer(
      uid: uid,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? 'Unknown User',
      avatarUrl: data['profilePictureUrl'] as String? ?? data['avatarUrl'] as String?,
      online: data['online'] as bool? ?? false,
      lastSeen: data['lastSeen'] as Timestamp?,
      fcmToken: data['fcmToken'] as String?,
      lecturerId: data['lecturerId'] as String? ?? '',
      modules: List<String>.from(data['modules'] ?? []),
      department: data['department'] as String?,
      qualification: data['qualification'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = toBaseMap();
    map.addAll({
      'lecturerId': lecturerId,
      'modules': modules,
      'department': department,
      'qualification': qualification,
    });
    return map;
  }
}

// Staff model with specific fields
class Staff extends BaseUser {
  final String staffId;
  final StaffDepartment department;
  final String? position;
  final String? supervisor;

  Staff({
    required String uid,
    required String email,
    required String displayName,
    String? avatarUrl,
    bool online = false,
    Timestamp? lastSeen,
    String? fcmToken,
    required this.staffId,
    required this.department,
    this.position,
    this.supervisor,
  }) : super(
          uid: uid,
          email: email,
          displayName: displayName,
          avatarUrl: avatarUrl,
          online: online,
          lastSeen: lastSeen,
          fcmToken: fcmToken,
          userType: 'staff',
        );

  factory Staff.fromMap(Map<String, dynamic> data, String uid) {
    return Staff(
      uid: uid,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? 'Unknown User',
      avatarUrl: data['profilePictureUrl'] as String? ?? data['avatarUrl'] as String?,
      online: data['online'] as bool? ?? false,
      lastSeen: data['lastSeen'] as Timestamp?,
      fcmToken: data['fcmToken'] as String?,
      staffId: data['staffId'] as String? ?? '',
      department: StaffDepartment.fromString(data['department'] as String? ?? 'other'),
      position: data['position'] as String?,
      supervisor: data['supervisor'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = toBaseMap();
    map.addAll({
      'staffId': staffId,
      'department': department.name,
      'position': position,
      'supervisor': supervisor,
    });
    return map;
  }
}

// Enum for Staff Departments
enum StaffDepartment {
  it('IT Department'),
  studentSupport('Student Support'),
  finance('Finance Department'),
  hr('Human Resources'),
  admissions('Admissions'),
  library('Library Services'),
  maintenance('Maintenance'),
  security('Security'),
  other('Other');

  const StaffDepartment(this.displayName);
  final String displayName;

  static StaffDepartment fromString(String value) {
    switch (value.toLowerCase()) {
      case 'it':
      case 'it department':
        return StaffDepartment.it;
      case 'student support':
      case 'studentsupport':
        return StaffDepartment.studentSupport;
      case 'finance':
      case 'finance department':
        return StaffDepartment.finance;
      case 'hr':
      case 'human resources':
        return StaffDepartment.hr;
      case 'admissions':
        return StaffDepartment.admissions;
      case 'library':
      case 'library services':
        return StaffDepartment.library;
      case 'maintenance':
        return StaffDepartment.maintenance;
      case 'security':
        return StaffDepartment.security;
      default:
        return StaffDepartment.other;
    }
  }
}

// Factory method to create appropriate user type from Firestore data
class UserFactory {
  static BaseUser createUser(Map<String, dynamic> data, String uid) {
    final userType = data['userType'] as String? ?? 'student';
    
    switch (userType.toLowerCase()) {
      case 'student':
        return Student.fromMap(data, uid);
      case 'lecturer':
        return Lecturer.fromMap(data, uid);
      case 'staff':
        return Staff.fromMap(data, uid);
      default:
        return AppUser.fromMap(data, uid);
    }
  }
}
