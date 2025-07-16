import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ting/features/auth/presentation/screens/auth_screen.dart';
import 'package:ting/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:ting/shared/widgets/main_navigation.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuth.instance;

    return StreamBuilder<User?>(
      stream: auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data != null && snapshot.data!.emailVerified) {
          return const MainNavigation();
        }

        if (snapshot.data != null && !snapshot.data!.emailVerified) {
          snapshot.data!.sendEmailVerification();
          return const EmailVerificationScreen();
        }

        return const AuthScreen();
      },
    );
  }
}
