import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:dander/core/subscription/trial_notification_scheduler.dart';

// ---------------------------------------------------------------------------
// Mock
// ---------------------------------------------------------------------------

class _MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Fallback values required by mocktail for complex types.
void _registerFallbacks() {
  registerFallbackValue(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );
  registerFallbackValue(
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'trial_reminders',
        'Trial Reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
  );
  registerFallbackValue(
    tz.TZDateTime.from(DateTime(2026, 1, 1), tz.local),
  );
  registerFallbackValue(
    UILocalNotificationDateInterpretation.absoluteTime,
  );
  registerFallbackValue(AndroidScheduleMode.exactAllowWhileIdle);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  tz.initializeTimeZones();

  late _MockPlugin mockPlugin;
  late TrialNotificationScheduler scheduler;
  late DateTime trialStart;

  setUp(() {
    _registerFallbacks();
    mockPlugin = _MockPlugin();

    // initialize() returns true by default.
    // We stub the simplest overload — named optional callbacks are not used by
    // LocalTrialNotificationScheduler, so we match on the positional arg only.
    when(() => mockPlugin.initialize(any())).thenAnswer((_) async => true);

    // zonedSchedule() completes successfully
    when(
      () => mockPlugin.zonedSchedule(
        any(),
        any(),
        any(),
        any(),
        any(),
        androidScheduleMode: any(named: 'androidScheduleMode'),
        uiLocalNotificationDateInterpretation:
            any(named: 'uiLocalNotificationDateInterpretation'),
      ),
    ).thenAnswer((_) async {});

    // cancel() completes successfully
    when(() => mockPlugin.cancel(any())).thenAnswer((_) async {});

    trialStart = DateTime(2026, 3, 15, 10, 0);
    scheduler = LocalTrialNotificationScheduler(plugin: mockPlugin);
  });

  // -------------------------------------------------------------------------
  // initialize
  // -------------------------------------------------------------------------

  group('scheduleForTrialStart — initialize', () {
    test('calls initialize exactly once', () async {
      await scheduler.scheduleForTrialStart(trialStart);

      verify(() => mockPlugin.initialize(any())).called(1);
    });
  });

  // -------------------------------------------------------------------------
  // Notification ID 101 — day 5
  // -------------------------------------------------------------------------

  group('scheduleForTrialStart — day-5 notification (ID 101)', () {
    test('schedules zonedSchedule with ID 101', () async {
      await scheduler.scheduleForTrialStart(trialStart);

      verify(
        () => mockPlugin.zonedSchedule(
          101,
          any(),
          any(),
          any(),
          any(),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          uiLocalNotificationDateInterpretation:
              any(named: 'uiLocalNotificationDateInterpretation'),
        ),
      ).called(1);
    });

    test('day-5 notification title is "Your Pro trial ends in 2 days"',
        () async {
      await scheduler.scheduleForTrialStart(trialStart);

      verify(
        () => mockPlugin.zonedSchedule(
          101,
          'Your Pro trial ends in 2 days',
          any(),
          any(),
          any(),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          uiLocalNotificationDateInterpretation:
              any(named: 'uiLocalNotificationDateInterpretation'),
        ),
      ).called(1);
    });

    test('day-5 notification body is "Keep your unlimited zones?"', () async {
      await scheduler.scheduleForTrialStart(trialStart);

      verify(
        () => mockPlugin.zonedSchedule(
          101,
          any(),
          'Keep your unlimited zones?',
          any(),
          any(),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          uiLocalNotificationDateInterpretation:
              any(named: 'uiLocalNotificationDateInterpretation'),
        ),
      ).called(1);
    });

    test('day-5 notification scheduled at trialStart + 5 days', () async {
      await scheduler.scheduleForTrialStart(trialStart);

      final expectedDate = trialStart.add(const Duration(days: 5));
      final expectedTz = tz.TZDateTime.from(expectedDate, tz.local);

      verify(
        () => mockPlugin.zonedSchedule(
          101,
          any(),
          any(),
          expectedTz,
          any(),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          uiLocalNotificationDateInterpretation:
              any(named: 'uiLocalNotificationDateInterpretation'),
        ),
      ).called(1);
    });
  });

  // -------------------------------------------------------------------------
  // Notification ID 102 — day 7
  // -------------------------------------------------------------------------

  group('scheduleForTrialStart — day-7 notification (ID 102)', () {
    test('schedules zonedSchedule with ID 102', () async {
      await scheduler.scheduleForTrialStart(trialStart);

      verify(
        () => mockPlugin.zonedSchedule(
          102,
          any(),
          any(),
          any(),
          any(),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          uiLocalNotificationDateInterpretation:
              any(named: 'uiLocalNotificationDateInterpretation'),
        ),
      ).called(1);
    });

    test('day-7 notification title is "Your Pro trial ended today"', () async {
      await scheduler.scheduleForTrialStart(trialStart);

      verify(
        () => mockPlugin.zonedSchedule(
          102,
          'Your Pro trial ended today',
          any(),
          any(),
          any(),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          uiLocalNotificationDateInterpretation:
              any(named: 'uiLocalNotificationDateInterpretation'),
        ),
      ).called(1);
    });

    test('day-7 notification body is "Your zones and data are safe."', () async {
      await scheduler.scheduleForTrialStart(trialStart);

      verify(
        () => mockPlugin.zonedSchedule(
          102,
          any(),
          'Your zones and data are safe.',
          any(),
          any(),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          uiLocalNotificationDateInterpretation:
              any(named: 'uiLocalNotificationDateInterpretation'),
        ),
      ).called(1);
    });

    test('day-7 notification scheduled at trialStart + 7 days', () async {
      await scheduler.scheduleForTrialStart(trialStart);

      final expectedDate = trialStart.add(const Duration(days: 7));
      final expectedTz = tz.TZDateTime.from(expectedDate, tz.local);

      verify(
        () => mockPlugin.zonedSchedule(
          102,
          any(),
          any(),
          expectedTz,
          any(),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          uiLocalNotificationDateInterpretation:
              any(named: 'uiLocalNotificationDateInterpretation'),
        ),
      ).called(1);
    });
  });

  // -------------------------------------------------------------------------
  // cancelAll
  // -------------------------------------------------------------------------

  group('cancelAll', () {
    test('cancels notification ID 101', () async {
      await scheduler.cancelAll();

      verify(() => mockPlugin.cancel(101)).called(1);
    });

    test('cancels notification ID 102', () async {
      await scheduler.cancelAll();

      verify(() => mockPlugin.cancel(102)).called(1);
    });

    test('cancels exactly two notifications', () async {
      await scheduler.cancelAll();

      verify(() => mockPlugin.cancel(any())).called(2);
    });
  });

  // -------------------------------------------------------------------------
  // NoOpTrialNotificationScheduler
  // -------------------------------------------------------------------------

  group('NoOpTrialNotificationScheduler', () {
    test('scheduleForTrialStart completes without error', () async {
      final noop = NoOpTrialNotificationScheduler();
      await expectLater(
        noop.scheduleForTrialStart(DateTime(2026, 1, 1)),
        completes,
      );
    });

    test('cancelAll completes without error', () async {
      final noop = NoOpTrialNotificationScheduler();
      await expectLater(noop.cancelAll(), completes);
    });
  });
}
