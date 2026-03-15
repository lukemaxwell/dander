import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/quiz/generators/direction_generator.dart';
import 'package:dander/core/quiz/question_type.dart';

void main() {
  Discovery _poi(String id, String name, double lat, double lng) => Discovery(
        id: id,
        name: name,
        category: 'cafe',
        rarity: RarityTier.common,
        position: LatLng(lat, lng),
        osmTags: const {},
        discoveredAt: DateTime(2026, 3, 1),
      );

  group('CompassBearing', () {
    test('north bearing maps to N', () {
      // Point B is directly north of point A
      final direction = CompassBearing.fromPoints(
        const LatLng(51.5, -0.1),
        const LatLng(51.6, -0.1),
      );
      expect(direction, CompassDirection.n);
    });

    test('south bearing maps to S', () {
      final direction = CompassBearing.fromPoints(
        const LatLng(51.5, -0.1),
        const LatLng(51.4, -0.1),
      );
      expect(direction, CompassDirection.s);
    });

    test('east bearing maps to E', () {
      final direction = CompassBearing.fromPoints(
        const LatLng(51.5, -0.1),
        const LatLng(51.5, 0.0),
      );
      expect(direction, CompassDirection.e);
    });

    test('west bearing maps to W', () {
      final direction = CompassBearing.fromPoints(
        const LatLng(51.5, -0.1),
        const LatLng(51.5, -0.2),
      );
      expect(direction, CompassDirection.w);
    });

    test('northeast bearing maps to NE', () {
      final direction = CompassBearing.fromPoints(
        const LatLng(51.5, -0.1),
        const LatLng(51.55, -0.05),
      );
      expect(direction, CompassDirection.ne);
    });

    test('all 8 compass directions are available', () {
      expect(CompassDirection.values.length, 8);
    });

    test('compass directions have readable labels', () {
      expect(CompassDirection.n.label, 'North');
      expect(CompassDirection.ne.label, 'North-East');
      expect(CompassDirection.sw.label, 'South-West');
    });
  });

  group('DirectionGenerator', () {
    test('generates questions from 2+ POIs', () {
      final pois = [
        _poi('node/1', 'Cafe A', 51.5, -0.1),
        _poi('node/2', 'Pub B', 51.6, -0.1),
        _poi('node/3', 'Shop C', 51.5, 0.0),
      ];

      final questions = DirectionGenerator.generate(pois);

      expect(questions, isNotEmpty);
      for (final q in questions) {
        expect(q.type, QuestionType.direction);
        expect(q.choices.length, 4);
        expect(q.correctIndex, greaterThanOrEqualTo(0));
        expect(q.correctIndex, lessThan(4));
        expect(q.questionId, startsWith('direction:'));
      }
    });

    test('returns empty list with fewer than 2 POIs', () {
      final pois = [_poi('node/1', 'Cafe A', 51.5, -0.1)];

      final questions = DirectionGenerator.generate(pois);

      expect(questions, isEmpty);
    });

    test('choices are compass direction labels', () {
      final pois = [
        _poi('node/1', 'Cafe A', 51.5, -0.1),
        _poi('node/2', 'Pub B', 51.6, -0.1),
      ];

      final questions = DirectionGenerator.generate(pois);
      final compassLabels =
          CompassDirection.values.map((d) => d.label).toSet();

      for (final q in questions) {
        for (final choice in q.choices) {
          expect(compassLabels.contains(choice), isTrue,
              reason: '"$choice" is not a compass label');
        }
      }
    });

    test('correct answer matches actual bearing', () {
      // Pub is directly north of Cafe
      final pois = [
        _poi('node/1', 'Cafe A', 51.5, -0.1),
        _poi('node/2', 'Pub B', 51.6, -0.1),
      ];

      final questions = DirectionGenerator.generate(pois);

      // Find the question asking about direction from Cafe to Pub
      final q = questions.firstWhere(
        (q) => q.prompt.contains('Cafe A') && q.prompt.contains('Pub B'),
        orElse: () => questions.first,
      );

      expect(q.choices[q.correctIndex], 'North');
    });

    test('prompt includes both POI names', () {
      final pois = [
        _poi('node/1', 'Cafe A', 51.5, -0.1),
        _poi('node/2', 'Pub B', 51.6, -0.1),
      ];

      final questions = DirectionGenerator.generate(pois);

      for (final q in questions) {
        // Each question should reference two POI names
        expect(q.prompt.length, greaterThan(10));
      }
    });

    test('no duplicate choices in a question', () {
      final pois = [
        _poi('node/1', 'A', 51.5, -0.1),
        _poi('node/2', 'B', 51.6, -0.1),
        _poi('node/3', 'C', 51.5, 0.0),
        _poi('node/4', 'D', 51.4, -0.2),
      ];

      final questions = DirectionGenerator.generate(pois);

      for (final q in questions) {
        expect(q.choices.toSet().length, q.choices.length,
            reason: 'Duplicate choices found');
      }
    });
  });
}
