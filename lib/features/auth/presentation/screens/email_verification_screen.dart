import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ting/features/auth/data/auth_repository.dart';
import 'package:ting/shared/theme.dart';
import 'package:ting/shared/widgets/main_navigation.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _emailVerificationCheck();
  }

  void _emailVerificationCheck() {
    _timer = Timer.periodic(Duration(seconds: 2), (timer) async {
      await AuthRepository.currentUser()?.reload();
      final user = AuthRepository.currentUser();
      if (user != null && user.emailVerified) {
        timer.cancel();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Email verified successfully!')));
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
          (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 80),
              Image.asset('assets/images/email_sent.png', width: 240),
              const SizedBox(height: 32),
              const Text('Check your email.', style: AppTheme.headingLarge),
              const SizedBox(height: 16),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppTheme.bodyMedium,
                  children: [
                    const TextSpan(text: "We sent a verification link to "),
                    TextSpan(
                      text: AuthRepository.currentUser()?.email ?? '',
                      style: AppTheme.bodyMedium.copyWith(
                        fontVariations: [FontVariation('wght', 600)],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  await AuthRepository.sendVerification();
                },
                child: const Text('Send Verification Email'),
              ),
              const SizedBox(height: 16),

              TextButton.icon(
                onPressed: () async {
                  await AuthRepository.signOut(context);
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
