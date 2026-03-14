import 'package:flutter_test/flutter_test.dart';
import 'package:dander/core/progress/daily_target.dart';

void main() {
  group('DailyTarget', () {
    group('creation', () {
      test('defaults to 0 streets and target of 1', () {
        final target = DailyTarget.empty();
        expect(target.streetsToday, 0);
        expect(target.target, 1);
      });

      test('stores lastResetDate', () {
        final now = DateTime(2024, 6, 15);
        final target = DailyTarget(
          streetsToday: 0,
          target: 1,
          lastResetDate: now,
        );
        expect(target.lastResetDate, now);
      });
    });

    group('increment', () {
      test('increments streetsToday by 1', () {
        final target = DailyTarget(
          streetsToday: 0,
          target: 1,
          lastResetDate: DateTime(2024, 6, 15),
        );
        final updated = target.increment();
        expect(updated.streetsToday, 1);
      });

      test('does not mutate original', () {
        final target = DailyTarget(
          streetsToday: 0,
          target: 1,
          lastResetDate: DateTime(2024, 6, 15),
        );
        target.increment();
        expect(target.streetsToday, 0);
      });

      test('can increment beyond target', () {
        final target = DailyTarget(
          streetsToday: 1,
          target: 1,
          lastResetDate: DateTime(2024, 6, 15),
        );
        final updated = target.increment();
        expect(updated.streetsToday, 2);
      });
    });

    group('reset logic', () {
      test('needsReset returns true when last reset was yesterday', () {
        final yesterday = DateTime(2024, 6, 14);
        final target = DailyTarget(
          streetsToday: 1,
          target: 1,
          lastResetDate: yesterday,
        );
        final today = DateTime(2024, 6, 15, 10, 30);
        expect(target.needsReset(today), isTrue);
      });

      test('needsReset returns false when last reset was today', () {
        final today = DateTime(2024, 6, 15, 8, 0);
        final target = DailyTarget(
          streetsToday: 1,
          target: 1,
          lastResetDate: today,
        );
        final laterToday = DateTime(2024, 6, 15, 20, 0);
        expect(target.needsReset(laterToday), isFalse);
      });

      test('reset returns new instance with 0 streets and updated date', () {
        final target = DailyTarget(
          streetsToday: 3,
          target: 1,
          lastResetDate: DateTime(2024, 6, 14),
        );
        final now = DateTime(2024, 6, 15, 10, 0);
        final reset = target.resetIfNeeded(now);
        expect(reset.streetsToday, 0);
        expect(reset.lastResetDate, now);
      });

      test('resetIfNeeded returns same values when same day', () {
        final today = DateTime(2024, 6, 15, 8, 0);
        final target = DailyTarget(
          streetsToday: 1,
          target: 1,
          lastResetDate: today,
        );
        final laterToday = DateTime(2024, 6, 15, 20, 0);
        final result = target.resetIfNeeded(laterToday);
        expect(result.streetsToday, 1);
      });
    });

    group('progress', () {
      test('progress is 0 when no streets walked', () {
        final target = DailyTarget.empty();
        expect(target.progress, 0.0);
      });

      test('progress is 1.0 when target met', () {
        final target = DailyTarget(
          streetsToday: 1,
          target: 1,
          lastResetDate: DateTime(2024, 6, 15),
        );
        expect(target.progress, 1.0);
      });

      test('progress is clamped to 1.0 when exceeded', () {
        final target = DailyTarget(
          streetsToday: 3,
          target: 1,
          lastResetDate: DateTime(2024, 6, 15),
        );
        expect(target.progress, 1.0);
      });

      test('isComplete is true when target met', () {
        final target = DailyTarget(
          streetsToday: 1,
          target: 1,
          lastResetDate: DateTime(2024, 6, 15),
        );
        expect(target.isComplete, isTrue);
      });

      test('isComplete is false when target not met', () {
        final target = DailyTarget.empty();
        expect(target.isComplete, isFalse);
      });
    });

    group('serialization', () {
      test('round-trips through JSON', () {
        final target = DailyTarget(
          streetsToday: 2,
          target: 1,
          lastResetDate: DateTime(2024, 6, 15, 10, 30),
        );
        final json = target.toJson();
        final restored = DailyTarget.fromJson(json);
        expect(restored.streetsToday, target.streetsToday);
        expect(restored.target, target.target);
      });
    });
  });
}
