import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'app_store.dart';
import 'models.dart';

class NotificationService {
  static const _weightReminderId = 1;
  static const _checkinId = 2;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      const settings = InitializationSettings(
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        macOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _plugin.initialize(settings);
      _ready = true;
    } catch (e) {
      debugPrint('Notifications unavailable: $e');
    }
  }

  Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(alert: true, sound: true) ?? false;
      }
      final macos = _plugin.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
      if (macos != null) {
        return await macos.requestPermissions(alert: true, sound: true) ??
            false;
      }
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
    }
    return false;
  }

  Future<void> sync(AppStore store) async {
    if (!_ready) return;
    try {
      final s = store.settings;

      await _plugin.cancel(_weightReminderId);
      if (s.reminderOn) {
        final now = tz.TZDateTime.now(tz.local);
        var at = tz.TZDateTime(tz.local, now.year, now.month, now.day,
            s.reminderHour, s.reminderMinute);
        final todayLogged = store.weightFor(DateTime.now()) != null;
        if (at.isBefore(now) || todayLogged) {
          at = at.add(const Duration(days: 1));
        }
        await _plugin.zonedSchedule(
          _weightReminderId,
          'Log today’s weight',
          'No weigh-in yet today. Logging one takes a second and keeps the trend honest.',
          at,
          const NotificationDetails(
            iOS: DarwinNotificationDetails(),
            macOS: DarwinNotificationDetails(),
            android: AndroidNotificationDetails(
              'weight_reminder',
              'Weight reminder',
              channelDescription: 'Fires only when the day has no weigh-in.',
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }

      await _plugin.cancel(_checkinId);
      if (s.checkinNudgeOn) {
        final last = store.latestSnapshot?.date;
        if (last != null) {
          var due = dayOnly(last).add(Duration(days: s.checkinCadenceDays));
          final snooze = s.snoozedUntil;
          if (snooze != null && snooze.isAfter(due)) due = dayOnly(snooze);
          var at = tz.TZDateTime(tz.local, due.year, due.month, due.day, 10);
          final now = tz.TZDateTime.now(tz.local);
          if (at.isAfter(now)) {
            await _plugin.zonedSchedule(
              _checkinId,
              '${s.checkinCadenceDays}-day check-in',
              'Three measurements refresh your body-fat, lean-mass and TDEE estimates. About a minute.',
              at,
              const NotificationDetails(
                iOS: DarwinNotificationDetails(),
                macOS: DarwinNotificationDetails(),
                android: AndroidNotificationDetails(
                  'checkin',
                  'Check-in nudge',
                  channelDescription: 'One nudge when measurements are due.',
                ),
              ),
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Notification scheduling failed: $e');
    }
  }
}
