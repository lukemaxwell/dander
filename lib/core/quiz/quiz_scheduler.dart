import 'street_memory_record.dart';

/// Selects and prioritises streets due for review in today's quiz session.
class QuizScheduler {
  QuizScheduler._();

  /// Maximum number of streets returned per session.
  static const int maxSessionSize = 20;

  /// Returns streets whose [StreetMemoryRecord.nextReviewDate] is on or before
  /// [today] (date comparison only — time component ignored), capped at
  /// [maxSessionSize].
  ///
  /// Priority order within the returned list:
  /// 1. [MemoryState.learning]
  /// 2. [MemoryState.review]
  /// 3. [MemoryState.newCard]
  /// 4. [MemoryState.mastered]
  ///
  /// Within the same state the original input order is preserved (stable sort).
  static List<StreetMemoryRecord> getDueToday(
    List<StreetMemoryRecord> records,
    DateTime today,
  ) {
    final todayDate = DateTime(today.year, today.month, today.day);

    final due = records.where((r) {
      final reviewDate = DateTime(
        r.nextReviewDate.year,
        r.nextReviewDate.month,
        r.nextReviewDate.day,
      );
      return !reviewDate.isAfter(todayDate);
    }).toList(growable: false);

    // Stable sort by priority bucket.
    final sorted = [...due]..sort(
        (a, b) => _priority(a.state).compareTo(_priority(b.state)),
      );

    return sorted.length <= maxSessionSize
        ? sorted
        : sorted.sublist(0, maxSessionSize);
  }

  /// Lower number = higher priority.
  static int _priority(MemoryState state) => switch (state) {
        MemoryState.learning => 0,
        MemoryState.review => 1,
        MemoryState.newCard => 2,
        MemoryState.mastered => 3,
      };
}
