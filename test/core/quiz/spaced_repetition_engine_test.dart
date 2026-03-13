import 'package:flutter_test/flutter_test.dart';
import 'package:dander/core/quiz/street_memory_record.dart';
import 'package:dander/core/quiz/quiz_result.dart';
import 'package:dander/core/quiz/spaced_repetition_engine.dart';

void main() {
  final answeredAt = DateTime(2025, 6, 10, 12, 0, 0);

  // Helper to build a record in a given state with specific values.
  StreetMemoryRecord makeRecord({
    String streetId = 'street-1',
    MemoryState state = MemoryState.newCard,
    int intervalDays = 0,
    double easeFactor = 2.5,
    DateTime? nextReviewDate,
    List<DateTime>? reviewHistory,
  }) {
    return StreetMemoryRecord(
      streetId: streetId,
      state: state,
      intervalDays: intervalDays,
      easeFactor: easeFactor,
      nextReviewDate: nextReviewDate ?? DateTime(2025, 6, 10),
      reviewHistory: reviewHistory ?? [],
    );
  }

  group('SpacedRepetitionEngine.processAnswer', () {
    // -------------------------------------------------------------------------
    // CORRECT answers
    // -------------------------------------------------------------------------
    group('correct — newCard state', () {
      test('transitions newCard → review', () {
        final record = makeRecord(state: MemoryState.newCard);
        final updated = SpacedRepetitionEngine.processAnswer(
            record, QuizResult.correct, answeredAt);
        expect(updated.state, equals(MemoryState.review));
      });

      test('sets interval to 1 day', () {
        final record = makeRecord(state: MemoryState.newCard);
        final updated = SpacedRepetitionEngine.processAnswer(
            record, QuizResult.correct, answeredAt);
        expect(updated.intervalDays, equals(1));
      });

      test('nextReviewDate is answeredAt + 1 day', () {
        final record = makeRecord(state: MemoryState.newCard);
        final updated = SpacedRepetitionEngine.processAnswer(
            record, QuizResult.correct, answeredAt);
        expect(updated.nextReviewDate,
            equals(answeredAt.add(const Duration(days: 1))));
      });

      test('easeFactor unchanged on correct', () {
        final record = makeRecord(state: MemoryState.newCard, easeFactor: 2.5);
        final updated = SpacedRepetitionEngine.processAnswer(
            record, QuizResult.correct, answeredAt);
        expect(updated.easeFactor, equals(2.5));
      });
    });

    group('correct — learning state', () {
      test('transitions learning → review', () {
        final record = makeRecord(state: MemoryState.learning, intervalDays: 1);
        final updated = SpacedRepetitionEngine.processAnswer(
            record, QuizResult.correct, answeredAt);
        expect(updated.state, equals(MemoryState.review));
      });

      test('sets interval to 1 day', () {
        final record = makeRecord(state: MemoryState.learning, intervalDays: 1);
        final updated = SpacedRepetitionEngine.processAnswer(
            record, QuizResult.correct, answeredAt);
        expect(updated.intervalDays, equals(1));
      });
    });

    group('correct — review state', () {
      test('stays in review state when interval < 30', () {
        final record = makeRecord(state: MemoryState.review, intervalDays: 7);
        final updated = SpacedRepetitionEngine.processAnswer(
            record, QuizResult.correct, answeredAt);
        expect(updated.state, equals(MemoryState.review));
      });

      test('interval = max(1, (prevInterval * easeFactor).round())', () {
        final record =
            makeRecord(state: MemoryState.review, intervalDays: 3, easeFactor: 2.5);
        final updated = SpacedRepetitionEngine.processAnswer(
            record, QuizResult.correct, answeredAt);
        // 3 * 2.5 = 7.5 → rounds to 8
        expect(updated.intervalDays, equals(8));
      });

      test('interval calculation: 7 days * 2.5 = 17.5 → 18', () {
        final record =
            makeRecord(state: MemoryState.review, intervalDays: 7, easeFactor: 2.5);
        final updated = SpacedRepetitionEngine.processAnswer(
            record, QuizResult.correct, answeredAt);
        expect(updated.intervalDays, equals(18));
      });

      test('interval calculation: 1 day * 2.5 = 2.5 → 3', () {
        final record =
            makeRecord(state: MemoryState.review, intervalDays: 1, easeFactor: 2.5);
        final updated = SpacedRepetitionEngine.processAnswer(
            record, QuizResult.correct, answeredAt);
        expect(updated.intervalDays, equals(3));
      });

      test('interval is at least 1', () {
        // Even with tiny easeFactor and interval 0, result should be >= 1
        final record =
            makeRecord(state: MemoryState.review, intervalDays: 0, easeFactor: 1.3);
        final updated = SpacedRepetitionEngine.processAnswer(
            record, QuizResult.correct, answeredAt);
        expect(updated.intervalDays, greaterThanOrEqualTo(1));
      });

      test('transitions to mastered when interval reaches >= 30', () {
        // 12 * 2.5 = 30 → should become mastered
        final record =
            makeRecord(state: MemoryState.review, intervalDays: 12, easeFactor: 2.5);
        final updated = SpacedRepetitionEngine.processAnswer(
            record, QuizResult.correct, answeredAt);
        expect(updated.intervalDays, equals(30));
        expect(updated.state, equals(MemoryState.mastered));
      });

      test('transitions to mastered when interval > 30', () {
        // Already at 20 days * 2.5 = 50 days
        final record =
            makeRecord(state: MemoryState.review, intervalDays: 20, easeFactor: 2.5);
        final updated = SpacedRepetitionEngine.processAnswer(
            record, QuizResult.correct, answeredAt);
        expect(updated.intervalDays, greaterThanOrEqualTo(30));
        expect(updated.state, equals(MemoryState.mastered));
      });

      test('interval exactly 30 transitions to mastered', () {
        // 12 * 2.5 = 30 exactly
        final record =
            makeRecord(state: MemoryState.review, intervalDays: 12, easeFactor: 2.5);
        final updated = SpacedRepetitionEngine.processAnswer(
            record, QuizResult.correct, answeredAt);
        expect(updated.state, equals(MemoryState.mastered));
      });
    });

    group('correct — mastered state stays mastered', () {
      test('mastered stays mastered on correct answer', () {
        final record = makeRecord(
            state: MemoryState.mastered, intervalDays: 30, easeFactor: 2.5);
        final updated = SpacedRepetitionEngine.processAnswer(
            record, QuizResult.correct, answeredAt);
        expect(updated.state, equals(MemoryState.mastered));
      });

      test('mastered interval continues to grow on correct', () {
        final record = makeRecord(
            state: MemoryState.mastered, intervalDays: 30, easeFactor: 2.5);
        final updated = SpacedRepetitionEngine.processAnswer(
            record, QuizResult.correct, answeredAt);
        expect(updated.intervalDays, greaterThan(30));
      });
    });

    // -------------------------------------------------------------------------
    // Review history append
    // -------------------------------------------------------------------------
    group('reviewHistory', () {
      test('answeredAt is appended to reviewHistory on correct', () {
        final record = makeRecord(reviewHistory: []);
        final updated = SpacedRepetitionEngine.processAnswer(
            record, QuizResult.correct, answeredAt);
        expect(updated.reviewHistory, contains(answeredAt));
      });

      test('answeredAt is appended to reviewHistory on incorrect', () {
        final record = makeRecord(reviewHistory: []);
        final updated = SpacedRepetitionEngine.processAnswer(
            record, QuizResult.incorrect, answeredAt);
        expect(updated.reviewHistory, contains(answeredAt));
      });

      test('existing history is preserved on update', () {
        final past = DateTime(2025, 6, 1);
        final record = makeRecord(reviewHistory: [past]);
        final updated = SpacedRepetitionEngine.processAnswer(
            record, QuizResult.correct, answeredAt);
        expect(updated.reviewHistory, containsAll([past, answeredAt]));
        expect(updated.reviewHistory.length, equals(2));
      });
    });

    // -------------------------------------------------------------------------
    // INCORRECT answers
    // -------------------------------------------------------------------------
    group('incorrect — any state', () {
      for (final state in MemoryState.values) {
        test('any state ($state) → transitions to learning', () {
          final record = makeRecord(state: state, intervalDays: 10);
          final updated = SpacedRepetitionEngine.processAnswer(
              record, QuizResult.incorrect, answeredAt);
          expect(updated.state, equals(MemoryState.learning));
        });
      }

      test('incorrect resets interval to 1', () {
        final record = makeRecord(state: MemoryState.review, intervalDays: 14);
        final updated = SpacedRepetitionEngine.processAnswer(
            record, QuizResult.incorrect, answeredAt);
        expect(updated.intervalDays, equals(1));
      });

      test('incorrect sets nextReviewDate to answeredAt + 1 day', () {
        final record = makeRecord(state: MemoryState.review);
        final updated = SpacedRepetitionEngine.processAnswer(
            record, QuizResult.incorrect, answeredAt);
        expect(updated.nextReviewDate,
            equals(answeredAt.add(const Duration(days: 1))));
      });

      test('incorrect decreases easeFactor by 0.2', () {
        final record =
            makeRecord(state: MemoryState.review, easeFactor: 2.5);
        final updated = SpacedRepetitionEngine.processAnswer(
            record, QuizResult.incorrect, answeredAt);
        expect(updated.easeFactor, closeTo(2.3, 0.0001));
      });

      test('easeFactor does not go below minimum 1.3', () {
        final record =
            makeRecord(state: MemoryState.review, easeFactor: 1.3);
        final updated = SpacedRepetitionEngine.processAnswer(
            record, QuizResult.incorrect, answeredAt);
        expect(updated.easeFactor, equals(1.3));
      });

      test('easeFactor at 1.4 decreases to 1.3 (not below)', () {
        final record =
            makeRecord(state: MemoryState.review, easeFactor: 1.4);
        final updated = SpacedRepetitionEngine.processAnswer(
            record, QuizResult.incorrect, answeredAt);
        expect(updated.easeFactor, closeTo(1.3, 0.0001));
      });

      test('easeFactor at 1.5 decreases to 1.3 (clamps at min)', () {
        // 1.5 - 0.2 = 1.3, which equals min
        final record =
            makeRecord(state: MemoryState.review, easeFactor: 1.5);
        final updated = SpacedRepetitionEngine.processAnswer(
            record, QuizResult.incorrect, answeredAt);
        expect(updated.easeFactor, closeTo(1.3, 0.0001));
      });
    });

    // -------------------------------------------------------------------------
    // Immutability
    // -------------------------------------------------------------------------
    group('immutability', () {
      test('processAnswer does not mutate the original record', () {
        final original = makeRecord(
            state: MemoryState.review, intervalDays: 7, easeFactor: 2.5);
        SpacedRepetitionEngine.processAnswer(
            original, QuizResult.correct, answeredAt);
        expect(original.state, equals(MemoryState.review));
        expect(original.intervalDays, equals(7));
        expect(original.easeFactor, equals(2.5));
      });
    });
  });
}
