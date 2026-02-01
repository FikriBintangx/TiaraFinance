import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


/// Urusin pesan pas aplikasi bobok
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("📱 Background Message: ${message.notification?.title}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  int _notificationCount = 0;
  
  /// Siapin tentara notifikasi (FCM & Lokal)
  Future<void> initialize() async {
    // Minta izin dulu sama Apple user
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ User granted notification permission');
    } else {
      print('⚠️ User declined notification permission');
    }

    // Siapin notifikasi lokal
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Bikin jalur khusus notif Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'tiara_finance_channel',
      'Tiara Finance Notifications',
      description: 'Notifikasi untuk pembayaran dan transaksi',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Urusin pesan pas lagi buka aplikasi
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Kalo notif dipencet pas app di background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Get FCM token
    String? token = await _fcm.getToken();
    print('📱 FCM Token: $token');
  }

  /// Urusin pesan pas lagi buka aplikasi
  void _handleForegroundMessage(RemoteMessage message) {
    print('📩 Foreground Message: ${message.notification?.title}');
    
    _notificationCount++;
    
    // Show local notification with badge
    _showLocalNotification(
      title: message.notification?.title ?? 'Notifikasi Baru',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }

  /// Kalo notif dipencet
  void _handleNotificationTap(RemoteMessage message) {
    print('👆 Notification tapped: ${message.notification?.title}');
    // PR: Arahin ke layar yang bener (nanti ya)
  }

  /// Pas notifikasi lokal disentuh
  void _onNotificationTapped(NotificationResponse response) {
    print('👆 Local notification tapped: ${response.payload}');
    // PR: Arahin ke layar yang bener (nanti ya)
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'tiara_finance_channel',
      'Tiara Finance Notifications',
      channelDescription: 'Notifikasi untuk pembayaran dan transaksi',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(''),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Munculin notif manual (buat tes doang)
  Future<void> showNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    _notificationCount++;
    await _showLocalNotification(
      title: title,
      body: body,
      payload: data?.toString(),
    );
  }

  /// Get notification count
  int get notificationCount => _notificationCount;

  /// Reset notification count
  void resetNotificationCount() {
    _notificationCount = 0;
  }

  /// Langganan topik buat notif massal
  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
    print('✅ Subscribed to topic: $topic');
  }

  /// Berhenti langganan dari topik
  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
    print('❌ Unsubscribed from topic: $topic');
  }

  /// Get FCM token
  Future<String?> getToken() async {
    return await _fcm.getToken();
  }
}
