import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages are handled here
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  late FlutterLocalNotificationsPlugin _localNotifications;
  static const _channelId = 'game_topup_channel';
  static const _channelName = 'GameTopup Notifications';

  Future<void> initialize() async {
    // 1. Request permissions
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
    );

    // 2. Initialize local notifications
    _localNotifications = FlutterLocalNotificationsPlugin();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // 3. Create Android channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'إشعارات تحديث حالة الطلبات',
      importance: Importance.high,
      enableVibration: true,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 4. Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForeground);

    // 5. Background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 6. Message opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpened);

    // 7. App opened from terminated state via notification
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _handleOpened(initial);
  }

  void _handleForeground(RemoteMessage message) {
    _showLocalNotification(
      title: message.notification?.title ?? 'GameTopup',
      body: message.notification?.body ?? '',
      payload: jsonEncode(message.data),
    );
  }

  void _handleOpened(RemoteMessage message) {
    // Navigation handling can be added here using a global navigator key
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'إشعارات GameTopup',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  /// Send push notification via FCM HTTP v1 API.
  /// NOTE: In production, this should be done from Cloud Functions
  /// (not from the client) to keep the server key secret.
  /// This is provided as a reference implementation.
  Future<void> sendToTokens({
    required List<String> tokens,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    if (tokens.isEmpty) return;

    // For production, call your backend / Cloud Function instead.
    // Example Cloud Function endpoint:
    // await http.post(
    //   Uri.parse('https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/sendNotification'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode({'tokens': tokens, 'title': title, 'body': body, 'data': data}),
    // );
  }

  /// Show a local notification (call from admin when updating order status)
  Future<void> showLocalNotification(String title, String body) async {
    await _showLocalNotification(title: title, body: body);
  }
}
