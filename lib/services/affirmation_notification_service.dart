import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class AffirmationNotificationService {
  // Singleton
  AffirmationNotificationService._privateConstructor();
  static final AffirmationNotificationService instance =
  AffirmationNotificationService._privateConstructor();

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static const int _baseNotificationId = 5000;
  static const int _maxFrequency = 10;

  bool _isInitialized = false;

  /// Initialize plugin
  Future<void> init() async {
    if (_isInitialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
    );

    await _plugin.initialize(
      settings: initSettings,
    );

    _isInitialized = true;
  }

  /// Schedule affirmations
  Future<void> scheduleDailyAffirmations({
    required List<String> affirmations,
    required int frequency,
  }) async {
    if (affirmations.isEmpty) return;
    if (!_isInitialized) await init();

    final safeFrequency = frequency.clamp(1, _maxFrequency);
    final random = Random();

    // Time window: 9 AM → 9 PM
    const int startMinute = 9 * 60;
    const int endMinute = 21 * 60;
    const int totalMinutes = endMinute - startMinute;

    final double slotDuration = totalMinutes / safeFrequency;

    const androidDetails = AndroidNotificationDetails(
      'affirmation_channel',
      'Daily Affirmations',
      channelDescription: 'Positive affirmations throughout your day',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const details = NotificationDetails(android: androidDetails);

    final now = tz.TZDateTime.now(tz.local);

    for (int i = 0; i < safeFrequency; i++) {
      final int slotStart =
          startMinute + (i * slotDuration).toInt();
      final int slotEnd =
          startMinute + ((i + 1) * slotDuration).toInt();

      // Prevent crash if range = 0
      final range = max(1, slotEnd - slotStart);

      final int randomTimeInMinutes =
          slotStart + random.nextInt(range);

      final int hour = randomTimeInMinutes ~/ 60;
      final int minute = randomTimeInMinutes % 60;

      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If time already passed → schedule tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final affirmation =
      affirmations[random.nextInt(affirmations.length)];

      await _plugin.zonedSchedule(
        id: _baseNotificationId + i,
        title: 'For you 💗',
        body: affirmation,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  /// Cancel only affirmation notifications
  Future<void> cancelAll() async {
    if (!_isInitialized) await init();

    for (int i = 0; i < _maxFrequency; i++) {
      await _plugin.cancel(
        id: _baseNotificationId + i,
      );
    }
  }

  /// Reschedule logic
  Future<void> reschedule({
    required bool isEnabled,
    required List<String> affirmations,
    required int frequency,
  }) async {
    await cancelAll();

    if (isEnabled && affirmations.isNotEmpty) {
      await scheduleDailyAffirmations(
        affirmations: affirmations,
        frequency: frequency,
      );
    }
  }
}