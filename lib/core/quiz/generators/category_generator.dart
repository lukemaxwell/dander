import 'dart:math';

import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/quiz/generated_question.dart';
import 'package:dander/core/quiz/question_type.dart';

/// Generates "What type of place is [POI]?" questions.
///
/// Requires at least 4 distinct non-"unknown" categories in the discovery set
/// to produce meaningful distractors.
abstract final class CategoryGenerator {
  static final _rng = Random();

  /// Generates category questions from [pois].
  ///
  /// Returns an empty list if fewer than 4 distinct known categories exist.
  static List<GeneratedQuestion> generate(List<Discovery> pois) {
    // Filter out unknown categories
    final knownPois =
        pois.where((p) => p.category != 'unknown').toList();
    final distinctCategories =
        knownPois.map((p) => p.category).toSet();

    if (distinctCategories.length < 4) return const [];

    final questions = <GeneratedQuestion>[];

    for (final poi in knownPois) {
      final correct = poi.category;
      final distractors = distinctCategories
          .where((c) => c != correct)
          .toList()
        ..shuffle(_rng);

      final choices = distractors.take(3).toList();
      final insertAt = _rng.nextInt(choices.length + 1);
      choices.insert(insertAt, correct);

      questions.add(GeneratedQuestion(
        questionId: 'category:${poi.id}',
        type: QuestionType.category,
        prompt: 'What type of place is ${poi.name}?',
        choices: choices,
        correctIndex: insertAt,
      ));
    }

    return questions;
  }
}
