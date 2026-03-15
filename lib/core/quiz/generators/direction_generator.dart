import 'dart:math';

import 'package:latlong2/latlong.dart';

import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/quiz/generated_question.dart';
import 'package:dander/core/quiz/question_type.dart';

/// The eight cardinal and intercardinal compass directions.
enum CompassDirection {
  n('North'),
  ne('North-East'),
  e('East'),
  se('South-East'),
  s('South'),
  sw('South-West'),
  w('West'),
  nw('North-West');

  const CompassDirection(this.label);

  /// Human-readable label shown in quiz choices.
  final String label;
}

/// Calculates compass bearing between two geographic points.
abstract final class CompassBearing {
  /// Returns the [CompassDirection] from [from] to [to].
  ///
  /// Uses the forward azimuth formula to compute bearing in degrees,
  /// then maps to one of eight 45-degree sectors.
  static CompassDirection fromPoints(LatLng from, LatLng to) {
    final lat1 = from.latitudeInRad;
    final lat2 = to.latitudeInRad;
    final dLng = (to.longitude - from.longitude) * pi / 180.0;

    final x = sin(dLng) * cos(lat2);
    final y = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);

    final bearing = (atan2(x, y) * 180.0 / pi + 360.0) % 360.0;

    return _bearingToDirection(bearing);
  }

  static CompassDirection _bearingToDirection(double bearing) {
    // Each sector is 45°, offset by 22.5° so N covers 337.5–22.5.
    const sectors = CompassDirection.values;
    final index = ((bearing + 22.5) % 360.0) ~/ 45.0;
    return sectors[index];
  }
}

/// Generates direction questions from discovered POIs.
///
/// Questions ask "Which direction is [POI B] from [POI A]?" with four
/// compass direction choices.
abstract final class DirectionGenerator {
  static final _rng = Random();

  /// Generates direction questions from [pois].
  ///
  /// Returns an empty list if fewer than 2 POIs are provided.
  static List<GeneratedQuestion> generate(List<Discovery> pois) {
    if (pois.length < 2) return const [];

    final questions = <GeneratedQuestion>[];

    for (var i = 0; i < pois.length; i++) {
      for (var j = i + 1; j < pois.length; j++) {
        final from = pois[i];
        final to = pois[j];

        final correct = CompassBearing.fromPoints(from.position, to.position);
        final choices = _buildChoices(correct);

        questions.add(GeneratedQuestion(
          questionId: 'direction:${from.id}-${to.id}',
          type: QuestionType.direction,
          prompt:
              'Which direction is ${to.name} from ${from.name}?',
          choices: choices,
          correctIndex: choices.indexOf(correct.label),
        ));
      }
    }

    return questions;
  }

  /// Builds a list of 4 compass direction labels including [correct].
  ///
  /// Picks 3 random distractors from the remaining directions.
  static List<String> _buildChoices(CompassDirection correct) {
    final others = CompassDirection.values
        .where((d) => d != correct)
        .toList()
      ..shuffle(_rng);

    final distractors = others.take(3).toList();
    final choices = distractors.map((d) => d.label).toList();

    final insertAt = _rng.nextInt(choices.length + 1);
    choices.insert(insertAt, correct.label);

    return choices;
  }
}
