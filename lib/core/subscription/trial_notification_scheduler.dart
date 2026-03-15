import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

// ---------------------------------------------------------------------------
// Notification IDs
// ---------------------------------------------------------------------------

const _kDayFiveId = 101;
const _kDaySevenId = 102;

// ---------------------------------------------------------------------------
// Android channel
// ---------------------------------------------------------------------------

const _kChannelId = 'trial_reminders';
const _kChannelName = 'Trial Reminders';

// ---------------------------------------------------------------------------
// Interface
// ---------------------------------------------------------------------------

/// Schedules and cancels local notifications for trial expiry reminders.
abstract interface class TrialNotificationScheduler {
  /// Schedules the two trial-expiry notifications relative to [trialStartDate].
  ///
  /// - ID 101 fires at [trialStartDate] + 5 days ("ends in 2 days").
  /// - ID 102 fires at [trialStartDate] + 7 days ("ended today").
  Future<void> scheduleForTrialStart(DateTime trialStartDate);

  /// Cancels both trial-expiry notifications (IDs 101 and 102).
  Future<void> cancelAll();
}

// ---------------------------------------------------------------------------
// Live implementation
// ---------------------------------------------------------------------------

/// Production implementation that wraps [FlutterLocalNotificationsPlugin].
///
/// Accept an optional [plugin] parameter to allow injection of a mock in tests.
class LocalTrialNotificationScheduler implements TrialNotificationScheduler {
  LocalTrialNotificationScheduler({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<void> scheduleForTrialStart(DateTime trialStartDate) async {
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    final details = NotificationDetails(
      android: const AndroidNotificationDetails(
        _kChannelId,
        _kChannelName,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    final dayFiveDate = trialStartDate.add(const Duration(days: 5));
    final daySevenDate = trialStartDate.add(const Duration(days: 7));

    await _plugin.zonedSchedule(
      _kDayFiveId,
      'Your Pro trial ends in 2 days',
      'Keep your unlimited zones?',
      tz.TZDateTime.from(dayFiveDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    await _plugin.zonedSchedule(
      _kDaySevenId,
      'Your Pro trial ended today',
      'Your zones and data are safe.',
      tz.TZDateTime.from(daySevenDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  @override
  Future<void> cancelAll() async {
    await _plugin.cancel(_kDayFiveId);
    await _plugin.cancel(_kDaySevenId);
  }
}

// ---------------------------------------------------------------------------
// No-op implementation (default for SubscriptionService)
// ---------------------------------------------------------------------------

/// A no-op [TrialNotificationScheduler] that does nothing.
///
/// Used as the default in [SubscriptionService] so that notification
/// scheduling can be wired in optionally without touching DI registration.
class NoOpTrialNotificationScheduler implements TrialNotificationScheduler {
  @override
  Future<void> scheduleForTrialStart(DateTime trialStartDate) async {}

  @override
  Future<void> cancelAll() async {}
}
