import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service untuk handle Firebase Cloud Messaging (Push Notifications)
class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize FCM dan request permission
  Future<void> initialize(String userId) async {
    try {
      // Request permission (iOS)
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ User granted notification permission');
      } else {
        debugPrint('⚠️ User declined notification permission');
        return;
      }

      // Get FCM token
      String? token = await _fcm.getToken();
      if (token != null) {
        debugPrint('📱 FCM Token: $token');
        // Save token to Firestore
        await _saveTokenToDatabase(userId, token);
      }

      // Listen for token refresh
      _fcm.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 FCM Token refreshed: $newToken');
        _saveTokenToDatabase(userId, newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages (when app is in background but not terminated)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Handle notification when app is opened from terminated state
      RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }

    } catch (e) {
      debugPrint('❌ Error initializing FCM: $e');
    }
  }

  /// Save FCM token to Firestore
  Future<void> _saveTokenToDatabase(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ FCM token saved to Firestore');
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  /// Handle foreground message (when app is open)
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📬 Foreground message received:');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');

    // You can show in-app notification here
    // Or update UI directly
  }

  /// Handle message when app is opened from notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('🔔 Notification tapped:');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');

    // Navigate to specific screen based on notification data
    // Example: if (message.data['type'] == 'payment') { navigate to payment screen }
  }

  /// Send notification to specific user
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get user's FCM token
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      String? fcmToken = userDoc.get('fcmToken');

      if (fcmToken == null) {
        debugPrint('⚠️ User $userId does not have FCM token');
        return;
      }

      // Save notification to Firestore (for notification history)
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'data': data ?? {},
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Notification saved to Firestore');
      
      // Note: Actual push notification sending requires Cloud Functions
      // This is just saving to database for now
      
    } catch (e) {
      debugPrint('❌ Error sending notification: $e');
    }
  }

  /// Send notification to all users with specific role
  Future<void> sendNotificationToRole({
    required String role,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get all users with specific role
      QuerySnapshot usersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: role)
          .get();

      // Send notification to each user
      for (var doc in usersSnapshot.docs) {
        await sendNotificationToUser(
          userId: doc.id,
          title: title,
          body: body,
          data: data,
        );
      }

      debugPrint('✅ Notifications sent to all $role users');
    } catch (e) {
      debugPrint('❌ Error sending notifications to role: $e');
    }
  }

  /// Get unread notifications count
  Stream<int> getUnreadNotificationsCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
    }
  }

  /// Delete FCM token (on logout)
  Future<void> deleteToken(String userId) async {
    try {
      await _fcm.deleteToken();
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
      });
      debugPrint('✅ FCM token deleted');
    } catch (e) {
      debugPrint('❌ Error deleting FCM token: $e');
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Background message received:');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
}
