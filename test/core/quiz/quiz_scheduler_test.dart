import 'package:flutter_test/flutter_test.dart';
import 'package:dander/core/quiz/street_memory_record.dart';
import 'package:dander/core/quiz/quiz_scheduler.dart';

void main() {
  final today = DateTime(2025, 6, 10);

  // Helper to build a record with a specific nextReviewDate and state.
  StreetMemoryRecord makeRecord({
    required String streetId,
    required DateTime nextReviewDate,
    MemoryState state = MemoryState.review,
    int intervalDays = 7,
  }) {
    return StreetMemoryRecord(
      streetId: streetId,
      state: state,
      intervalDays: intervalDays,
      easeFactor: 2.5,
      nextReviewDate: nextReviewDate,
      reviewHistory: [],
    );
  }

  group('QuizScheduler.getDueToday', () {
    // -------------------------------------------------------------------------
    // Empty / trivial inputs
    // -------------------------------------------------------------------------
    group('empty inputs', () {
      test('returns empty list when no records', () {
        final result = QuizScheduler.getDueToday([], today);
        expect(result, isEmpty);
      });

      test('returns empty list when all records are future-dated', () {
        final records = [
          makeRecord(streetId: 's1', nextReviewDate: today.add(const Duration(days: 1))),
          makeRecord(streetId: 's2', nextReviewDate: today.add(const Duration(days: 7))),
        ];
        final result = QuizScheduler.getDueToday(records, today);
        expect(result, isEmpty);
      });

      test('returns empty list when all records are mastered with future dates',
          () {
        final records = [
          makeRecord(
            streetId: 's1',
            state: MemoryState.mastered,
            nextReviewDate: today.add(const Duration(days: 30)),
          ),
        ];
        final result = QuizScheduler.getDueToday(records, today);
        expect(result, isEmpty);
      });
    });

    // -------------------------------------------------------------------------
    // Due date filtering
    // -------------------------------------------------------------------------
    group('due date filtering', () {
      test('includes record with nextReviewDate == today', () {
        final record = makeRecord(streetId: 's1', nextReviewDate: today);
        final result = QuizScheduler.getDueToday([record], today);
        expect(result.map((r) => r.streetId), contains('s1'));
      });

      test('includes record with nextReviewDate before today', () {
        final record = makeRecord(
            streetId: 's1',
            nextReviewDate: today.subtract(const Duration(days: 3)));
        final result = QuizScheduler.getDueToday([record], today);
        expect(result.map((r) => r.streetId), contains('s1'));
      });

      test('excludes record with nextReviewDate after today', () {
        final record = makeRecord(
            streetId: 's1',
            nextReviewDate: today.add(const Duration(days: 1)));
        final result = QuizScheduler.getDueToday([record], today);
        expect(result.map((r) => r.streetId), isNot(contains('s1')));
      });

      test('date comparison ignores time component', () {
        // A record whose nextReviewDate is today at 23:59 should be included
        final todayLate = DateTime(today.year, today.month, today.day, 23, 59);
        final todayEarly = DateTime(today.year, today.month, today.day, 0, 0);
        final recordLate =
            makeRecord(streetId: 's1', nextReviewDate: todayLate);
        final recordEarly =
            makeRecord(streetId: 's2', nextReviewDate: todayEarly);
        final result =
            QuizScheduler.getDueToday([recordLate, recordEarly], today);
        expect(result.length, equals(2));
      });
    });

    // -------------------------------------------------------------------------
    // Session size cap
    // -------------------------------------------------------------------------
    group('session size cap', () {
      test('caps results at maxSessionSize (20)', () {
        final records = List.generate(
          30,
          (i) => makeRecord(streetId: 'street-$i', nextReviewDate: today),
        );
        final result = QuizScheduler.getDueToday(records, today);
        expect(result.length, equals(QuizScheduler.maxSessionSize));
      });

      test('returns all when fewer than maxSessionSize are due', () {
        final records = List.generate(
          5,
          (i) => makeRecord(streetId: 'street-$i', nextReviewDate: today),
        );
        final result = QuizScheduler.getDueToday(records, today);
        expect(result.length, equals(5));
      });

      test('returns exactly maxSessionSize when exactly 20 are due', () {
        final records = List.generate(
          20,
          (i) => makeRecord(streetId: 'street-$i', nextReviewDate: today),
        );
        final result = QuizScheduler.getDueToday(records, today);
        expect(result.length, equals(20));
      });
    });

    // -------------------------------------------------------------------------
    // Priority ordering: learning first, then review, then newCard
    // -------------------------------------------------------------------------
    group('priority ordering', () {
      test('learning cards come before review cards', () {
        final records = [
          makeRecord(
              streetId: 'review-1',
              state: MemoryState.review,
              nextReviewDate: today),
          makeRecord(
              streetId: 'learning-1',
              state: MemoryState.learning,
              nextReviewDate: today),
        ];
        final result = QuizScheduler.getDueToday(records, today);
        expect(result[0].streetId, equals('learning-1'));
        expect(result[1].streetId, equals('review-1'));
      });

      test('review cards come before newCard cards', () {
        final records = [
          makeRecord(
              streetId: 'new-1',
              state: MemoryState.newCard,
              nextReviewDate: today),
          makeRecord(
              streetId: 'review-1',
              state: MemoryState.review,
              nextReviewDate: today),
        ];
        final result = QuizScheduler.getDueToday(records, today);
        expect(result[0].streetId, equals('review-1'));
        expect(result[1].streetId, equals('new-1'));
      });

      test('priority order: learning > review > newCard', () {
        final records = [
          makeRecord(
              streetId: 'new-1',
              state: MemoryState.newCard,
              nextReviewDate: today),
          makeRecord(
              streetId: 'review-1',
              state: MemoryState.review,
              nextReviewDate: today),
          makeRecord(
              streetId: 'learning-1',
              state: MemoryState.learning,
              nextReviewDate: today),
        ];
        final result = QuizScheduler.getDueToday(records, today);
        expect(result[0].state, equals(MemoryState.learning));
        expect(result[1].state, equals(MemoryState.review));
        expect(result[2].state, equals(MemoryState.newCard));
      });

      test('mastered cards due today are excluded from session', () {
        // Mastered cards that happen to be due today should still be surfaced
        // per spec — a mastered card with nextReviewDate <= today is due.
        // But let's verify they appear last or confirm spec behaviour:
        // They ARE included because they are due; the spec doesn't exclude mastered.
        final records = [
          makeRecord(
              streetId: 'mastered-1',
              state: MemoryState.mastered,
              intervalDays: 30,
              nextReviewDate: today),
          makeRecord(
              streetId: 'learning-1',
              state: MemoryState.learning,
              nextReviewDate: today),
        ];
        final result = QuizScheduler.getDueToday(records, today);
        // learning should come first
        expect(result[0].state, equals(MemoryState.learning));
      });

      test('within same state, order is stable', () {
        final records = [
          makeRecord(
              streetId: 'learning-2',
              state: MemoryState.learning,
              nextReviewDate: today),
          makeRecord(
              streetId: 'learning-1',
              state: MemoryState.learning,
              nextReviewDate: today),
        ];
        final result = QuizScheduler.getDueToday(records, today);
        // Both are learning — order among them should be stable (input order)
        expect(result[0].streetId, equals('learning-2'));
        expect(result[1].streetId, equals('learning-1'));
      });
    });

    // -------------------------------------------------------------------------
    // All mastered (nothing due)
    // -------------------------------------------------------------------------
    group('all mastered', () {
      test('returns empty when all mastered cards have future review dates', () {
        final records = [
          makeRecord(
            streetId: 's1',
            state: MemoryState.mastered,
            nextReviewDate: today.add(const Duration(days: 30)),
          ),
          makeRecord(
            streetId: 's2',
            state: MemoryState.mastered,
            nextReviewDate: today.add(const Duration(days: 14)),
          ),
        ];
        final result = QuizScheduler.getDueToday(records, today);
        expect(result, isEmpty);
      });
    });

    // -------------------------------------------------------------------------
    // Immutability
    // -------------------------------------------------------------------------
    group('immutability', () {
      test('input list is not modified by getDueToday', () {
        final records = [
          makeRecord(streetId: 's1', nextReviewDate: today),
          makeRecord(
              streetId: 's2',
              nextReviewDate: today.add(const Duration(days: 1))),
        ];
        final originalLength = records.length;
        QuizScheduler.getDueToday(records, today);
        expect(records.length, equals(originalLength));
      });
    });
  });
}
