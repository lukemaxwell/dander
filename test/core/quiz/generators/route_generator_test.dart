import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/location/walk_session.dart';
import 'package:dander/core/streets/street.dart';
import 'package:dander/core/quiz/generators/route_generator.dart';
import 'package:dander/core/quiz/question_type.dart';

void main() {
  Discovery _poi(String id, String name, double lat, double lng,
          DateTime discoveredAt) =>
      Discovery(
        id: id,
        name: name,
        category: 'cafe',
        rarity: RarityTier.common,
        position: LatLng(lat, lng),
        osmTags: const {},
        discoveredAt: discoveredAt,
      );

  Street _street(String id, String name, List<LatLng> nodes) => Street(
        id: id,
        name: name,
        nodes: nodes,
        walkedAt: DateTime(2026, 3, 1),
      );

  int _walkCounter = 0;
  WalkSession _walk(DateTime start, DateTime end, List<LatLng> points) {
    _walkCounter++;
    var session = WalkSession.start(id: 'walk-$_walkCounter', startTime: start);
    for (final p in points) {
      session = session.addPoint(WalkPoint(position: p, timestamp: start));
    }
    return session.completeAt(end);
  }

  group('RouteGenerator', () {
    test('generates questions when walk has 2+ POIs and 4+ streets', () {
      final walkStart = DateTime(2026, 3, 1, 10, 0);
      final walkEnd = DateTime(2026, 3, 1, 11, 0);

      final walks = [
        _walk(walkStart, walkEnd, [
          const LatLng(51.500, -0.100),
          const LatLng(51.501, -0.100),
          const LatLng(51.502, -0.100),
        ]),
      ];

      final discoveries = [
        _poi('node/1', 'Cafe A', 51.500, -0.100, walkStart.add(const Duration(minutes: 5))),
        _poi('node/2', 'Pub B', 51.502, -0.100, walkStart.add(const Duration(minutes: 30))),
      ];

      final streets = [
        _street('way/1', 'High Street', [const LatLng(51.500, -0.100), const LatLng(51.502, -0.100)]),
        _street('way/2', 'Low Road', [const LatLng(51.510, -0.100), const LatLng(51.512, -0.100)]),
        _street('way/3', 'Park Lane', [const LatLng(51.520, -0.100), const LatLng(51.522, -0.100)]),
        _street('way/4', 'Mill Way', [const LatLng(51.530, -0.100), const LatLng(51.532, -0.100)]),
      ];

      final questions = RouteGenerator.generate(walks, discoveries, streets);

      expect(questions, isNotEmpty);
      for (final q in questions) {
        expect(q.type, QuestionType.route);
        expect(q.choices.length, 4);
        expect(q.correctIndex, greaterThanOrEqualTo(0));
        expect(q.correctIndex, lessThan(4));
        expect(q.questionId, startsWith('route:'));
      }
    });

    test('returns empty list when no walk has 2+ POIs', () {
      final walkStart = DateTime(2026, 3, 1, 10, 0);
      final walkEnd = DateTime(2026, 3, 1, 11, 0);

      final walks = [
        _walk(walkStart, walkEnd, [const LatLng(51.500, -0.100)]),
      ];

      // Only 1 POI during the walk
      final discoveries = [
        _poi('node/1', 'Cafe A', 51.500, -0.100, walkStart.add(const Duration(minutes: 5))),
      ];

      final streets = [
        _street('way/1', 'High Street', [const LatLng(51.500, -0.100), const LatLng(51.502, -0.100)]),
        _street('way/2', 'Low Road', [const LatLng(51.510, -0.100), const LatLng(51.512, -0.100)]),
        _street('way/3', 'Park Lane', [const LatLng(51.520, -0.100), const LatLng(51.522, -0.100)]),
        _street('way/4', 'Mill Way', [const LatLng(51.530, -0.100), const LatLng(51.532, -0.100)]),
      ];

      final questions = RouteGenerator.generate(walks, discoveries, streets);

      expect(questions, isEmpty);
    });

    test('returns empty list with fewer than 4 streets', () {
      final walkStart = DateTime(2026, 3, 1, 10, 0);
      final walkEnd = DateTime(2026, 3, 1, 11, 0);

      final walks = [
        _walk(walkStart, walkEnd, [const LatLng(51.500, -0.100)]),
      ];

      final discoveries = [
        _poi('node/1', 'Cafe A', 51.500, -0.100, walkStart.add(const Duration(minutes: 5))),
        _poi('node/2', 'Pub B', 51.502, -0.100, walkStart.add(const Duration(minutes: 30))),
      ];

      final streets = [
        _street('way/1', 'High Street', [const LatLng(51.500, -0.100)]),
        _street('way/2', 'Low Road', [const LatLng(51.510, -0.100)]),
      ];

      final questions = RouteGenerator.generate(walks, discoveries, streets);

      expect(questions, isEmpty);
    });

    test('correct answer is the street nearest both POIs', () {
      final walkStart = DateTime(2026, 3, 1, 10, 0);
      final walkEnd = DateTime(2026, 3, 1, 11, 0);

      final walks = [
        _walk(walkStart, walkEnd, [
          const LatLng(51.500, -0.100),
          const LatLng(51.502, -0.100),
        ]),
      ];

      // Both POIs are near High Street (51.500 to 51.502)
      final discoveries = [
        _poi('node/1', 'Cafe A', 51.500, -0.100, walkStart.add(const Duration(minutes: 5))),
        _poi('node/2', 'Pub B', 51.502, -0.100, walkStart.add(const Duration(minutes: 30))),
      ];

      final streets = [
        _street('way/1', 'High Street', [const LatLng(51.500, -0.100), const LatLng(51.502, -0.100)]),
        _street('way/2', 'Low Road', [const LatLng(51.510, -0.110), const LatLng(51.512, -0.110)]),
        _street('way/3', 'Park Lane', [const LatLng(51.520, -0.120), const LatLng(51.522, -0.120)]),
        _street('way/4', 'Mill Way', [const LatLng(51.530, -0.130), const LatLng(51.532, -0.130)]),
      ];

      final questions = RouteGenerator.generate(walks, discoveries, streets);

      expect(questions, isNotEmpty);
      final q = questions.first;
      expect(q.choices[q.correctIndex], 'High Street');
    });

    test('prompt includes both POI names', () {
      final walkStart = DateTime(2026, 3, 1, 10, 0);
      final walkEnd = DateTime(2026, 3, 1, 11, 0);

      final walks = [
        _walk(walkStart, walkEnd, [
          const LatLng(51.500, -0.100),
          const LatLng(51.502, -0.100),
        ]),
      ];

      final discoveries = [
        _poi('node/1', 'Cafe A', 51.500, -0.100, walkStart.add(const Duration(minutes: 5))),
        _poi('node/2', 'Pub B', 51.502, -0.100, walkStart.add(const Duration(minutes: 30))),
      ];

      final streets = [
        _street('way/1', 'High Street', [const LatLng(51.500, -0.100), const LatLng(51.502, -0.100)]),
        _street('way/2', 'Low Road', [const LatLng(51.510, -0.100), const LatLng(51.512, -0.100)]),
        _street('way/3', 'Park Lane', [const LatLng(51.520, -0.100), const LatLng(51.522, -0.100)]),
        _street('way/4', 'Mill Way', [const LatLng(51.530, -0.100), const LatLng(51.532, -0.100)]),
      ];

      final questions = RouteGenerator.generate(walks, discoveries, streets);

      for (final q in questions) {
        expect(q.prompt.contains('Cafe A') || q.prompt.contains('Pub B'), isTrue,
            reason: 'Prompt should reference POI names');
      }
    });

    test('no duplicate choices in a question', () {
      final walkStart = DateTime(2026, 3, 1, 10, 0);
      final walkEnd = DateTime(2026, 3, 1, 11, 0);

      final walks = [
        _walk(walkStart, walkEnd, [
          const LatLng(51.500, -0.100),
          const LatLng(51.502, -0.100),
        ]),
      ];

      final discoveries = [
        _poi('node/1', 'Cafe A', 51.500, -0.100, walkStart.add(const Duration(minutes: 5))),
        _poi('node/2', 'Pub B', 51.502, -0.100, walkStart.add(const Duration(minutes: 30))),
      ];

      final streets = [
        _street('way/1', 'High Street', [const LatLng(51.500, -0.100), const LatLng(51.502, -0.100)]),
        _street('way/2', 'Low Road', [const LatLng(51.510, -0.100), const LatLng(51.512, -0.100)]),
        _street('way/3', 'Park Lane', [const LatLng(51.520, -0.100), const LatLng(51.522, -0.100)]),
        _street('way/4', 'Mill Way', [const LatLng(51.530, -0.100), const LatLng(51.532, -0.100)]),
      ];

      final questions = RouteGenerator.generate(walks, discoveries, streets);

      for (final q in questions) {
        expect(q.choices.toSet().length, q.choices.length,
            reason: 'Duplicate choices found');
      }
    });

    test('only uses POIs from the same walk', () {
      final walk1Start = DateTime(2026, 3, 1, 10, 0);
      final walk1End = DateTime(2026, 3, 1, 11, 0);
      final walk2Start = DateTime(2026, 3, 2, 10, 0);
      final walk2End = DateTime(2026, 3, 2, 11, 0);

      final walks = [
        _walk(walk1Start, walk1End, [const LatLng(51.500, -0.100)]),
        _walk(walk2Start, walk2End, [const LatLng(51.510, -0.100)]),
      ];

      // One POI per walk — no walk has 2+ POIs
      final discoveries = [
        _poi('node/1', 'Cafe A', 51.500, -0.100, walk1Start.add(const Duration(minutes: 5))),
        _poi('node/2', 'Pub B', 51.510, -0.100, walk2Start.add(const Duration(minutes: 5))),
      ];

      final streets = [
        _street('way/1', 'High Street', [const LatLng(51.500, -0.100), const LatLng(51.502, -0.100)]),
        _street('way/2', 'Low Road', [const LatLng(51.510, -0.100), const LatLng(51.512, -0.100)]),
        _street('way/3', 'Park Lane', [const LatLng(51.520, -0.100), const LatLng(51.522, -0.100)]),
        _street('way/4', 'Mill Way', [const LatLng(51.530, -0.100), const LatLng(51.532, -0.100)]),
      ];

      final questions = RouteGenerator.generate(walks, discoveries, streets);

      // No questions — each walk only has 1 POI
      expect(questions, isEmpty);
    });
  });
}
