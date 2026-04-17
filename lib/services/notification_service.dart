import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const int _dailyNotificationId = 1001;
  static const String _channelId = 'daily_reminder_channel';
  static const String _channelName = 'Daily Reminders';
  static const String _channelDesc = 'Daily reminder notifications';

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ---------------------------------------------------------------------------
  // PUBLIC API
  // ---------------------------------------------------------------------------

  Future<void> init() async {
    if (_initialized) return;

    // 1. Initialize timezone
    tz.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

      // ✅ FIX: correct variable used here
      debugPrint('NotificationService: timezone set to ${timezoneInfo.identifier}');
    } catch (e) {
      debugPrint(
        'NotificationService: failed to resolve local tz ($e), falling back to default.',
      );
    }

    // 2. Initialize plugin
    const androidInit =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidInit,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // 3. Create notification channel
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
      ),
    );

    _initialized = true;
    debugPrint('NotificationService: init complete');
  }

  Future<bool> requestPermission() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    final pluginGranted =
    await androidImpl?.requestNotificationsPermission();

    final status = await Permission.notification.request();

    final granted = (pluginGranted ?? false) || status.isGranted;
    debugPrint('NotificationService: permission granted = $granted');

    return granted;
  }

  Future<void> scheduleDailyNotification(int hour, int minute) async {
    assert(_initialized, 'Call init() first');

    await _plugin.cancel(id: _dailyNotificationId);

    final now = tz.TZDateTime.now(tz.local);
    final scheduled = _nextInstanceOf(hour, minute);

    debugPrint('NOW: $now');
    debugPrint('SCHEDULED: $scheduled');

    final todaysSlot = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // 🔥 Fail-safe
    if (todaysSlot.isBefore(now)) {
      debugPrint('TRIGGERED: immediate');

      await _plugin.show(
        id: _dailyNotificationId + 1,
        title: _title,
        body: _body,
        notificationDetails: _notificationDetails(),
      );
    }

    await _plugin.zonedSchedule(
      id: _dailyNotificationId,
      title: _title,
      body: _body,
      scheduledDate: scheduled,
      notificationDetails: _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_reminder',
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll(); // ✅ better than cancel(id)
    debugPrint('CANCELLED: all notifications');
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  static const String _title = 'Daily Reminder';
  static const String _body = 'Tap to open the app.';

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'daily_reminder',
        category: AndroidNotificationCategory.reminder,
      ),
    );
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('TRIGGERED: tap payload=${response.payload}');
  }
}