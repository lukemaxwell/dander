import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:dander/core/location/walk_session.dart';

void main() {
  final t0 = DateTime(2024, 6, 1, 9, 0, 0);
  final t1 = DateTime(2024, 6, 1, 9, 0, 5);
  final t2 = DateTime(2024, 6, 1, 9, 0, 10);

  const p0 = LatLng(51.5000, -0.1000);
  const p1 = LatLng(51.5009, -0.1000); // ~100 m north
  const p2 = LatLng(51.5009, -0.1009); // ~100 m west of p1

  WalkPoint makePoint(LatLng pos, DateTime ts) =>
      WalkPoint(position: pos, timestamp: ts);

  WalkSession makeSession() => WalkSession.start(id: 'test-id', startTime: t0);

  group('WalkPoint', () {
    test('stores position and timestamp', () {
      final point = makePoint(p0, t0);
      expect(point.position, equals(p0));
      expect(point.timestamp, equals(t0));
    });

    test('two points with same values are equal', () {
      final a = makePoint(p0, t0);
      final b = makePoint(p0, t0);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('two points with different values are not equal', () {
      final a = makePoint(p0, t0);
      final b = makePoint(p1, t0);
      expect(a, isNot(equals(b)));
    });
  });

  group('WalkSession.start', () {
    test('creates session with given id and startTime', () {
      final session = makeSession();
      expect(session.id, equals('test-id'));
      expect(session.startTime, equals(t0));
    });

    test('starts with no points', () {
      final session = makeSession();
      expect(session.points, isEmpty);
      expect(session.pointCount, equals(0));
    });

    test('starts with null endTime', () {
      final session = makeSession();
      expect(session.endTime, isNull);
    });

    test('starts with zero distance', () {
      final session = makeSession();
      expect(session.distanceMeters, equals(0.0));
    });
  });

  group('WalkSession.addPoint (immutability)', () {
    test('returns a new session instance — does not mutate original', () {
      final original = makeSession();
      final updated = original.addPoint(makePoint(p0, t0));
      expect(identical(original, updated), isFalse);
    });

    test('original session has 0 points after addPoint', () {
      final original = makeSession();
      original.addPoint(makePoint(p0, t0));
      expect(original.pointCount, equals(0));
    });

    test('new session has 1 point after addPoint', () {
      final session = makeSession().addPoint(makePoint(p0, t0));
      expect(session.pointCount, equals(1));
    });

    test('chaining addPoint builds up point list immutably', () {
      final session = makeSession()
          .addPoint(makePoint(p0, t0))
          .addPoint(makePoint(p1, t1))
          .addPoint(makePoint(p2, t2));
      expect(session.pointCount, equals(3));
    });

    test('points list returned from session is unmodifiable', () {
      final session = makeSession().addPoint(makePoint(p0, t0));
      expect(
        () => (session.points as List).add(makePoint(p1, t1)),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('preserves all fields except points when adding a point', () {
      final original = makeSession();
      final updated = original.addPoint(makePoint(p0, t0));
      expect(updated.id, equals(original.id));
      expect(updated.startTime, equals(original.startTime));
      expect(updated.endTime, isNull);
    });
  });

  group('WalkSession.complete (immutability)', () {
    test('returns a new instance', () {
      final session = makeSession();
      final completed = session.complete();
      expect(identical(session, completed), isFalse);
    });

    test('completed session has non-null endTime', () {
      final session = makeSession().complete();
      expect(session.endTime, isNotNull);
    });

    test('original session endTime remains null after complete', () {
      final session = makeSession();
      session.complete();
      expect(session.endTime, isNull);
    });

    test('endTime is >= startTime', () {
      final session = makeSession().complete();
      expect(
        session.endTime!.isAfter(session.startTime) ||
            session.endTime == session.startTime,
        isTrue,
      );
    });

    test('complete preserves points', () {
      final session = makeSession()
          .addPoint(makePoint(p0, t0))
          .addPoint(makePoint(p1, t1))
          .complete();
      expect(session.pointCount, equals(2));
    });

    test('complete with explicit endTime stores that time', () {
      final endTime = DateTime(2024, 6, 1, 10, 0, 0);
      final session = makeSession().completeAt(endTime);
      expect(session.endTime, equals(endTime));
    });
  });

  group('WalkSession.duration', () {
    test('returns zero duration when no endTime', () {
      final session = makeSession();
      // Without endTime, duration is elapsed from startTime to now — at minimum 0
      expect(session.duration.inSeconds, greaterThanOrEqualTo(0));
    });

    test('returns exact duration when endTime is set', () {
      final start = DateTime(2024, 6, 1, 9, 0, 0);
      final end = DateTime(2024, 6, 1, 9, 30, 0);
      final session =
          WalkSession.start(id: 'id', startTime: start).completeAt(end);
      expect(session.duration, equals(const Duration(minutes: 30)));
    });

    test('handles sub-second precision', () {
      final start = DateTime(2024, 6, 1, 9, 0, 0, 0);
      final end = DateTime(2024, 6, 1, 9, 0, 0, 500);
      final session =
          WalkSession.start(id: 'id', startTime: start).completeAt(end);
      expect(session.duration.inMilliseconds, equals(500));
    });
  });

  group('WalkSession.distanceMeters', () {
    test('is 0.0 with no points', () {
      expect(makeSession().distanceMeters, equals(0.0));
    });

    test('is 0.0 with a single point', () {
      final session = makeSession().addPoint(makePoint(p0, t0));
      expect(session.distanceMeters, equals(0.0));
    });

    test('calculates distance between two points correctly', () {
      final session =
          makeSession().addPoint(makePoint(p0, t0)).addPoint(makePoint(p1, t1));
      // p0 to p1 is ~100 m
      expect(session.distanceMeters, closeTo(100.0, 5.0));
    });

    test('accumulates distance over multiple points', () {
      final session = makeSession()
          .addPoint(makePoint(p0, t0))
          .addPoint(makePoint(p1, t1))
          .addPoint(makePoint(p2, t2));
      // p0→p1 ≈ 100 m north, p1→p2 ≈ 62 m west (longitude shrinks with lat)
      // Total is approximately 162 m; use a wide-enough tolerance.
      expect(session.distanceMeters, closeTo(162.0, 15.0));
    });

    test('distance is non-negative', () {
      final session =
          makeSession().addPoint(makePoint(p1, t0)).addPoint(makePoint(p0, t1));
      expect(session.distanceMeters, greaterThanOrEqualTo(0.0));
    });
  });

  group('WalkSession serialisation (toJson / fromJson)', () {
    test('round-trips an empty session', () {
      final session = makeSession();
      final json = session.toJson();
      final restored = WalkSession.fromJson(json);
      expect(restored.id, equals(session.id));
      expect(restored.startTime, equals(session.startTime));
      expect(restored.endTime, isNull);
      expect(restored.pointCount, equals(0));
    });

    test('round-trips a session with points and endTime', () {
      final endTime = DateTime(2024, 6, 1, 10, 0, 0);
      final session = makeSession()
          .addPoint(makePoint(p0, t0))
          .addPoint(makePoint(p1, t1))
          .completeAt(endTime);

      final json = session.toJson();
      final restored = WalkSession.fromJson(json);

      expect(restored.id, equals(session.id));
      expect(restored.startTime, equals(session.startTime));
      expect(restored.endTime, equals(endTime));
      expect(restored.pointCount, equals(2));
      expect(
          restored.points[0].position.latitude, closeTo(p0.latitude, 0.000001));
      expect(
          restored.points[1].position.latitude, closeTo(p1.latitude, 0.000001));
    });

    test('toJson produces a Map<String, dynamic>', () {
      final json = makeSession().toJson();
      expect(json, isA<Map<String, dynamic>>());
    });

    test('fromJson handles missing endTime field gracefully', () {
      final json = makeSession().toJson()..remove('endTime');
      final restored = WalkSession.fromJson(json);
      expect(restored.endTime, isNull);
    });
  });
}
