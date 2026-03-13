import 'package:flutter_test/flutter_test.dart';
import 'package:dander/core/quiz/quiz_streak_tracker.dart';

void main() {
  group('QuizStreakTracker', () {
    group('QuizStreakTracker.empty', () {
      test('starts with streak 0', () {
        final tracker = QuizStreakTracker.empty();
        expect(tracker.currentStreak, equals(0));
      });

      test('starts with null lastSessionDate', () {
        final tracker = QuizStreakTracker.empty();
        expect(tracker.lastSessionDate, isNull);
      });
    });

    group('recordSession', () {
      test('first session sets streak to 1', () {
        final tracker = QuizStreakTracker.empty();
        final updated = tracker.recordSession(DateTime(2024, 6, 3));
        expect(updated.currentStreak, equals(1));
      });

      test('first session sets lastSessionDate', () {
        final tracker = QuizStreakTracker.empty();
        final date = DateTime(2024, 6, 3);
        final updated = tracker.recordSession(date);
        expect(updated.lastSessionDate, equals(date));
      });

      test('original tracker is unchanged after recordSession', () {
        final tracker = QuizStreakTracker.empty();
        tracker.recordSession(DateTime(2024, 6, 3));
        expect(tracker.currentStreak, equals(0));
        expect(tracker.lastSessionDate, isNull);
      });

      test('session in same week does not increment streak', () {
        final tracker =
            QuizStreakTracker.empty().recordSession(DateTime(2024, 6, 3));
        final updated = tracker.recordSession(DateTime(2024, 6, 5));
        expect(updated.currentStreak, equals(1));
      });

      test('session in same week updates lastSessionDate', () {
        final tracker =
            QuizStreakTracker.empty().recordSession(DateTime(2024, 6, 3));
        final updated = tracker.recordSession(DateTime(2024, 6, 5));
        expect(updated.lastSessionDate, equals(DateTime(2024, 6, 5)));
      });

      test('session in next consecutive week increments streak', () {
        final tracker =
            QuizStreakTracker.empty().recordSession(DateTime(2024, 6, 3));
        final updated = tracker.recordSession(DateTime(2024, 6, 10));
        expect(updated.currentStreak, equals(2));
      });

      test('session after skipping a week resets streak to 1', () {
        final tracker =
            QuizStreakTracker.empty().recordSession(DateTime(2024, 6, 3));
        final updated = tracker.recordSession(DateTime(2024, 6, 17));
        expect(updated.currentStreak, equals(1));
      });

      test('multiple consecutive weeks increment streak correctly', () {
        var tracker = QuizStreakTracker.empty();
        tracker = tracker.recordSession(DateTime(2024, 6, 3));
        tracker = tracker.recordSession(DateTime(2024, 6, 10));
        tracker = tracker.recordSession(DateTime(2024, 6, 17));
        tracker = tracker.recordSession(DateTime(2024, 6, 24));
        expect(tracker.currentStreak, equals(4));
      });

      test('session spanning year boundary still tracks correctly', () {
        final tracker =
            QuizStreakTracker.empty().recordSession(DateTime(2023, 12, 25));
        final updated = tracker.recordSession(DateTime(2024, 1, 1));
        expect(updated.currentStreak, equals(2));
      });
    });

    group('isActiveToday', () {
      test('returns false for empty tracker', () {
        final tracker = QuizStreakTracker.empty();
        expect(tracker.isActiveToday, isFalse);
      });

      test('returns true when lastSessionDate is today', () {
        final today = DateTime.now();
        final tracker = QuizStreakTracker.empty().recordSession(today);
        expect(tracker.isActiveToday, isTrue);
      });

      test('returns false when lastSessionDate is yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final tracker = QuizStreakTracker(
          currentStreak: 1,
          lastSessionDate: yesterday,
        );
        expect(tracker.isActiveToday, isFalse);
      });
    });

    group('isAtRisk', () {
      test('returns false for empty tracker', () {
        final tracker = QuizStreakTracker.empty();
        expect(tracker.isAtRisk, isFalse);
      });

      test('returns false when session was done in current week', () {
        final today = DateTime.now();
        final tracker = QuizStreakTracker.empty().recordSession(today);
        expect(tracker.isAtRisk, isFalse);
      });

      test('returns true when last session was in previous week, none this week',
          () {
        final lastWeek = DateTime.now().subtract(const Duration(days: 8));
        final tracker = QuizStreakTracker(
          currentStreak: 2,
          lastSessionDate: lastWeek,
        );
        expect(tracker.isAtRisk, isTrue);
      });

      test('returns false when streak is already broken (skipped 2+ weeks)',
          () {
        final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 16));
        final tracker = QuizStreakTracker(
          currentStreak: 1,
          lastSessionDate: twoWeeksAgo,
        );
        expect(tracker.isAtRisk, isFalse);
      });
    });

    group('serialisation', () {
      test('toJson and fromJson round-trip for empty tracker', () {
        final original = QuizStreakTracker.empty();
        final json = original.toJson();
        final restored = QuizStreakTracker.fromJson(json);
        expect(restored.currentStreak, equals(original.currentStreak));
        expect(restored.lastSessionDate, isNull);
      });

      test('toJson and fromJson round-trip with streak and date', () {
        final date = DateTime(2024, 6, 15, 10, 30, 0);
        final original =
            QuizStreakTracker(currentStreak: 5, lastSessionDate: date);
        final json = original.toJson();
        final restored = QuizStreakTracker.fromJson(json);
        expect(restored.currentStreak, equals(5));
        expect(restored.lastSessionDate, equals(date));
      });

      test('toJson produces a Map with expected keys', () {
        final tracker = QuizStreakTracker(
          currentStreak: 2,
          lastSessionDate: DateTime(2024, 1, 1),
        );
        final json = tracker.toJson();
        expect(json.containsKey('currentStreak'), isTrue);
        expect(json.containsKey('lastSessionDate'), isTrue);
      });

      test('fromJson handles null lastSessionDate', () {
        final json = {'currentStreak': 0, 'lastSessionDate': null};
        final tracker = QuizStreakTracker.fromJson(json);
        expect(tracker.lastSessionDate, isNull);
        expect(tracker.currentStreak, equals(0));
      });
    });
  });
}
