import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'progress_store.dart';

/// Local-only daily reminder. No network, no analytics, no remote payloads.
class NotificationService {
  NotificationService._();

  static const int _reminderId = 1;
  static const String _channelId = 'wikato_daily';
  static const String _channelName = 'Daily reminders';
  static const String _channelDescription =
      'A daily nudge to practice your phrases.';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      ),
    );
    _initialized = true;
  }

  /// Requests OS-level permission to show notifications. Returns true if
  /// granted. Call only after the user has opted in to a reminder.
  static Future<bool> requestPermission() async {
    await init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      if (granted == false) return false;
    }
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (granted == false) return false;
    }
    return true;
  }

  /// Schedules a single daily notification at [hour] (0–23) in local time.
  /// Replaces any existing schedule. Uses [DateTimeComponents.time] so the
  /// OS repeats it every day.
  static Future<void> scheduleDaily(int hour) async {
    await init();
    await _plugin.cancel(id: _reminderId);

    final now = DateTime.now();
    var firstFire = DateTime(now.year, now.month, now.day, hour);
    if (!firstFire.isAfter(now)) {
      firstFire = firstFire.add(const Duration(days: 1));
    }
    // Use TZDateTime in UTC keyed off the local epoch ms — sidesteps needing
    // the device's IANA timezone name. DST shifts will move the firing time
    // by one hour twice a year; acceptable for a soft daily reminder.
    final scheduled = tz.TZDateTime.fromMillisecondsSinceEpoch(
      tz.UTC,
      firstFire.millisecondsSinceEpoch,
    );

    final body = _bodyForStreak(ProgressStore.streakDays.value);

    await _plugin.zonedSchedule(
      id: _reminderId,
      title: 'Wikato',
      body: body,
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  static String _bodyForStreak(int streak) {
    if (streak > 0) return 'Keep your $streak-day streak alive';
    return 'Ready for 5 phrases today?';
  }
}
