import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:ting/core/services/notification_service.dart';
import 'package:ting/features/auth/presentation/widgets/auth_wrapper.dart';
import 'package:ting/firebase_options.dart';
import 'package:ting/services/widget_service.dart';
import 'shared/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.instance.initialize();

  // Initialize WorkManager for background tasks
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  // Initialize widget service
  await WidgetService.initialize();

  runApp(const MyApp());
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Handle background widget updates
    return Future.value(true);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ting',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: AuthWrapper(),
    );
  }
}
