const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

exports.sendNotification = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notification = snap.data();
    
    if (!notification.fcmToken) {
      console.log('No FCM token found for notification:', notification);
      return null;
    }

    const message = {
      token: notification.fcmToken,
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: {
        type: 'message',
        senderEmail: notification.senderEmail || '',
        message: notification.body || '',
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'high_importance_channel',
          priority: 'high',
          defaultSound: true,
          defaultVibrateTimings: true,
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    try {
      const response = await admin.messaging().send(message);
      console.log('Successfully sent notification:', response);
      
      // Update the notification status
      await snap.ref.update({
        status: 'sent',
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      return response;
    } catch (error) {
      console.error('Error sending notification:', error);
      
      // Update the notification status
      await snap.ref.update({
        status: 'failed',
        error: error.message,
      });
      
      throw error;
    }
  }); 