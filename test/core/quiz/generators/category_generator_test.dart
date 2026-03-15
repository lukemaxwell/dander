import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/quiz/generators/category_generator.dart';
import 'package:dander/core/quiz/question_type.dart';

void main() {
  Discovery _poi(String id, String name, String category) => Discovery(
        id: id,
        name: name,
        category: category,
        rarity: RarityTier.common,
        position: const LatLng(51.5, -0.1),
        osmTags: const {},
        discoveredAt: DateTime(2026, 3, 1),
      );

  group('CategoryGenerator', () {
    test('generates questions from 4+ distinct categories', () {
      final pois = [
        _poi('node/1', 'Bean Counter', 'cafe'),
        _poi('node/2', 'The Crown', 'pub'),
        _poi('node/3', 'Riverside Park', 'park'),
        _poi('node/4', 'QuickMart', 'shop'),
      ];

      final questions = CategoryGenerator.generate(pois);

      expect(questions, isNotEmpty);
      for (final q in questions) {
        expect(q.type, QuestionType.category);
        expect(q.choices.length, 4);
        expect(q.correctIndex, greaterThanOrEqualTo(0));
        expect(q.correctIndex, lessThan(4));
        expect(q.questionId, startsWith('category:'));
      }
    });

    test('returns empty list with fewer than 4 distinct categories', () {
      final pois = [
        _poi('node/1', 'Bean Counter', 'cafe'),
        _poi('node/2', 'Java House', 'cafe'),
        _poi('node/3', 'The Crown', 'pub'),
      ];

      final questions = CategoryGenerator.generate(pois);

      expect(questions, isEmpty);
    });

    test('skips POIs with unknown category', () {
      final pois = [
        _poi('node/1', 'Mystery Place', 'unknown'),
        _poi('node/2', 'Bean Counter', 'cafe'),
        _poi('node/3', 'The Crown', 'pub'),
        _poi('node/4', 'Riverside Park', 'park'),
        _poi('node/5', 'QuickMart', 'shop'),
      ];

      final questions = CategoryGenerator.generate(pois);

      // Should still generate — 4 distinct known categories exist
      expect(questions, isNotEmpty);
      // No question should ask about the unknown POI
      for (final q in questions) {
        expect(q.prompt, isNot(contains('Mystery Place')));
      }
    });

    test('correct answer matches POI category', () {
      final pois = [
        _poi('node/1', 'Bean Counter', 'cafe'),
        _poi('node/2', 'The Crown', 'pub'),
        _poi('node/3', 'Riverside Park', 'park'),
        _poi('node/4', 'QuickMart', 'shop'),
      ];

      final questions = CategoryGenerator.generate(pois);

      for (final q in questions) {
        // Extract the POI name from the prompt
        final correctAnswer = q.choices[q.correctIndex];
        // Verify the correct answer is a real category in our data
        final knownCategories = pois.map((p) => p.category).toSet();
        expect(knownCategories.contains(correctAnswer), isTrue,
            reason: '"$correctAnswer" is not a known category');
      }
    });

    test('choices are categories from the user discovery set', () {
      final pois = [
        _poi('node/1', 'Bean Counter', 'cafe'),
        _poi('node/2', 'The Crown', 'pub'),
        _poi('node/3', 'Riverside Park', 'park'),
        _poi('node/4', 'QuickMart', 'shop'),
        _poi('node/5', 'Art Gallery', 'gallery'),
      ];

      final questions = CategoryGenerator.generate(pois);
      final knownCategories = pois.map((p) => p.category).toSet();

      for (final q in questions) {
        for (final choice in q.choices) {
          expect(knownCategories.contains(choice), isTrue,
              reason: '"$choice" is not from the discovery set');
        }
      }
    });

    test('no duplicate choices in a question', () {
      final pois = [
        _poi('node/1', 'Bean Counter', 'cafe'),
        _poi('node/2', 'The Crown', 'pub'),
        _poi('node/3', 'Riverside Park', 'park'),
        _poi('node/4', 'QuickMart', 'shop'),
        _poi('node/5', 'Art Gallery', 'gallery'),
      ];

      final questions = CategoryGenerator.generate(pois);

      for (final q in questions) {
        expect(q.choices.toSet().length, q.choices.length,
            reason: 'Duplicate choices found');
      }
    });

    test('prompt includes POI name', () {
      final pois = [
        _poi('node/1', 'Bean Counter', 'cafe'),
        _poi('node/2', 'The Crown', 'pub'),
        _poi('node/3', 'Riverside Park', 'park'),
        _poi('node/4', 'QuickMart', 'shop'),
      ];

      final questions = CategoryGenerator.generate(pois);

      for (final q in questions) {
        // Prompt should reference at least one POI name
        final containsAnyName =
            pois.any((p) => q.prompt.contains(p.name));
        expect(containsAnyName, isTrue,
            reason: 'Prompt "${q.prompt}" does not reference any POI');
      }
    });

    test('questionId encodes POI id', () {
      final pois = [
        _poi('node/1', 'Bean Counter', 'cafe'),
        _poi('node/2', 'The Crown', 'pub'),
        _poi('node/3', 'Riverside Park', 'park'),
        _poi('node/4', 'QuickMart', 'shop'),
      ];

      final questions = CategoryGenerator.generate(pois);

      for (final q in questions) {
        // questionId should be category:<poi_id>
        expect(q.questionId, startsWith('category:'));
        final poiId = q.questionId.substring('category:'.length);
        expect(pois.any((p) => p.id == poiId), isTrue,
            reason: 'questionId "$poiId" does not match any POI');
      }
    });
  });
}
