import 'dart:async';
import 'api_service.dart';
import 'notification_service.dart';

// The new backend has no server-triggered FCM push — it exposes a
// poll/ack API instead (GET .../notifications, POST .../notifications/ack-bulk).
// This means a notification only ever appears while the app is running
// (foreground, or right on resume) — not reliably when fully closed, the
// way a true push would. Deliberate simplification on the backend side, not
// an oversight here.
class NotificationPollingService {
  static Timer? _timer;
  static bool _polling = false;

  static Future<void> pollOnce() async {
    if (_polling) return; // avoid overlapping polls if one is slow
    _polling = true;
    try {
      final result = await ApiService.getPendingNotifications();
      if (result['statusCode'] != 200 || result['success'] != true) return;

      final items = (result['data'] as List).cast<Map<String, dynamic>>();
      if (items.isEmpty) return;

      for (final item in items) {
        final title = item['title'] as String?;
        final description = item['description'] as String?;
        if (title == null || description == null) continue;
        await NotificationService.showLocal(title: title, body: description);
      }

      final ids = items.map((item) => item['id'] as int).toList();
      await ApiService.ackNotificationsBulk(ids);
    } catch (_) {
      // Non-fatal — next poll cycle retries; nothing was ack'd so anything
      // shown-but-unacked would just be re-delivered (harmless duplicate)
      // rather than silently lost.
    } finally {
      _polling = false;
    }
  }

  // Call on login/app-resume. Polls immediately, then every 2 minutes while
  // the app stays foregrounded — pair with stop() on pause/detach.
  static void start() {
    pollOnce();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 2), (_) => pollOnce());
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
