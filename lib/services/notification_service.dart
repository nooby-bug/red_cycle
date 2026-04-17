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
  // PUBLIC API (matches your existing UI calls)
  // ---------------------------------------------------------------------------

  Future<void> init() async {
    if (_initialized) return;

    // 1. Initialize timezone database + set device-local tz explicitly.
    tz.initializeTimeZones();
    try {
      final String localTz = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTz));
      debugPrint('NotificationService: timezone set to $localTz');
    } catch (e) {
      debugPrint('NotificationService: failed to resolve local tz ($e), '
          'falling back to default. Notifications may fire in UTC.');
    }

    // 2. Initialize the plugin (Android only here; add iOS settings if needed).
    const AndroidInitializationSettings androidInit =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // 3. Pre-create the channel (Android 8+) so importance/sound are correct
    //    on first delivery.
    final AndroidFlutterLocalNotificationsPlugin? androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
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

  /// Requests notification permission.
  /// Android 13+ requires POST_NOTIFICATIONS at runtime.
  /// Returns true if granted.
  Future<bool> requestPermission() async {
    // Plugin-level request (Android 13+).
    final AndroidFlutterLocalNotificationsPlugin? androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    final bool? pluginGranted =
    await androidImpl?.requestNotificationsPermission();

    // Fallback / double-check via permission_handler (covers older devices
    // and gives a single source of truth for the UI).
    final PermissionStatus status = await Permission.notification.request();

    final bool granted = (pluginGranted ?? false) || status.isGranted;
    debugPrint('NotificationService: permission granted = $granted');
    return granted;
  }

  /// Schedules a daily notification at [hour]:[minute] (24h, device-local time).
  /// If that time has already passed today, fires once immediately and then
  /// schedules tomorrow's occurrence.
  Future<void> scheduleDailyNotification(int hour, int minute) async {
    assert(_initialized, 'Call NotificationService.instance.init() first');

    // Always cancel the previous schedule before re-scheduling so we never
    // end up with stacked duplicates after the user changes the time.
    await _plugin.cancel(id: _dailyNotificationId);

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    final tz.TZDateTime scheduled = _nextInstanceOf(hour, minute);

    debugPrint('NOW:       $now');
    debugPrint('SCHEDULED: $scheduled (daily at $hour:${minute.toString().padLeft(2, '0')})');

    // Fail-safe: if the user-chosen time is in the past for today, fire now.
    // _nextInstanceOf already rolls forward to tomorrow, so we just need to
    // detect "originally in the past" and trigger an immediate show.
    final tz.TZDateTime todaysSlot = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (todaysSlot.isBefore(now)) {
      debugPrint('TRIGGERED: immediate (chosen time already passed today)');
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
    await _plugin.cancel(id: _dailyNotificationId);
    debugPrint('CANCELLED: all notifications');
  }

  // ---------------------------------------------------------------------------
  // INTERNAL HELPERS
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

  /// Returns the next [tz.TZDateTime] matching [hour]:[minute] in device-local
  /// time. If the time has already passed today, rolls forward to tomorrow.
  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
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
    // Hook your navigation / deep-link logic here.
  }
}