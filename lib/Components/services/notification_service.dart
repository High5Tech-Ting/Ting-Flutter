import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// This function must be outside any class
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.instance.setupFlutterNotifications();
  await NotificationService.instance.showNotification(message);
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isFlutterLocalNotificationsInitialized = false;

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await _requestPermission();
    await setupFlutterNotifications();
    await setupMessageHandlers();
    await _saveTokenToDatabase();

    final token = await _messaging.getToken();
    print('FCM Token: $token');
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('Permission status: ${settings.authorizationStatus}');
  }

  Future<void> _saveTokenToDatabase() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final token = await _messaging.getToken();
        if (token != null) {
          await _firestore.collection('users').doc(user.uid).set({
            'fcmToken': token,
            'email': user.email,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          print('FCM token saved for user: ${user.email}');
        }
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  Future<void> setupFlutterNotifications() async {
    if (_isFlutterLocalNotificationsInitialized) return;

    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const initializationSettingsDarwin = DarwinInitializationSettings();

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Notification tapped: ${response.payload}');
      },
    );

    _isFlutterLocalNotificationsInitialized = true;
  }

  Future<void> showNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  Future<void> setupMessageHandlers() async {
    FirebaseMessaging.onMessage.listen((message) {
      showNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessage(initialMessage);
    }
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    if (message.data['type'] == 'chat') {
      // Handle chat tap
      print('User tapped on a chat notification');
    } else {
      print('Opened from background: ${message.data}');
    }
  }

  // Simple method to send notification when a message is sent
  Future<void> sendMessageNotification({
    required String receiverId,
    required String messageText,
    required String senderEmail,
  }) async {
    try {
      // Get receiver's FCM token
      DocumentSnapshot receiverDoc = await _firestore.collection('users').doc(receiverId).get();
      
      if (receiverDoc.exists) {
        final receiverData = receiverDoc.data() as Map<String, dynamic>?;
        String? fcmToken = receiverData?['fcmToken'] as String?;
        
        if (fcmToken != null) {
          // Create notification document for Cloud Function to process
          await _firestore.collection('notifications').add({
            'receiverId': receiverId,
            'fcmToken': fcmToken,
            'title': 'New message from $senderEmail',
            'body': messageText,
            'senderEmail': senderEmail,
            'timestamp': FieldValue.serverTimestamp(),
            'status': 'pending',
          });
          
          print('Message notification queued for: $receiverId');
        } else {
          print('No FCM token found for receiver: $receiverId');
        }
      } else {
        print('Receiver document not found: $receiverId');
      }
    } catch (e) {
      print('Error sending message notification: $e');
    }
  }
}
