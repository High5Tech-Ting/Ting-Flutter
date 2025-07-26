import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final bool online;
  final Timestamp? lastSeen;
  final String? fcmToken;
  final String? studentId;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.online = false,
    this.lastSeen,
    this.fcmToken,
    this.studentId,
  });

  factory AppUser.fromMap(Map<String, dynamic> data, String uid) {
    return AppUser(
      uid: uid,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? 'Unknown User',
      avatarUrl: data['avatarUrl'] as String?,
      online: data['online'] as bool? ?? false,
      lastSeen: data['lastSeen'] as Timestamp?,
      fcmToken: data['fcmToken'] as String?,
      studentId: data['studentId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'online': online,
      'lastSeen': lastSeen,
      'fcmToken': fcmToken,
      'studentId': studentId,
    };
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? avatarUrl,
    bool? online,
    Timestamp? lastSeen,
    String? fcmToken,
    String? studentId,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      online: online ?? this.online,
      lastSeen: lastSeen ?? this.lastSeen,
      fcmToken: fcmToken ?? this.fcmToken,
      studentId: studentId ?? this.studentId,
    );
  }
}
