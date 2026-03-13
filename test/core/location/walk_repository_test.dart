import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dander/core/location/walk_repository.dart';
import 'package:dander/core/location/walk_session.dart';

class MockBox extends Mock implements Box<dynamic> {}

void main() {
  const p0 = LatLng(51.5000, -0.1000);
  const p1 = LatLng(51.5009, -0.1000);

  final t0 = DateTime(2024, 6, 1, 9, 0, 0);
  final t1 = DateTime(2024, 6, 1, 9, 0, 5);
  final endTime = DateTime(2024, 6, 1, 9, 30, 0);

  WalkSession buildSession({String id = 'walk-001'}) =>
      WalkSession.start(id: id, startTime: t0)
          .addPoint(WalkPoint(position: p0, timestamp: t0))
          .addPoint(WalkPoint(position: p1, timestamp: t1))
          .completeAt(endTime);

  // Produce the same JSON string that HiveWalkRepository writes to Hive.
  String encodeSession(WalkSession session) => jsonEncode(session.toJson());

  group('HiveWalkRepository', () {
    late MockBox mockBox;
    late HiveWalkRepository repository;

    setUp(() {
      mockBox = MockBox();
      repository = HiveWalkRepository.withBox(mockBox);
    });

    group('saveWalk', () {
      test('stores JSON-encoded walk under the walk id key', () async {
        final session = buildSession();
        when(() => mockBox.get('__index__')).thenReturn(null);
        when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

        await repository.saveWalk(session);

        verify(() => mockBox.put(session.id, any())).called(1);
      });

      test('also stores the id in the index list', () async {
        final session = buildSession();
        when(() => mockBox.get('__index__')).thenReturn(null);
        when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

        await repository.saveWalk(session);

        verify(() => mockBox.put('__index__', any())).called(1);
      });

      test('saves multiple walks and each gets its own key', () async {
        final s1 = buildSession(id: 'walk-001');
        final s2 = buildSession(id: 'walk-002');

        // First call: index is empty. Second call: index has walk-001.
        var indexCallCount = 0;
        when(() => mockBox.get('__index__')).thenAnswer((_) {
          indexCallCount++;
          return indexCallCount == 1 ? null : '["walk-001"]';
        });
        when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

        await repository.saveWalk(s1);
        await repository.saveWalk(s2);

        verify(() => mockBox.put('walk-001', any())).called(1);
        verify(() => mockBox.put('walk-002', any())).called(1);
      });
    });

    group('getWalk', () {
      test('returns null for unknown id', () async {
        when(() => mockBox.get('nonexistent')).thenReturn(null);

        final result = await repository.getWalk('nonexistent');
        expect(result, isNull);
      });

      test('returns restored WalkSession for known id', () async {
        final session = buildSession();
        when(() => mockBox.get(session.id)).thenReturn(encodeSession(session));

        final result = await repository.getWalk(session.id);
        expect(result, isNotNull);
        expect(result!.id, equals(session.id));
        expect(result.pointCount, equals(session.pointCount));
      });

      test('restores distance correctly after round-trip', () async {
        final session = buildSession();
        when(() => mockBox.get(session.id)).thenReturn(encodeSession(session));

        final result = await repository.getWalk(session.id);
        expect(
          result!.distanceMeters,
          closeTo(session.distanceMeters, 0.001),
        );
      });
    });

    group('getWalks', () {
      test('returns empty list when no walks stored', () async {
        when(() => mockBox.get('__index__')).thenReturn(null);

        final result = await repository.getWalks();
        expect(result, isEmpty);
      });

      test('returns all stored walks', () async {
        final s1 = buildSession(id: 'walk-001');
        final s2 = buildSession(id: 'walk-002');

        when(() => mockBox.get('__index__'))
            .thenReturn('["walk-001","walk-002"]');
        when(() => mockBox.get('walk-001')).thenReturn(encodeSession(s1));
        when(() => mockBox.get('walk-002')).thenReturn(encodeSession(s2));

        final result = await repository.getWalks();
        expect(result.length, equals(2));
        expect(result.map((s) => s.id).toSet(),
            containsAll(['walk-001', 'walk-002']));
      });

      test('skips entries that fail to decode (graceful degradation)',
          () async {
        when(() => mockBox.get('__index__'))
            .thenReturn('["walk-001","walk-corrupted"]');
        when(() => mockBox.get('walk-001'))
            .thenReturn(encodeSession(buildSession(id: 'walk-001')));
        when(() => mockBox.get('walk-corrupted'))
            .thenReturn('NOT_VALID_JSON{{{');

        final result = await repository.getWalks();
        expect(result.length, equals(1));
        expect(result.first.id, equals('walk-001'));
      });
    });
  });
}
