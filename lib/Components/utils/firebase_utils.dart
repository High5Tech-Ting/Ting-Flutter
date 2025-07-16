import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class FirebaseInitializer extends StatelessWidget {
  final Widget Function(BuildContext) builder;

  const FirebaseInitializer({Key? key, required this.builder}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(),
      builder: (context, snapshot) {
        // Check for errors
        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text(
                  'Error initializing Firebase: ${snapshot.error}',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.done) {
          return builder(context);
        }

        return MaterialApp(
          home: Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }
}

// Usage:
// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   runApp(FirebaseInitializer(
//     builder: (context) => MyApp(),
//   ));
// }