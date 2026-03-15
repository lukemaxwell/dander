import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/debug/fake_location_service.dart';

void main() {
  group('FakeLocationService', () {
    late FakeLocationService service;
    const greenwich = LatLng(51.4769, -0.0005);

    setUp(() {
      service = FakeLocationService(position: greenwich);
    });

    group('permissions', () {
      test('requestPermission always returns true', () async {
        expect(await service.requestPermission(), isTrue);
      });

      test('hasPermission always returns true', () async {
        expect(await service.hasPermission, isTrue);
      });
    });

    group('getCurrentPosition', () {
      test('returns a Position matching the configured LatLng', () async {
        final pos = await service.getCurrentPosition();
        expect(pos.latitude, equals(greenwich.latitude));
        expect(pos.longitude, equals(greenwich.longitude));
      });

      test('returns zero accuracy and speed values', () async {
        final pos = await service.getCurrentPosition();
        expect(pos.accuracy, equals(0.0));
        expect(pos.speed, equals(0.0));
        expect(pos.altitude, equals(0.0));
      });
    });

    group('positionStream', () {
      test('emits at least one Position with correct coordinates', () async {
        final pos = await service.positionStream.first;
        expect(pos.latitude, equals(greenwich.latitude));
        expect(pos.longitude, equals(greenwich.longitude));
      });

      test('is a broadcast stream (multiple listeners)', () {
        // Should not throw — broadcast streams allow multiple listens.
        service.positionStream.listen((_) {});
        service.positionStream.listen((_) {});
      });
    });

    group('custom position', () {
      test('uses different coordinates when configured', () async {
        final customService = FakeLocationService(
          position: const LatLng(40.7128, -74.0060),
        );
        final pos = await customService.getCurrentPosition();
        expect(pos.latitude, closeTo(40.7128, 0.001));
        expect(pos.longitude, closeTo(-74.0060, 0.001));
      });
    });
  });
}
