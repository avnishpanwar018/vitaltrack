import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder.dart';

class ReminderException implements Exception {
  const ReminderException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Local reminders are configured only from explicit settings actions.
class NotificationService {
  NotificationService({Future<String> Function()? localTimezone})
      : _localTimezone = localTimezone ?? FlutterTimezone.getLocalTimezone;

  final Future<String> Function() _localTimezone;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  Future<void>? _initializing;
  bool _initialized = false;
  bool _pluginAvailable = true;

  bool get isSupported => _pluginAvailable && !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  /// Does not request permission, schedule, or display notifications.
  Future<void> initialize() async {
    if (_initialized || !isSupported) return;
    try {
      await (_initializing ??= _initialize());
    } catch (_) {
      // Flutter unit tests and unsupported desktop builds may not register a
      // platform implementation. Treat that the same as an unavailable
      // notification platform instead of crashing app startup.
      _pluginAvailable = false;
    } finally {
      _initializing = null;
    }
  }

  Future<void> _initialize() async {
    tz_data.initializeTimeZones();
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      requestProvisionalPermission: false,
    );
    final initialized = await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: darwin,
        macOS: darwin,
      ),
    );
    if (initialized != true) {
      throw const ReminderException('Could not initialize reminders. Try again.');
    }
    _initialized = true;
  }

  /// Call only in response to the user's reminder opt-in.
  Future<bool> requestPermissions() async {
    if (!isSupported) return false;
    await initialize();
    if (!isSupported) return false;
    try {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final android = _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
          if (await android?.areNotificationsEnabled() == true) return true;
          return await android?.requestNotificationsPermission() == true;
        case TargetPlatform.iOS:
          return await _plugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
            alert: true, badge: true, sound: true,
          ) == true;
        case TargetPlatform.macOS:
          return await _plugin.resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
            alert: true, badge: true, sound: true,
          ) == true;
        default:
          return false;
      }
    } catch (_) {
      _pluginAvailable = false;
      return false;
    }
  }

  /// Checks the current permission without prompting, including OS revocation.
  Future<bool> hasPermission() async {
    if (!isSupported) return false;
    await initialize();
    if (!isSupported) return false;
    try {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          return await _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()?.areNotificationsEnabled() == true;
        case TargetPlatform.iOS:
          final permission = await _plugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()?.checkPermissions();
          return permission?.isEnabled == true;
        case TargetPlatform.macOS:
          final permission = await _plugin.resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()?.checkPermissions();
          return permission?.isEnabled == true;
        default:
          return false;
      }
    } catch (_) {
      _pluginAvailable = false;
      return false;
    }
  }

  Future<void> scheduleReminder(Reminder reminder) async {
    if (!reminder.enabled) {
      await cancelReminder(reminder.id);
      return;
    }
    if (!isSupported) return;
    if (!await hasPermission()) {
      throw const ReminderException(
        'Notifications are denied. Allow notifications in device settings, then try again.',
      );
    }

    // Refresh at every scheduling action so changing the device zone is honored.
    // Never fall back to UTC or a fixed offset: those lose local/DST semantics.
    try {
      tz.setLocalLocation(tz.getLocation(await _localTimezone()));
    } catch (_) {
      throw const ReminderException(
        'Could not read the device timezone. Check your device time settings and try again.',
      );
    }
    final scheduled = nextReminderTime(reminder.time, tz.TZDateTime.now(tz.local));
    await _plugin.zonedSchedule(
      notificationIdFor(reminder.id),
      reminder.title,
      'Time to record your blood pressure reading.',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'bp_reminders',
          'Blood Pressure Reminders',
          channelDescription: 'Daily reminders to measure blood pressure',
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'reminder:${reminder.id}',
    );
  }

  Future<void> scheduleAllReminders(List<Reminder> reminders) async {
    for (final reminder in reminders) {
      await scheduleReminder(reminder);
    }
  }

  Future<void> cancelReminder(String id) async {
    if (!isSupported) return;
    await initialize();
    await _plugin.cancel(notificationIdFor(id));
  }

  Future<void> cancelAll() async {
    if (!isSupported) return;
    await initialize();
    await _plugin.cancelAll();
  }

  // Compatibility with existing clients. Unsolicited missed-reading alerts have
  // been retired; daily, explicitly enabled reminders use scheduleReminder.
  Future<void> showMissedReminderNotification() async {}

  /// Stable 31-bit ID using a bounded multiply (also deterministic on the web).
  static int notificationIdFor(String reminderId) {
    var hash = 5381;
    for (final byte in utf8.encode(reminderId)) {
      hash = ((hash * 33) ^ byte) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }

  static tz.TZDateTime nextReminderTime(String time, tz.TZDateTime now) {
    final match = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').firstMatch(time);
    if (match == null) {
      throw const FormatException('Reminder time must use HH:mm format');
    }
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    var scheduled = tz.TZDateTime(
      now.location, now.year, now.month, now.day, hour, minute,
    );
    if (!scheduled.isAfter(now)) {
      // Reconstruct the next calendar day instead of adding 24 hours over DST.
      scheduled = tz.TZDateTime(
        now.location, now.year, now.month, now.day + 1, hour, minute,
      );
    }
    return scheduled;
  }
}
