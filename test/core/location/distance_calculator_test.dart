import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:dander/core/location/distance_calculator.dart' as dc;
import 'package:dander/core/location/walk_session.dart';

// ignore: avoid_renaming_method_parameters
// We alias DistanceCalculator via the import prefix `dc` to avoid the name
// collision with latlong2's own DistanceCalculator export.
void main() {
  group('DistanceCalculator', () {
    group('haversine', () {
      test('returns 0 for identical points', () {
        const a = LatLng(51.5, -0.1);
        final result = dc.DistanceCalculator.haversine(a, a);
        expect(result, equals(0.0));
      });

      test('calculates known distance: London to Paris ~340 km', () {
        const london = LatLng(51.5074, -0.1278);
        const paris = LatLng(48.8566, 2.3522);
        final result = dc.DistanceCalculator.haversine(london, paris);
        // Known distance ~340 km — allow 5 km tolerance
        expect(result, closeTo(340000, 5000));
      });

      test('calculates short distance accurately: ~100 m north', () {
        // Moving ~100 m north: 1 degree lat ~111 111 m, so 100 m ~0.0009 deg
        const a = LatLng(51.5000, -0.1000);
        const b = LatLng(51.5009, -0.1000);
        final result = dc.DistanceCalculator.haversine(a, b);
        expect(result, closeTo(100.0, 5.0));
      });

      test('is symmetric: haversine(a, b) == haversine(b, a)', () {
        const a = LatLng(48.8566, 2.3522);
        const b = LatLng(40.7128, -74.0060);
        expect(
          dc.DistanceCalculator.haversine(a, b),
          closeTo(dc.DistanceCalculator.haversine(b, a), 0.001),
        );
      });

      test('handles points on the equator correctly', () {
        // 1 degree longitude at equator ~111 195 m
        const a = LatLng(0.0, 0.0);
        const b = LatLng(0.0, 1.0);
        final result = dc.DistanceCalculator.haversine(a, b);
        expect(result, closeTo(111195, 200));
      });

      test('handles negative coordinates', () {
        const a = LatLng(-33.8688, 151.2093); // Sydney
        const b = LatLng(-37.8136, 144.9631); // Melbourne
        final result = dc.DistanceCalculator.haversine(a, b);
        // Known distance ~714 km — allow 5 km tolerance
        expect(result, closeTo(714000, 5000));
      });

      test('handles antipodal points (max possible distance ~20 015 km)', () {
        const a = LatLng(0.0, 0.0);
        const b = LatLng(0.0, 180.0);
        final result = dc.DistanceCalculator.haversine(a, b);
        expect(result, closeTo(20015087, 1000));
      });

      test('handles points at poles', () {
        const northPole = LatLng(90.0, 0.0);
        const equator = LatLng(0.0, 0.0);
        final result = dc.DistanceCalculator.haversine(northPole, equator);
        // Quarter circumference ~10 007 543 m
        expect(result, closeTo(10007543, 1000));
      });
    });

    group('totalDistance', () {
      test('returns 0.0 for empty list', () {
        expect(dc.DistanceCalculator.totalDistance([]), equals(0.0));
      });

      test('returns 0.0 for a single point', () {
        final points = [
          WalkPoint(
            position: const LatLng(51.5, -0.1),
            timestamp: DateTime(2024, 1, 1, 10, 0),
          ),
        ];
        expect(dc.DistanceCalculator.totalDistance(points), equals(0.0));
      });

      test('sums segment distances for two points', () {
        const a = LatLng(51.5000, -0.1000);
        const b = LatLng(51.5009, -0.1000);
        final points = [
          WalkPoint(position: a, timestamp: DateTime(2024, 1, 1, 10, 0)),
          WalkPoint(position: b, timestamp: DateTime(2024, 1, 1, 10, 1)),
        ];
        final result = dc.DistanceCalculator.totalDistance(points);
        final expected = dc.DistanceCalculator.haversine(a, b);
        expect(result, closeTo(expected, 0.001));
      });

      test('sums all segments for three points', () {
        const a = LatLng(51.5000, -0.1000);
        const b = LatLng(51.5009, -0.1000);
        const c = LatLng(51.5009, -0.1009);
        final points = [
          WalkPoint(position: a, timestamp: DateTime(2024, 1, 1, 10, 0)),
          WalkPoint(position: b, timestamp: DateTime(2024, 1, 1, 10, 1)),
          WalkPoint(position: c, timestamp: DateTime(2024, 1, 1, 10, 2)),
        ];
        final result = dc.DistanceCalculator.totalDistance(points);
        final expected = dc.DistanceCalculator.haversine(a, b) +
            dc.DistanceCalculator.haversine(b, c);
        expect(result, closeTo(expected, 0.001));
      });

      test('handles duplicate consecutive points (zero-length segments)', () {
        const a = LatLng(51.5, -0.1);
        final points = [
          WalkPoint(position: a, timestamp: DateTime(2024, 1, 1, 10, 0)),
          WalkPoint(position: a, timestamp: DateTime(2024, 1, 1, 10, 1)),
          WalkPoint(position: a, timestamp: DateTime(2024, 1, 1, 10, 2)),
        ];
        expect(dc.DistanceCalculator.totalDistance(points), equals(0.0));
      });

      test('accumulates over 1000 identical segments without overflow', () {
        const a = LatLng(51.5000, -0.1000);
        const b = LatLng(51.5009, -0.1000);
        final segDist = dc.DistanceCalculator.haversine(a, b);
        final points = <WalkPoint>[];
        for (var i = 0; i < 1001; i++) {
          final pos = i.isEven ? a : b;
          points.add(WalkPoint(
            position: pos,
            timestamp: DateTime(2024, 1, 1).add(Duration(seconds: i * 5)),
          ));
        }
        final result = dc.DistanceCalculator.totalDistance(points);
        // 1000 segments alternating a-b-a-... each segment ~segDist
        expect(result, closeTo(segDist * 1000, 0.1));
      });
    });

    group('metersToKilometers', () {
      test('converts 1000 m to 1.0 km', () {
        expect(dc.DistanceCalculator.metersToKilometers(1000.0), equals(1.0));
      });

      test('converts 0 m to 0.0 km', () {
        expect(dc.DistanceCalculator.metersToKilometers(0.0), equals(0.0));
      });

      test('converts 500 m to 0.5 km', () {
        expect(dc.DistanceCalculator.metersToKilometers(500.0), equals(0.5));
      });

      test('converts large distances correctly', () {
        expect(
          dc.DistanceCalculator.metersToKilometers(42195.0),
          closeTo(42.195, 0.0001),
        );
      });
    });
  });
}
