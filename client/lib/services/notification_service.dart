import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

// Must match the channelId used when displaying notifications below and the
// default_notification_channel_id meta-data in AndroidManifest.xml.
const _channel = AndroidNotificationChannel(
  'attendance_reminders',
  'Attendance Reminders',
  description: 'Reminders to complete today\'s check-in / check-out',
  importance: Importance.high,
);

final _localNotifications = FlutterLocalNotificationsPlugin();

// The backend sends data-only messages (no "notification" payload) so we
// fully control how the notification is displayed — in particular, using
// BigTextStyle so the whole message is readable by expanding it in the
// notification shade, without needing to tap into the app.
NotificationDetails _expandedDetails(String body) => NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(body),
      ),
    );

Future<void> _showFromData(Map<String, dynamic> data) async {
  final title = data['title'] as String?;
  final body = data['body'] as String?;
  if (title == null || body == null) return;
  await _localNotifications.show(
    id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
    title: title,
    body: body,
    notificationDetails: _expandedDetails(body),
  );
}

// Runs in a separate background isolate when a message arrives while the app
// is fully terminated or backgrounded — must be a top-level function
// annotated with vm:entry-point, and re-creates its own plugin/channel since
// it doesn't share state with the main isolate's NotificationService.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_channel);
  await plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  final title = message.data['title'] as String?;
  final body = message.data['body'] as String?;
  if (title == null || body == null) return;
  await plugin.show(
    id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
    title: title,
    body: body,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(body),
      ),
    ),
  );
}

class NotificationService {
  static Future<void> initialize() async {
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    // Data-only messages don't auto-display anything on Android — we build
    // and show the notification ourselves so it always uses BigTextStyle.
    FirebaseMessaging.onMessage.listen((message) => _showFromData(message.data));
  }

  // Requests notification permission (required on Android 13+, iOS) and, if
  // granted, registers this device's FCM token with the backend so it can
  // receive the 8:30 PM attendance reminder. Safe to call on every app
  // open/login — failures (permission denied, no network) are swallowed so
  // they never block the normal login/session flow.
  static Future<void> requestPermissionAndRegister() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      await ApiService.registerFcmToken(token);

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        ApiService.registerFcmToken(newToken);
      });
    } catch (_) {
      // Non-fatal — student just won't get push reminders this session.
    }
  }
}
