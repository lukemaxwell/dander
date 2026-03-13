import 'dart:math';

import 'package:dander/core/quiz/quiz_result.dart';
import 'package:dander/core/quiz/street_memory_record.dart';
import 'package:dander/core/streets/street.dart';

/// A single quiz question: identify the [targetStreet] from [choices].
class QuizQuestion {
  const QuizQuestion({
    required this.targetStreet,
    required this.choices,
    required this.correctIndex,
  });

  /// The street the user must identify.
  final Street targetStreet;

  /// The four answer choices (including [targetStreet]).
  final List<Street> choices;

  /// Index in [choices] where [targetStreet] appears.
  final int correctIndex;
}

/// Immutable state object representing an in-progress quiz session.
///
/// Use [QuizSession.create] to build a session from walked streets.
/// Advance through questions with [answerCurrent], which returns a new instance.
class QuizSession {
  const QuizSession({
    required this.questions,
    required this.currentIndex,
    required this.correctCount,
  });

  /// Builds a quiz session from [streets] using [records] to order questions.
  ///
  /// Questions are constructed by pairing each street as the target with three
  /// randomly selected distractors from the remaining streets.
  factory QuizSession.create(
    List<Street> streets,
    List<StreetMemoryRecord> records,
  ) {
    if (streets.isEmpty) {
      return const QuizSession(
        questions: [],
        currentIndex: 0,
        correctCount: 0,
      );
    }

    final rng = Random();
    final questions = <QuizQuestion>[];

    for (final target in streets) {
      final others = streets.where((s) => s.id != target.id).toList();
      others.shuffle(rng);
      final distractors = others.take(3).toList();

      // Build choices and insert target at a random position
      final choices = List<Street>.from(distractors);
      final insertAt = rng.nextInt(choices.length + 1);
      choices.insert(insertAt, target);

      questions.add(QuizQuestion(
        targetStreet: target,
        choices: choices,
        correctIndex: insertAt,
      ));
    }

    return QuizSession(
      questions: questions,
      currentIndex: 0,
      correctCount: 0,
    );
  }

  /// Ordered list of questions for this session.
  final List<QuizQuestion> questions;

  /// Index of the current (unanswered) question.
  final int currentIndex;

  /// Number of correct answers so far.
  final int correctCount;

  /// Whether all questions have been answered.
  bool get isComplete => currentIndex >= questions.length;

  /// The current question. Must not be called when [isComplete] is true.
  QuizQuestion get currentQuestion => questions[currentIndex];

  /// Returns a new [QuizSession] after answering the current question with
  /// [result].
  ///
  /// The original session is never mutated.
  QuizSession answerCurrent(QuizResult result) {
    return QuizSession(
      questions: questions,
      currentIndex: currentIndex + 1,
      correctCount:
          result == QuizResult.correct ? correctCount + 1 : correctCount,
    );
  }
}
