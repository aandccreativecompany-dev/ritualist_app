import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'models.dart';

/// Local scheduled notifications. No server, no push, works offline.
class Notifications {
  Notifications._();
  static final Notifications instance = Notifications._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialised = false;

  static const _channelId = 'ritualist_daily';
  static const _channelName = 'Daily reminders';
  static const _channelDescription =
      'Your mantra, open tasks, and the evening close.';

  Future<void> init() async {
    if (_initialised) return;

    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // Fall back to UTC rather than crash on an unknown zone name.
    }

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _initialised = true;
  }

  /// Ask once, when the user turns reminders on — never at launch.
  Future<bool> requestPermission() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return false;
    final granted = await android.requestNotificationsPermission();
    return granted ?? false;
  }

  Future<bool> permissionGranted() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return false;
    final enabled = await android.areNotificationsEnabled();
    return enabled ?? false;
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(''),
        ),
      );

  tz.TZDateTime _nextInstance(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstance(hour, minute),
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Rebuilds the whole schedule. Called on launch, on edit, and after reboot
  /// (the OS drops pending alarms when the device restarts).
  Future<void> scheduleAll({
    required List<ReminderSetting> reminders,
    required String mantra,
    required List<String> openTasks,
  }) async {
    await init();
    await _plugin.cancelAll();

    if (!await permissionGranted()) return;

    for (final reminder in reminders) {
      if (!reminder.enabled) continue;

      switch (reminder.id) {
        case 'mantra':
          final tasks = openTasks.isEmpty
              ? 'Set your three priorities for today.'
              : openTasks.join(' · ');
          await _schedule(
            id: 1,
            title: 'Your mantra for today',
            body: '$mantra\n\n$tasks',
            hour: reminder.hour,
            minute: reminder.minute,
          );
          break;

        case 'midday':
          // Fires only when something is still open.
          if (openTasks.isEmpty) break;
          final count = openTasks.length;
          await _schedule(
            id: 2,
            title: count == 1
                ? '1 priority still open'
                : '$count priorities still open',
            body: openTasks.join('\n'),
            hour: reminder.hour,
            minute: reminder.minute,
          );
          break;

        case 'evening':
          await _schedule(
            id: 3,
            title: 'Close the day',
            body: 'Ninety seconds: tick your habits and look at tomorrow.',
            hour: reminder.hour,
            minute: reminder.minute,
          );
          break;
      }
    }
  }
}
