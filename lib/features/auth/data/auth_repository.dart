import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ting/features/auth/presentation/widgets/auth_wrapper.dart';

class AuthRepository {
  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  static Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential.user;
  }

  static Future<void> signOut(BuildContext context) async {
    await _firebaseAuth.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AuthWrapper()),
      (route) => false,
    );
  }

  static Future<void> sendVerification() async {
    await _firebaseAuth.currentUser?.sendEmailVerification();
  }

  static User? currentUser() {
    return _firebaseAuth.currentUser;
  }

  static Future<void> resetPassword(BuildContext context, String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Password reset email sent.')));
  }
}
