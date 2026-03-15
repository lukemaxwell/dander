import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/location/walk_session.dart';
import 'package:dander/core/quiz/generated_question.dart';
import 'package:dander/core/quiz/generators/category_generator.dart';
import 'package:dander/core/quiz/generators/direction_generator.dart';
import 'package:dander/core/quiz/generators/proximity_generator.dart';
import 'package:dander/core/quiz/generators/route_generator.dart';
import 'package:dander/core/quiz/memory_record.dart';
import 'package:dander/core/quiz/question_type.dart';
import 'package:dander/core/streets/street.dart';

/// Builds mixed quiz sessions drawing from all available question types.
///
/// Caps sessions at [maxQuestions] with at most [maxPerType] of any single
/// type. Prioritises questions that are due for review via spaced repetition.
abstract final class MixedSessionBuilder {
  static const int maxQuestions = 20;
  static const int maxPerType = 8;

  /// Builds a mixed quiz session from available data.
  ///
  /// [discoveries] — all discovered POIs.
  /// [streets] — all walked streets.
  /// [walks] — completed walk sessions.
  /// [records] — existing spaced repetition records for priority ordering.
  static List<GeneratedQuestion> build({
    required List<Discovery> discoveries,
    required List<Street> streets,
    required List<WalkSession> walks,
    required List<MemoryRecord> records,
  }) {
    // Generate all possible questions from each generator
    final allQuestions = <GeneratedQuestion>[
      ...DirectionGenerator.generate(discoveries),
      ...CategoryGenerator.generate(discoveries),
      ...ProximityGenerator.generate(discoveries),
      ...RouteGenerator.generate(walks, discoveries, streets),
    ];

    if (allQuestions.isEmpty) return const [];

    // Build a lookup of existing records by questionId
    final recordMap = {for (final r in records) r.questionId: r};

    // Sort: due questions first (by next review date), then new questions
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    allQuestions.sort((a, b) {
      final recordA = recordMap[a.questionId];
      final recordB = recordMap[b.questionId];

      final priorityA = _priority(recordA, today);
      final priorityB = _priority(recordB, today);

      return priorityA.compareTo(priorityB);
    });

    // Select questions respecting type caps
    final selected = <GeneratedQuestion>[];
    final typeCounts = <QuestionType, int>{};

    for (final q in allQuestions) {
      if (selected.length >= maxQuestions) break;

      final count = typeCounts[q.type] ?? 0;
      if (count >= maxPerType) continue;

      selected.add(q);
      typeCounts[q.type] = count + 1;
    }

    // Shuffle to avoid predictable type ordering within the session
    selected.shuffle();

    return selected;
  }

  /// Returns a priority score (lower = higher priority).
  ///
  /// Due/overdue questions get negative scores (most urgent first).
  /// New questions get 0. Future questions get positive scores.
  static int _priority(MemoryRecord? record, DateTime today) {
    if (record == null) return 0; // New question — neutral priority

    final daysUntilDue = record.nextReviewDate.difference(today).inDays;
    return daysUntilDue; // Overdue = negative = higher priority
  }
}

/// Calculates the user's neighbourhood knowledge score.
///
/// Mastered questions count as 100%, review questions as 50%,
/// and new/learning questions as 0%.
abstract final class KnowledgeScore {
  /// Returns a percentage (0–100) representing mastery across all [records].
  static double calculate(List<MemoryRecord> records) {
    if (records.isEmpty) return 0.0;

    double totalCredit = 0;

    for (final record in records) {
      switch (record.state) {
        case MemoryState.mastered:
          totalCredit += 1.0;
        case MemoryState.review:
          totalCredit += 0.5;
        case MemoryState.newCard:
        case MemoryState.learning:
          totalCredit += 0.0;
      }
    }

    return (totalCredit / records.length) * 100.0;
  }
}
