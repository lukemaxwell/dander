import 'dart:math';

import 'package:latlong2/latlong.dart';

import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/location/walk_session.dart';
import 'package:dander/core/quiz/generated_question.dart';
import 'package:dander/core/quiz/question_type.dart';
import 'package:dander/core/streets/street.dart';

/// Generates "What street connects [POI A] and [POI B]?" questions.
///
/// Cross-references walk sessions with discovery timestamps to find POI pairs
/// discovered during the same walk, then identifies the nearest street.
abstract final class RouteGenerator {
  static final _rng = Random();
  static const _haversine = Distance();

  /// Generates route questions from [walks], [discoveries], and [streets].
  ///
  /// Returns an empty list if no walk has 2+ POI discoveries or if fewer
  /// than 4 streets are available for distractor choices.
  static List<GeneratedQuestion> generate(
    List<WalkSession> walks,
    List<Discovery> discoveries,
    List<Street> streets,
  ) {
    if (streets.length < 4) return const [];

    final questions = <GeneratedQuestion>[];

    for (final walk in walks) {
      if (walk.endTime == null) continue;

      // Find discoveries made during this walk
      final walkPois = discoveries.where((d) {
        if (d.discoveredAt == null) return false;
        return !d.discoveredAt!.isBefore(walk.startTime) &&
            !d.discoveredAt!.isAfter(walk.endTime!);
      }).toList();

      if (walkPois.length < 2) continue;

      // Generate questions for pairs of POIs from this walk
      for (var i = 0; i < walkPois.length; i++) {
        for (var j = i + 1; j < walkPois.length; j++) {
          final poiA = walkPois[i];
          final poiB = walkPois[j];

          final nearest = _findNearestStreet(poiA.position, poiB.position, streets);
          if (nearest == null) continue;

          final choices = _buildChoices(nearest, streets);
          if (choices == null) continue;

          questions.add(GeneratedQuestion(
            questionId: 'route:${poiA.id}-${poiB.id}',
            type: QuestionType.route,
            prompt:
                'What street connects ${poiA.name} and ${poiB.name}?',
            choices: choices,
            correctIndex: choices.indexOf(nearest.name),
          ));
        }
      }
    }

    return questions;
  }

  /// Finds the street whose geometry is closest to both POI positions.
  ///
  /// Uses the sum of minimum distances from each POI to any node on the
  /// street as the proximity metric.
  static Street? _findNearestStreet(
    LatLng posA,
    LatLng posB,
    List<Street> streets,
  ) {
    Street? best;
    double bestScore = double.infinity;

    for (final street in streets) {
      if (street.nodes.isEmpty) continue;

      final distA = _minDistanceToStreet(posA, street);
      final distB = _minDistanceToStreet(posB, street);
      final score = distA + distB;

      if (score < bestScore) {
        bestScore = score;
        best = street;
      }
    }

    return best;
  }

  /// Returns the minimum Haversine distance from [point] to any node
  /// in [street].
  static double _minDistanceToStreet(LatLng point, Street street) {
    double minDist = double.infinity;
    for (final node in street.nodes) {
      final dist = _haversine.as(LengthUnit.Meter, point, node);
      if (dist < minDist) minDist = dist;
    }
    return minDist;
  }

  /// Builds 4 street-name choices including [correct], with 3 random
  /// distractors. Returns `null` if not enough unique street names.
  static List<String>? _buildChoices(Street correct, List<Street> streets) {
    final otherNames = streets
        .where((s) => s.name != correct.name)
        .map((s) => s.name)
        .toSet()
        .toList()
      ..shuffle(_rng);

    if (otherNames.length < 3) return null;

    final choices = otherNames.take(3).toList();
    final insertAt = _rng.nextInt(choices.length + 1);
    choices.insert(insertAt, correct.name);

    return choices;
  }
}
