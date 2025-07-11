import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ting/auth/presentation/screens/auth_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final _auth = FirebaseAuth.instance;

    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          print("User is not logged in");
          return const AuthScreen();
        }

        if (snapshot.data != null && snapshot.data!.emailVerified) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Ting'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () {
                    _auth.signOut();
                  },
                ),
              ],
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Welcome to Ting!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Logged in as: ${snapshot.data?.email}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        // User is logged in but email is not verified
        return Scaffold(
          backgroundColor: Colors.amber,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Please verify your email',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    _auth.signOut();
                  },
                  child: const Text('Back to Sign In'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
