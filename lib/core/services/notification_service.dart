import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class DueReminder {
  final int id;
  final String title;
  final String body;
  final DateTime when;

  const DueReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.when,
  });
}

class NotificationService {
  static const _dailyId = 9999;
  static const _weeklyId = 9998;
  static const _dueIdBase = 100000;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    try {
      final local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Africa/Kigali'));
    }

    // Permission is asked for explicitly when the user turns reminders on,
    // never on launch.
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: darwin,
        macOS: darwin,
      ),
    );
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await init();
    if (Platform.isIOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }
    if (Platform.isAndroid) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  Future<bool> isPermitted() async {
    await init();
    if (Platform.isIOS) {
      final options = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.checkPermissions();
      return options?.isEnabled ?? false;
    }
    if (Platform.isAndroid) {
      final enabled = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.areNotificationsEnabled();
      return enabled ?? false;
    }
    return true;
  }

  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await init();
    await _plugin.zonedSchedule(
      _dailyId,
      'Log today\'s spending',
      'Takes ten seconds. Your future self will thank you.',
      _nextAt(hour: hour, minute: minute),
      _details('reminders', 'Daily reminder'),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleWeeklySummary() async {
    await init();
    var when = _nextAt(hour: 19, minute: 0);
    while (when.weekday != DateTime.sunday) {
      when = when.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      _weeklyId,
      'Your week in Genga',
      'See where your money went this week.',
      when,
      _details('reports', 'Weekly summary'),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> scheduleDueReminders(List<DueReminder> reminders) async {
    await init();
    await cancelDueReminders();
    final now = tz.TZDateTime.now(tz.local);
    for (final r in reminders) {
      final when = tz.TZDateTime.from(r.when, tz.local);
      if (!when.isAfter(now)) continue;
      await _plugin.zonedSchedule(
        _dueIdBase + r.id,
        r.title,
        r.body,
        when,
        _details('recurrence', 'Recurring payments'),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> cancelDailyReminder() async {
    await init();
    await _plugin.cancel(_dailyId);
  }

  Future<void> cancelWeeklySummary() async {
    await init();
    await _plugin.cancel(_weeklyId);
  }

  Future<void> cancelDueReminders() async {
    await init();
    final pending = await _plugin.pendingNotificationRequests();
    for (final p in pending.where((p) => p.id >= _dueIdBase)) {
      await _plugin.cancel(p.id);
    }
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  Future<void> showJoinRequest({
    required String memberName,
    required String spaceName,
  }) async {
    await init();
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000 % _dueIdBase,
      'Join request',
      '$memberName wants to join $spaceName',
      _details('join_requests', 'Join requests'),
    );
  }

  tz.TZDateTime _nextAt({required int hour, required int minute}) {
    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!when.isAfter(now)) when = when.add(const Duration(days: 1));
    return when;
  }

  NotificationDetails _details(String channel, String name) =>
      NotificationDetails(
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: true,
        ),
        android: AndroidNotificationDetails(
          channel,
          name,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      );
}
