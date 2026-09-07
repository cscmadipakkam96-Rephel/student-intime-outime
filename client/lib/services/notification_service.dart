import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

// Must match the channelId the backend sends under (android.notification.channelId
// in attendanceReminder.service.js) and the default_notification_channel_id
// meta-data in AndroidManifest.xml.
const _channel = AndroidNotificationChannel(
  'attendance_reminders',
  'Attendance Reminders',
  description: 'Reminders to complete today\'s check-in / check-out',
  importance: Importance.high,
);

final _localNotifications = FlutterLocalNotificationsPlugin();

// Runs when a data/notification message arrives while the app is fully
// terminated or backgrounded. Must be a top-level (or static) function
// annotated with vm:entry-point so the background isolate can find it.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class NotificationService {
  // Android only shows a system notification for messages received while the
  // app is in the foreground if we display it ourselves — FCM's own
  // "notification" payload is silently dropped in that state otherwise.
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

    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    });
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
