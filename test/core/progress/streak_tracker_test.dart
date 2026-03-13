import 'package:flutter_test/flutter_test.dart';
import 'package:dander/core/progress/streak_tracker.dart';

void main() {
  group('StreakTracker', () {
    group('StreakTracker.empty', () {
      test('starts with streak 0', () {
        final tracker = StreakTracker.empty();
        expect(tracker.currentStreak, equals(0));
      });

      test('starts with null lastWalkDate', () {
        final tracker = StreakTracker.empty();
        expect(tracker.lastWalkDate, isNull);
      });
    });

    group('recordWalk', () {
      test('first walk sets streak to 1', () {
        final tracker = StreakTracker.empty();
        final updated = tracker.recordWalk(DateTime(2024, 6, 3)); // Monday
        expect(updated.currentStreak, equals(1));
      });

      test('first walk sets lastWalkDate', () {
        final tracker = StreakTracker.empty();
        final date = DateTime(2024, 6, 3);
        final updated = tracker.recordWalk(date);
        expect(updated.lastWalkDate, equals(date));
      });

      test('original tracker is unchanged after recordWalk', () {
        final tracker = StreakTracker.empty();
        tracker.recordWalk(DateTime(2024, 6, 3));
        expect(tracker.currentStreak, equals(0));
        expect(tracker.lastWalkDate, isNull);
      });

      test('walk in same week does not increment streak', () {
        // Week 1: Monday walk
        final tracker =
            StreakTracker.empty().recordWalk(DateTime(2024, 6, 3)); // Monday
        // Walk again on Wednesday of the same week
        final updated = tracker.recordWalk(DateTime(2024, 6, 5)); // Wednesday
        expect(updated.currentStreak, equals(1));
      });

      test('walk in same week updates lastWalkDate', () {
        final tracker = StreakTracker.empty().recordWalk(DateTime(2024, 6, 3));
        final updated = tracker.recordWalk(DateTime(2024, 6, 5));
        expect(updated.lastWalkDate, equals(DateTime(2024, 6, 5)));
      });

      test('walk in next consecutive week increments streak', () {
        // Week 1: walk on Monday 3 June 2024
        final tracker = StreakTracker.empty().recordWalk(DateTime(2024, 6, 3));
        // Week 2: walk on Monday 10 June 2024
        final updated = tracker.recordWalk(DateTime(2024, 6, 10));
        expect(updated.currentStreak, equals(2));
      });

      test('walk after skipping a week resets streak to 1', () {
        // Week 1
        final tracker = StreakTracker.empty().recordWalk(DateTime(2024, 6, 3));
        // Skip week 2 — walk in week 3
        final updated = tracker.recordWalk(DateTime(2024, 6, 17));
        expect(updated.currentStreak, equals(1));
      });

      test('multiple consecutive weeks increment streak correctly', () {
        var tracker = StreakTracker.empty();
        // 4 consecutive weekly walks
        tracker = tracker.recordWalk(DateTime(2024, 6, 3)); // week 1
        tracker = tracker.recordWalk(DateTime(2024, 6, 10)); // week 2
        tracker = tracker.recordWalk(DateTime(2024, 6, 17)); // week 3
        tracker = tracker.recordWalk(DateTime(2024, 6, 24)); // week 4
        expect(tracker.currentStreak, equals(4));
      });

      test('walk spanning year boundary still tracks correctly', () {
        // Last week of 2023 (week containing Dec 25)
        final tracker =
            StreakTracker.empty().recordWalk(DateTime(2023, 12, 25));
        // First week of 2024
        final updated = tracker.recordWalk(DateTime(2024, 1, 1));
        expect(updated.currentStreak, equals(2));
      });
    });

    group('isActiveThisWeek', () {
      test('returns false for empty tracker', () {
        final tracker = StreakTracker.empty();
        expect(tracker.isActiveThisWeek, isFalse);
      });

      test('returns true when lastWalkDate is in current ISO week', () {
        // We can't easily mock DateTime.now() so we use recordWalk with today
        final today = DateTime.now();
        final tracker = StreakTracker.empty().recordWalk(today);
        expect(tracker.isActiveThisWeek, isTrue);
      });

      test('returns false when lastWalkDate is in a previous week', () {
        // Walk that happened 14 days ago — definitely a previous week
        final oldDate = DateTime.now().subtract(const Duration(days: 14));
        final tracker = StreakTracker(
          currentStreak: 1,
          lastWalkDate: oldDate,
        );
        expect(tracker.isActiveThisWeek, isFalse);
      });
    });

    group('isAtRisk', () {
      test('returns false for empty tracker', () {
        final tracker = StreakTracker.empty();
        expect(tracker.isAtRisk, isFalse);
      });

      test('returns false when walk was done in current week', () {
        final today = DateTime.now();
        final tracker = StreakTracker.empty().recordWalk(today);
        expect(tracker.isAtRisk, isFalse);
      });

      test('returns true when last walk was in previous week, none this week',
          () {
        final lastWeek = DateTime.now().subtract(const Duration(days: 8));
        final tracker = StreakTracker(
          currentStreak: 2,
          lastWalkDate: lastWeek,
        );
        expect(tracker.isAtRisk, isTrue);
      });

      test('returns false when streak is already broken (skipped 2+ weeks)',
          () {
        // Skipped 2+ weeks — streak is already 0 / reset territory
        // isAtRisk should be false because there's nothing to risk anymore
        final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 16));
        final tracker = StreakTracker(
          currentStreak: 1,
          lastWalkDate: twoWeeksAgo,
        );
        expect(tracker.isAtRisk, isFalse);
      });
    });

    group('copyWith', () {
      test('creates new instance with updated fields', () {
        final original =
            StreakTracker(currentStreak: 3, lastWalkDate: DateTime(2024, 6, 1));
        final copied = original.copyWith(currentStreak: 5);
        expect(copied.currentStreak, equals(5));
        expect(copied.lastWalkDate, equals(original.lastWalkDate));
      });

      test('original unchanged after copyWith', () {
        final original =
            StreakTracker(currentStreak: 3, lastWalkDate: DateTime(2024, 6, 1));
        original.copyWith(currentStreak: 5);
        expect(original.currentStreak, equals(3));
      });
    });

    group('serialisation', () {
      test('toJson and fromJson round-trip for empty tracker', () {
        final original = StreakTracker.empty();
        final json = original.toJson();
        final restored = StreakTracker.fromJson(json);
        expect(restored.currentStreak, equals(original.currentStreak));
        expect(restored.lastWalkDate, isNull);
      });

      test('toJson and fromJson round-trip with streak and date', () {
        final date = DateTime(2024, 6, 15, 10, 30, 0);
        final original = StreakTracker(currentStreak: 5, lastWalkDate: date);
        final json = original.toJson();
        final restored = StreakTracker.fromJson(json);
        expect(restored.currentStreak, equals(5));
        expect(restored.lastWalkDate, equals(date));
      });

      test('toJson produces a Map with expected keys', () {
        final tracker =
            StreakTracker(currentStreak: 2, lastWalkDate: DateTime(2024, 1, 1));
        final json = tracker.toJson();
        expect(json.containsKey('currentStreak'), isTrue);
        expect(json.containsKey('lastWalkDate'), isTrue);
      });

      test('fromJson handles null lastWalkDate', () {
        final json = {'currentStreak': 0, 'lastWalkDate': null};
        final tracker = StreakTracker.fromJson(json);
        expect(tracker.lastWalkDate, isNull);
        expect(tracker.currentStreak, equals(0));
      });
    });
  });
}
