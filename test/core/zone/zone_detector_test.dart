import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/zone/zone.dart';
import 'package:dander/core/zone/zone_detector.dart';

void main() {
  final now = DateTime(2026, 3, 13, 12, 0);

  Zone makeZone({
    required String id,
    required LatLng centre,
    String name = 'Test Zone',
  }) =>
      Zone(
        id: id,
        name: name,
        centre: centre,
        createdAt: now,
      );

  // Well-known city coordinates used for distance assertions.
  // London (St Paul's): 51.5138° N, -0.0984° W
  const london = LatLng(51.5138, -0.0984);
  // Paris (Notre-Dame): 48.8530° N, 2.3499° E  (~340 km from London)
  const paris = LatLng(48.8530, 2.3499);
  // Birmingham: 52.4862° N, -1.8904° W  (~163 km from London)
  const birmingham = LatLng(52.4862, -1.8904);
  // A point 1 km north of London (same longitude, +0.009° lat ≈ 1 000 m)
  const londonNearby = LatLng(51.5228, -0.0984);

  group('ZoneDetector', () {
    late ZoneDetector detector;

    setUp(() {
      detector = ZoneDetector();
    });

    // -------------------------------------------------------------------------
    // distanceBetween
    // -------------------------------------------------------------------------

    group('distanceBetween', () {
      test('returns 0 for identical points', () {
        final dist = detector.distanceBetween(london, london);
        expect(dist, closeTo(0.0, 1.0));
      });

      test('London to Paris is approximately 343 km', () {
        final dist = detector.distanceBetween(london, paris);
        // Actual great-circle distance between these coordinates ≈ 343 357 m.
        // Allow ±2 000 m tolerance to account for floating-point variation.
        expect(dist, closeTo(343357.0, 2000.0));
      });

      test('London to Birmingham is approximately 163 km', () {
        final dist = detector.distanceBetween(london, birmingham);
        expect(dist, closeTo(163000.0, 2000.0));
      });

      test('is symmetric — A→B equals B→A', () {
        final ab = detector.distanceBetween(london, paris);
        final ba = detector.distanceBetween(paris, london);
        expect(ab, closeTo(ba, 0.01));
      });

      test('returns distance in metres, not kilometres', () {
        // London to nearby point ≈ 1 000 m, not ≈ 1
        final dist = detector.distanceBetween(london, londonNearby);
        expect(dist, greaterThan(500.0));
        expect(dist, lessThan(2000.0));
      });
    });

    // -------------------------------------------------------------------------
    // detectNewZone
    // -------------------------------------------------------------------------

    group('detectNewZone', () {
      test('returns true when there are no existing zones', () {
        final result = detector.detectNewZone(london, []);
        expect(result, isTrue);
      });

      test('returns true when position is >50 km from all zone centres', () {
        // Paris zone is ~340 km from London — well beyond the threshold.
        final zones = [makeZone(id: 'z1', centre: paris)];
        final result = detector.detectNewZone(london, zones);
        expect(result, isTrue);
      });

      test('returns false when position is within 50 km of a zone', () {
        // londonNearby is ~1 km from London — well within threshold.
        final zones = [makeZone(id: 'z1', centre: london)];
        final result = detector.detectNewZone(londonNearby, zones);
        expect(result, isFalse);
      });

      test('returns false when position is exactly at a zone centre', () {
        final zones = [makeZone(id: 'z1', centre: london)];
        final result = detector.detectNewZone(london, zones);
        expect(result, isFalse);
      });

      test(
          'returns false when at least one zone is within threshold '
          'even if others are not', () {
        // Two zones: one in London (near), one in Paris (far).
        final zones = [
          makeZone(id: 'z1', centre: london),
          makeZone(id: 'z2', centre: paris),
        ];
        // londonNearby is <50 km from London zone, so result must be false.
        final result = detector.detectNewZone(londonNearby, zones);
        expect(result, isFalse);
      });

      test('returns true when all zones are beyond 50 km', () {
        // Birmingham (~163 km) and Paris (~340 km) are both beyond threshold.
        final zones = [
          makeZone(id: 'z1', centre: birmingham),
          makeZone(id: 'z2', centre: paris),
        ];
        final result = detector.detectNewZone(london, zones);
        expect(result, isTrue);
      });

      test('uses newZoneThresholdMeters constant for the boundary check', () {
        expect(ZoneDetector.newZoneThresholdMeters, equals(50000.0));
      });
    });

    // -------------------------------------------------------------------------
    // findActiveZone
    // -------------------------------------------------------------------------

    group('findActiveZone', () {
      test('returns null when zone list is empty', () {
        final result = detector.findActiveZone(london, []);
        expect(result, isNull);
      });

      test('returns the sole zone when only one zone exists', () {
        final zone = makeZone(id: 'z1', centre: london);
        final result = detector.findActiveZone(london, [zone]);
        expect(result, equals(zone));
      });

      test('returns the closest zone to the current position', () {
        // London zone is ~1 km from londonNearby; Paris zone is ~340 km.
        final londonZone = makeZone(id: 'z1', centre: london);
        final parisZone = makeZone(id: 'z2', centre: paris);
        final result = detector.findActiveZone(londonNearby, [londonZone, parisZone]);
        expect(result, equals(londonZone));
      });

      test('returns the closest zone regardless of list order', () {
        // Same as above but Paris listed first.
        final londonZone = makeZone(id: 'z1', centre: london);
        final parisZone = makeZone(id: 'z2', centre: paris);
        final result = detector.findActiveZone(londonNearby, [parisZone, londonZone]);
        expect(result, equals(londonZone));
      });

      test('distinguishes correctly between two nearby zones', () {
        // Birmingham is ~163 km from London; Paris is ~340 km.
        // Position at London should resolve to Birmingham as closer.
        final birminghamZone = makeZone(id: 'z1', centre: birmingham);
        final parisZone = makeZone(id: 'z2', centre: paris);
        final result = detector.findActiveZone(london, [birminghamZone, parisZone]);
        expect(result, equals(birminghamZone));
      });

      test('does not mutate the input list', () {
        final zones = [
          makeZone(id: 'z1', centre: london),
          makeZone(id: 'z2', centre: paris),
        ];
        final originalLength = zones.length;
        final originalFirst = zones.first;
        detector.findActiveZone(london, zones);
        expect(zones.length, equals(originalLength));
        expect(zones.first, equals(originalFirst));
      });
    });
  });
}
