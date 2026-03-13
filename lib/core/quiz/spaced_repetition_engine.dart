import 'street_memory_record.dart';
import 'quiz_result.dart';

/// Pure, stateless SM-2 spaced repetition engine.
///
/// All methods are static and return new [StreetMemoryRecord] instances —
/// the input record is never mutated.
class SpacedRepetitionEngine {
  SpacedRepetitionEngine._();

  /// Minimum allowed ease factor.
  static const double _minEaseFactor = 1.3;

  /// Interval threshold (days) at which a card becomes [MemoryState.mastered].
  static const int _masteredThreshold = 30;

  /// Processes a quiz answer and returns an updated [StreetMemoryRecord].
  ///
  /// SM-2 rules applied:
  ///
  /// **Correct:**
  /// - [MemoryState.newCard] or [MemoryState.learning]
  ///   → state = [MemoryState.review], interval = 1
  /// - [MemoryState.review] or [MemoryState.mastered]
  ///   → interval = max(1, (prevInterval × easeFactor).round())
  /// - If resulting interval ≥ 30 → state = [MemoryState.mastered]
  /// - easeFactor unchanged
  /// - nextReviewDate = answeredAt + intervalDays
  ///
  /// **Incorrect:**
  /// - Any state → state = [MemoryState.learning], interval = 1
  /// - easeFactor = max(1.3, easeFactor − 0.2)
  /// - nextReviewDate = answeredAt + 1 day
  static StreetMemoryRecord processAnswer(
    StreetMemoryRecord record,
    QuizResult result,
    DateTime answeredAt,
  ) {
    final updatedHistory = List<DateTime>.unmodifiable(
      [...record.reviewHistory, answeredAt],
    );

    return switch (result) {
      QuizResult.correct => _processCorrect(record, answeredAt, updatedHistory),
      QuizResult.incorrect =>
        _processIncorrect(record, answeredAt, updatedHistory),
    };
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static StreetMemoryRecord _processCorrect(
    StreetMemoryRecord record,
    DateTime answeredAt,
    List<DateTime> updatedHistory,
  ) {
    final int newInterval;

    switch (record.state) {
      case MemoryState.newCard:
      case MemoryState.learning:
        newInterval = 1;
      case MemoryState.review:
      case MemoryState.mastered:
        final computed = (record.intervalDays * record.easeFactor).round();
        newInterval = computed < 1 ? 1 : computed;
    }

    final newState = newInterval >= _masteredThreshold
        ? MemoryState.mastered
        : MemoryState.review;

    return record.copyWith(
      state: newState,
      intervalDays: newInterval,
      nextReviewDate: answeredAt.add(Duration(days: newInterval)),
      reviewHistory: updatedHistory,
    );
  }

  static StreetMemoryRecord _processIncorrect(
    StreetMemoryRecord record,
    DateTime answeredAt,
    List<DateTime> updatedHistory,
  ) {
    final newEase = (record.easeFactor - 0.2) < _minEaseFactor
        ? _minEaseFactor
        : record.easeFactor - 0.2;

    return record.copyWith(
      state: MemoryState.learning,
      intervalDays: 1,
      easeFactor: newEase,
      nextReviewDate: answeredAt.add(const Duration(days: 1)),
      reviewHistory: updatedHistory,
    );
  }
}
