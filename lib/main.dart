import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:ting/auth/presentation/widgets/auth_wrapper.dart';
import 'package:ting/firebase_options.dart';
import 'shared/theme.dart';

void main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ting',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
    );
  }
}
