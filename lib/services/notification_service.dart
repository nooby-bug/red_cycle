  import 'package:flutter/foundation.dart';
  import 'package:flutter_local_notifications/flutter_local_notifications.dart';
  import 'package:flutter_timezone/flutter_timezone.dart';
  import 'package:permission_handler/permission_handler.dart';
  import 'package:timezone/data/latest.dart' as tz;
  import 'package:timezone/timezone.dart' as tz;
  import 'package:red/models/period_entry.dart';
  import 'package:red/services/prediction_service.dart';
  import 'package:red/models/prediction_data.dart';
  import 'package:red/utils/user_preferences.dart';


  class NotificationService {
    NotificationService._();
    static final NotificationService instance = NotificationService._();

    final PredictionService _predictionService = PredictionService();

    // --- Notification IDs ---
    static const int _dailyNotificationId = 1001;
    static const int _periodUpcomingId = 2001;
    static const int _periodStartId = 2002;
    static const int _ovulationId = 3001;
    static const int _fertileWindowId = 3002;
    static const int _baseAffirmationId = 5000;
    static const int _maxAffirmationFrequency = 10;

    static const String _channelId = 'daily_reminder_channel';
    static const String _channelName = 'Daily Reminders';
    static const String _channelDesc = 'Daily reminder notifications';

    final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
    bool _initialized = false;

    // ---------------------------------------------------------------------------
    // EXISTING PUBLIC API (UNCHANGED)
    // ---------------------------------------------------------------------------

    Future<void> refreshAllReminders({
      required List<PeriodEntry> history,
      required int hour,
      required int minute,
      required bool periodEnabled,
      required bool loggingEnabled,
    }) async {


      debugPrint("========================================");
      debugPrint("🔄 REFRESHING ALL REMINDERS");
      debugPrint("📊 History count: ${history.length}");
      debugPrint("⏰ Time: $hour:$minute");
      debugPrint("🩸 Period Enabled: $periodEnabled");
      debugPrint("📝 Logging Enabled: $loggingEnabled");

      assert(_initialized, 'Call init() first');

      debugPrint("🔁 REFRESHING ALL REMINDERS");

      await cancelAll();
      debugPrint("🧹 Cleared all existing notifications");

      // Daily reminder (logging)
      if (loggingEnabled) {
        debugPrint("➡️ Scheduling LOGGING reminders...");
        await scheduleDailyNotification(hour, minute);
      }

      // Cycle reminders
      if (periodEnabled) {
        debugPrint("➡️ Scheduling PERIOD reminders...");
        await scheduleCycleReminders(history);
      }
      debugPrint("✅ Refresh complete");
      debugPrint("========================================");
    }

    Future<void> init() async {
      if (_initialized) return;

      tz.initializeTimeZones();

      try {
        final TimezoneInfo timezoneInfo = await FlutterTimezone.getLocalTimezone();
        final String tzName = timezoneInfo.identifier;

        tz.setLocalLocation(tz.getLocation(tzName));
        debugPrint('NotificationService: timezone set to $tzName');
      } catch (e) {
        debugPrint('NotificationService: failed to resolve local tz ($e)');
      }

      const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initSettings =
      InitializationSettings(android: androidInit);

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

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

      debugPrint("🕒 DAILY REMINDER:");
      debugPrint("   Now → $now");
      debugPrint("   Scheduled → $scheduled");
      debugPrint("   Time → $hour:$minute");

      final todaysSlot = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

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
    // NEW SMART CYCLE REMINDER LOGIC
    // ---------------------------------------------------------------------------

    /// Schedules all relevant cycle-based reminders for the near future.
    Future<void> scheduleCycleReminders(List<PeriodEntry> history) async {
      assert(_initialized, 'Call init() first');
      debugPrint("--- Running Smart Cycle Reminder Scheduling ---");

      // 1. Cancel previous cycle reminders to avoid duplicates
      await _cancelCycleReminders();

      // 2. Validate data
      if (history.isEmpty) {
        debugPrint("⛔ No history → skipping cycle reminders");
        return;
      }

      if (history.length < 2) {
        debugPrint(
            "⛔ Not enough data (need ≥2 cycles) → skipping cycle reminders");
        return;
      }

  // 3. Calculate predictions

      final userCycleLength =
          await UserPreferences.getCycleLength() ?? 28;

      debugPrint("🧠 Calculating cycle prediction...");
      final prediction = _predictionService.getPredictionData(
        periodEntries: history,
        cycleLength: userCycleLength,
        today: DateTime.now(),
      );
      debugPrint("📊 Prediction:");
      debugPrint("   Next Period → ${prediction.nextPeriod}");
      debugPrint("   Ovulation   → ${prediction.ovulation}");
      debugPrint("   Fertile     → ${prediction.fertileStart} → ${prediction.fertileEnd}");

      final prefsCycleHour = await UserPreferences.getCycleReminderHour() ?? 9;
      final prefsCycleMinute = await UserPreferences.getCycleReminderMinute() ?? 0;

      final upcomingEvents = _getUpcomingEvents(
        prediction,
        prefsCycleHour,
        prefsCycleMinute,
      );

  // 4. Schedule each event
      for (final event in upcomingEvents) {
        await _scheduleOneTimeNotification(
          id: event['id'],
          title: event['title'],
          body: event['body'],
          scheduledDateTime: event['date'],
        );
      }
    }

    // ---------------------------------------------------------------------------
    // CYCLE PREDICTION HELPERS
    // ---------------------------------------------------------------------------

    /// Predicts key cycle dates based on the last period start.


    /// Gathers and filters all potential reminder events for the next 7 days.
    List<Map<String, dynamic>> _getUpcomingEvents(
        PredictionData prediction,
        int hour,
        int minute,
        ) {
      final now = tz.TZDateTime.now(tz.local);
      final sevenDaysFromNow = now.add(const Duration(days: 7));

      final Map<int, Map<String, dynamic>> events = {
        _periodUpcomingId: {
          'date': prediction.nextPeriod.subtract(const Duration(days: 2)),
          'title': '🩸 Period Coming Soon',
          'body': 'Your next period is predicted in 2 days.',
        },
        _periodStartId: {
          'date': prediction.nextPeriod,
          'title': '🩸 Period May Start Today',
          'body': 'Your period is predicted today.',
        },
        _ovulationId: {
          'date': prediction.ovulation,
          'title': '🌸 Ovulation Day',
          'body': 'Today is your ovulation day.',
        },
        _fertileWindowId: {
          'date': prediction.fertileStart,
          'title': '🌸 Fertile Window',
          'body': 'Fertile window begins today.',
        },
      };

      List<Map<String, dynamic>> result = [];

      events.forEach((id, data) {
        final DateTime eventDate = data['date'];

        final DateTime scheduled = DateTime(
          eventDate.year,
          eventDate.month,
          eventDate.day,
          hour,
          minute,
        );

        debugPrint("📅 EVENT CHECK:");
        debugPrint("   Title → ${data['title']}");
        debugPrint("   Raw Date → ${data['date']}");
        debugPrint("   FINAL Scheduled → $scheduled");
        debugPrint("   Using USER TIME → $hour:$minute");

        // ❌ Skip past events (unless today)
        if (scheduled.isBefore(now) &&
            !_isSameDay(scheduled, now)) {
          debugPrint("⛔ SKIPPED (past event)");
          return;
        }

        // ❌ Skip far future (>7 days)
        if (scheduled.isAfter(sevenDaysFromNow)) {
          debugPrint("⛔ SKIPPED (too far)");
          return;
        }

        result.add({
          'id': id,
          'title': data['title'],
          'body': data['body'],
          'date': scheduled,
        });
      });

      return result;
    }

    // ---------------------------------------------------------------------------
    // NOTIFICATION SCHEDULING HELPERS
    // ---------------------------------------------------------------------------

    /// Schedules a single, one-time notification for a future date.
    Future<void> _scheduleOneTimeNotification({
      required int id,
      required String title,
      required String body,
      required DateTime scheduledDateTime,
    }) async {
      final now = tz.TZDateTime.now(tz.local);

      // Fail-safe: If the scheduled time has already passed today, show immediately.
      if (scheduledDateTime.isBefore(now)) {
        debugPrint("SCHEDULED EVENT (IMMEDIATE): '$title' for now (was ${scheduledDateTime.toIso8601String()})");
        debugPrint("⚠️ Event time already passed → triggering immediately");
        debugPrint("   Title → $title");
        debugPrint("   Original → ${scheduledDateTime.toIso8601String()}");
        debugPrint("   Now → ${now.toIso8601String()}");
        await _plugin.show(
          id: id,
          title: title,
          body: body,
          notificationDetails: _notificationDetails(),
        );
        return;
      }

      debugPrint("🔔 SCHEDULED EVENT:");
      debugPrint("   Title → $title");
      debugPrint("   Time → ${scheduledDateTime.toIso8601String()}");
      debugPrint("   ID → $id");

      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledDateTime, tz.local),
        notificationDetails: _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,

      );
    }

    /// Cancels only the cycle-specific reminders, leaving the daily one intact.
    Future<void> _cancelCycleReminders() async {
      await _plugin.cancel(id: _periodUpcomingId);
      await _plugin.cancel(id: _periodStartId);
      await _plugin.cancel(id: _ovulationId);
      await _plugin.cancel(id: _fertileWindowId);
      debugPrint("CANCELLED: previous cycle reminders.");
    }

    bool _isSameDay(DateTime a, DateTime b) {
      return a.year == b.year && a.month == b.month && a.day == b.day;
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