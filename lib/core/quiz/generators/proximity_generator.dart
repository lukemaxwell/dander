import 'dart:math';

import 'package:latlong2/latlong.dart';

import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/quiz/generated_question.dart';
import 'package:dander/core/quiz/question_type.dart';

/// Generates "What's the nearest [category] to [POI]?" questions.
///
/// Uses Haversine distance to determine the genuinely nearest POI.
/// Requires at least 4 POIs to produce meaningful distractors.
abstract final class ProximityGenerator {
  static final _rng = Random();
  static const _haversine = Distance();

  /// Generates proximity questions from [pois].
  ///
  /// Returns an empty list if fewer than 4 POIs are provided.
  static List<GeneratedQuestion> generate(List<Discovery> pois) {
    if (pois.length < 5) return const [];

    final questions = <GeneratedQuestion>[];

    for (final ref in pois) {
      final others = pois.where((p) => p.id != ref.id).toList();

      // Sort by distance from ref
      others.sort((a, b) {
        final distA = _haversine.as(LengthUnit.Meter, ref.position, a.position);
        final distB = _haversine.as(LengthUnit.Meter, ref.position, b.position);
        return distA.compareTo(distB);
      });

      final nearest = others.first;

      // Pick 3 distractors from the remaining (not nearest)
      final distractorPool = others.sublist(1)..shuffle(_rng);
      final distractors = distractorPool.take(min(3, distractorPool.length)).toList();

      if (distractors.length < 3) continue;

      final choices = distractors.map((d) => d.name).toList();
      final insertAt = _rng.nextInt(choices.length + 1);
      choices.insert(insertAt, nearest.name);

      questions.add(GeneratedQuestion(
        questionId: 'proximity:${ref.id}',
        type: QuestionType.proximity,
        prompt: "What's the nearest place to ${ref.name}?",
        choices: choices,
        correctIndex: insertAt,
      ));
    }

    return questions;
  }
}
