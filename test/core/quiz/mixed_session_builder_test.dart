import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/location/walk_session.dart';
import 'package:dander/core/quiz/generated_question.dart';
import 'package:dander/core/quiz/memory_record.dart';
import 'package:dander/core/quiz/mixed_session_builder.dart';
import 'package:dander/core/quiz/question_type.dart';
import 'package:dander/core/streets/street.dart';

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

  Street _street(String id, String name, double lat) => Street(
        id: id,
        name: name,
        nodes: [LatLng(lat, -0.100), LatLng(lat + 0.002, -0.100)],
        walkedAt: DateTime(2026, 3, 1),
      );

  group('MixedSessionBuilder', () {
    test('builds a session with mixed question types', () {
      final pois = [
        _poi('node/1', 'Cafe A', 'cafe', 51.500, -0.100),
        _poi('node/2', 'Pub B', 'pub', 51.501, -0.100),
        _poi('node/3', 'Shop C', 'shop', 51.510, -0.100),
        _poi('node/4', 'Park D', 'park', 51.520, -0.100),
        _poi('node/5', 'Gallery E', 'gallery', 51.505, -0.100),
      ];

      final streets = [
        _street('way/1', 'High Street', 51.500),
        _street('way/2', 'Low Road', 51.510),
        _street('way/3', 'Park Lane', 51.520),
        _street('way/4', 'Mill Way', 51.530),
      ];

      final session = MixedSessionBuilder.build(
        discoveries: pois,
        streets: streets,
        walks: const [],
        records: const [],
      );

      expect(session, isNotEmpty);
      // Should have multiple question types
      final types = session.map((q) => q.type).toSet();
      expect(types.length, greaterThan(1));
    });

    test('caps session at 20 questions', () {
      // Generate many POIs to exceed the cap
      final pois = List.generate(
        20,
        (i) => _poi('node/$i', 'Place $i', 'cat${i % 5}', 51.5 + i * 0.001, -0.1),
      );

      final streets = [
        _street('way/1', 'High Street', 51.500),
        _street('way/2', 'Low Road', 51.510),
        _street('way/3', 'Park Lane', 51.520),
        _street('way/4', 'Mill Way', 51.530),
      ];

      final session = MixedSessionBuilder.build(
        discoveries: pois,
        streets: streets,
        walks: const [],
        records: const [],
      );

      expect(session.length, lessThanOrEqualTo(20));
    });

    test('no more than 8 questions of any single type', () {
      final pois = List.generate(
        20,
        (i) => _poi('node/$i', 'Place $i', 'cat${i % 5}', 51.5 + i * 0.001, -0.1),
      );

      final streets = [
        _street('way/1', 'High Street', 51.500),
        _street('way/2', 'Low Road', 51.510),
        _street('way/3', 'Park Lane', 51.520),
        _street('way/4', 'Mill Way', 51.530),
      ];

      final session = MixedSessionBuilder.build(
        discoveries: pois,
        streets: streets,
        walks: const [],
        records: const [],
      );

      for (final type in QuestionType.values) {
        final count = session.where((q) => q.type == type).length;
        expect(count, lessThanOrEqualTo(8),
            reason: '$type exceeds max 8 per session');
      }
    });

    test('returns empty session when no data available', () {
      final session = MixedSessionBuilder.build(
        discoveries: const [],
        streets: const [],
        walks: const [],
        records: const [],
      );

      expect(session, isEmpty);
    });

    test('prioritises due questions via spaced repetition', () {
      final pois = [
        _poi('node/1', 'Cafe A', 'cafe', 51.500, -0.100),
        _poi('node/2', 'Pub B', 'pub', 51.501, -0.100),
        _poi('node/3', 'Shop C', 'shop', 51.510, -0.100),
        _poi('node/4', 'Park D', 'park', 51.520, -0.100),
        _poi('node/5', 'Gallery E', 'gallery', 51.505, -0.100),
      ];

      // Mark a direction question as due today (newCard state)
      final records = [
        MemoryRecord.initial('direction:node/1-node/2'),
      ];

      final session = MixedSessionBuilder.build(
        discoveries: pois,
        streets: const [],
        walks: const [],
        records: records,
      );

      // The due question should appear in the session
      final dueQuestionPresent = session.any(
        (q) => q.questionId == 'direction:node/1-node/2',
      );
      expect(dueQuestionPresent, isTrue);
    });
  });

  group('KnowledgeScore', () {
    test('returns 0 when no records exist', () {
      final score = KnowledgeScore.calculate(const []);
      expect(score, 0.0);
    });

    test('returns 100 when all records are mastered', () {
      final records = [
        MemoryRecord(
          questionId: 'direction:a-b',
          state: MemoryState.mastered,
          intervalDays: 30,
          easeFactor: 2.5,
          nextReviewDate: DateTime(2026, 4, 15),
          reviewHistory: const [],
        ),
        MemoryRecord(
          questionId: 'category:node/1',
          state: MemoryState.mastered,
          intervalDays: 30,
          easeFactor: 2.5,
          nextReviewDate: DateTime(2026, 4, 15),
          reviewHistory: const [],
        ),
      ];

      final score = KnowledgeScore.calculate(records);
      expect(score, 100.0);
    });

    test('returns percentage of mastered records', () {
      final records = [
        MemoryRecord(
          questionId: 'direction:a-b',
          state: MemoryState.mastered,
          intervalDays: 30,
          easeFactor: 2.5,
          nextReviewDate: DateTime(2026, 4, 15),
          reviewHistory: const [],
        ),
        MemoryRecord.initial('category:node/1'),
        MemoryRecord.initial('proximity:node/2'),
        MemoryRecord.initial('route:a-b'),
      ];

      final score = KnowledgeScore.calculate(records);
      expect(score, 25.0); // 1 of 4 mastered
    });

    test('review state counts partially towards score', () {
      final records = [
        MemoryRecord(
          questionId: 'direction:a-b',
          state: MemoryState.review,
          intervalDays: 5,
          easeFactor: 2.5,
          nextReviewDate: DateTime(2026, 3, 20),
          reviewHistory: const [],
        ),
      ];

      final score = KnowledgeScore.calculate(records);
      // Review = 50% mastery credit
      expect(score, 50.0);
    });
  });
}
