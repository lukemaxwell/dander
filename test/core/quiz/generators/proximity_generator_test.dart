import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/quiz/generators/proximity_generator.dart';
import 'package:dander/core/quiz/question_type.dart';

void main() {
  Discovery _poi(String id, String name, String category, double lat,
          double lng) =>
      Discovery(
        id: id,
        name: name,
        category: category,
        rarity: RarityTier.common,
        position: LatLng(lat, lng),
        osmTags: const {},
        discoveredAt: DateTime(2026, 3, 1),
      );

  group('ProximityGenerator', () {
    test('generates questions from 5+ POIs', () {
      final pois = [
        _poi('node/1', 'Cafe A', 'cafe', 51.500, -0.100),
        _poi('node/2', 'Pub B', 'pub', 51.501, -0.100),
        _poi('node/3', 'Shop C', 'shop', 51.510, -0.100),
        _poi('node/4', 'Park D', 'park', 51.520, -0.100),
        _poi('node/5', 'Gallery E', 'gallery', 51.505, -0.100),
      ];

      final questions = ProximityGenerator.generate(pois);

      expect(questions, isNotEmpty);
      for (final q in questions) {
        expect(q.type, QuestionType.proximity);
        expect(q.choices.length, 4);
        expect(q.correctIndex, greaterThanOrEqualTo(0));
        expect(q.correctIndex, lessThan(4));
        expect(q.questionId, startsWith('proximity:'));
      }
    });

    test('returns empty list with fewer than 5 POIs', () {
      final pois = [
        _poi('node/1', 'Cafe A', 'cafe', 51.500, -0.100),
        _poi('node/2', 'Pub B', 'pub', 51.501, -0.100),
        _poi('node/3', 'Shop C', 'shop', 51.510, -0.100),
        _poi('node/4', 'Park D', 'park', 51.520, -0.100),
      ];

      final questions = ProximityGenerator.generate(pois);

      expect(questions, isEmpty);
    });

    test('correct answer is the nearest POI', () {
      // Cafe at 51.500, Pub very close at 51.5005, others further away
      final pois = [
        _poi('node/1', 'Cafe A', 'cafe', 51.500, -0.100),
        _poi('node/2', 'Pub B', 'pub', 51.5005, -0.100), // ~55m away
        _poi('node/3', 'Shop C', 'shop', 51.510, -0.100), // ~1.1km away
        _poi('node/4', 'Park D', 'park', 51.520, -0.100), // ~2.2km away
        _poi('node/5', 'Gallery E', 'gallery', 51.530, -0.100), // ~3.3km
      ];

      final questions = ProximityGenerator.generate(pois);

      // Find question asking "What's nearest to Cafe A?"
      final cafeQ = questions.firstWhere(
        (q) => q.prompt.contains('Cafe A'),
        orElse: () => questions.first,
      );

      // Pub B is nearest to Cafe A
      expect(cafeQ.choices[cafeQ.correctIndex], 'Pub B');
    });

    test('choices are POI names', () {
      final pois = [
        _poi('node/1', 'Cafe A', 'cafe', 51.500, -0.100),
        _poi('node/2', 'Pub B', 'pub', 51.501, -0.100),
        _poi('node/3', 'Shop C', 'shop', 51.510, -0.100),
        _poi('node/4', 'Park D', 'park', 51.520, -0.100),
        _poi('node/5', 'Gallery E', 'gallery', 51.505, -0.100),
      ];

      final questions = ProximityGenerator.generate(pois);
      final poiNames = pois.map((p) => p.name).toSet();

      for (final q in questions) {
        for (final choice in q.choices) {
          expect(poiNames.contains(choice), isTrue,
              reason: '"$choice" is not a known POI name');
        }
      }
    });

    test('no duplicate choices in a question', () {
      final pois = [
        _poi('node/1', 'Cafe A', 'cafe', 51.500, -0.100),
        _poi('node/2', 'Pub B', 'pub', 51.501, -0.100),
        _poi('node/3', 'Shop C', 'shop', 51.510, -0.100),
        _poi('node/4', 'Park D', 'park', 51.520, -0.100),
        _poi('node/5', 'Gallery E', 'gallery', 51.505, -0.100),
      ];

      final questions = ProximityGenerator.generate(pois);

      for (final q in questions) {
        expect(q.choices.toSet().length, q.choices.length,
            reason: 'Duplicate choices found');
      }
    });

    test('prompt includes reference POI name', () {
      final pois = [
        _poi('node/1', 'Cafe A', 'cafe', 51.500, -0.100),
        _poi('node/2', 'Pub B', 'pub', 51.501, -0.100),
        _poi('node/3', 'Shop C', 'shop', 51.510, -0.100),
        _poi('node/4', 'Park D', 'park', 51.520, -0.100),
        _poi('node/5', 'Gallery E', 'gallery', 51.505, -0.100),
      ];

      final questions = ProximityGenerator.generate(pois);

      for (final q in questions) {
        final containsAnyName = pois.any((p) => q.prompt.contains(p.name));
        expect(containsAnyName, isTrue,
            reason: 'Prompt "${q.prompt}" does not reference any POI');
      }
    });

    test('does not include reference POI as a choice', () {
      final pois = [
        _poi('node/1', 'Cafe A', 'cafe', 51.500, -0.100),
        _poi('node/2', 'Pub B', 'pub', 51.501, -0.100),
        _poi('node/3', 'Shop C', 'shop', 51.510, -0.100),
        _poi('node/4', 'Park D', 'park', 51.520, -0.100),
        _poi('node/5', 'Gallery E', 'gallery', 51.505, -0.100),
      ];

      final questions = ProximityGenerator.generate(pois);

      for (final q in questions) {
        // Extract the reference POI name from the prompt
        final refPoi = pois.firstWhere((p) => q.prompt.contains(p.name));
        expect(q.choices.contains(refPoi.name), isFalse,
            reason:
                'Reference POI "${refPoi.name}" should not be in choices');
      }
    });
  });
}
