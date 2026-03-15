import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/debug/fixtures/active_zone_fixture.dart';
import 'package:dander/core/zone/mystery_poi.dart';

void main() {
  group('ActiveZoneFixture', () {
    const fixture = ActiveZoneFixture();

    test('has correct name', () {
      expect(fixture.name, equals('active_zone'));
    });

    test('suppresses onboarding', () {
      expect(fixture.suppressOnboarding, isTrue);
    });

    test('has a seed position in Greenwich area', () {
      expect(fixture.seedPosition, isNotNull);
      expect(fixture.seedPosition!.latitude, closeTo(51.4769, 0.01));
    });

    test('has walked paths for fog seeding', () {
      expect(fixture.walkedPaths, isNotEmpty);
      expect(fixture.walkedPaths.first.length, greaterThan(1));
    });

    group('zone data', () {
      test('provides a zone centred in Greenwich area', () {
        final zone = ActiveZoneFixture.zone;
        expect(zone.centre.latitude, closeTo(51.4769, 0.01));
        expect(zone.name, isNotEmpty);
        expect(zone.xp, greaterThan(0));
      });
    });

    group('mystery POIs', () {
      test('provides at least 5 mystery POIs', () {
        final pois = ActiveZoneFixture.mysteryPois;
        expect(pois.length, greaterThanOrEqualTo(5));
      });

      test('has at least 3 hinted POIs (visible as ? markers)', () {
        final hinted = ActiveZoneFixture.mysteryPois
            .where((p) => p.state == PoiState.hinted)
            .toList();
        expect(hinted.length, greaterThanOrEqualTo(3));
      });

      test('has at least 2 revealed POIs with names', () {
        final revealed = ActiveZoneFixture.mysteryPois
            .where((p) => p.state == PoiState.revealed)
            .toList();
        expect(revealed.length, greaterThanOrEqualTo(2));
        for (final poi in revealed) {
          expect(poi.name, isNotNull);
          expect(poi.name, isNotEmpty);
        }
      });

      test('all POIs are in Greenwich area', () {
        for (final poi in ActiveZoneFixture.mysteryPois) {
          expect(poi.position.latitude, closeTo(51.477, 0.01));
        }
      });
    });

    group('discoveries', () {
      test('has Discovery entries matching revealed POIs', () {
        final revealed = ActiveZoneFixture.mysteryPois
            .where((p) => p.state == PoiState.revealed)
            .toList();
        expect(
          ActiveZoneFixture.discoveries.length,
          equals(revealed.length),
        );
        for (final discovery in ActiveZoneFixture.discoveries) {
          expect(discovery.discoveredAt, isNotNull);
          expect(discovery.name, isNotEmpty);
        }
      });
    });

    group('walk session', () {
      test('provides a completed walk session', () {
        final walk = ActiveZoneFixture.walkSession;
        expect(walk.endTime, isNotNull);
        expect(walk.pointCount, greaterThan(0));
      });

      test('walk points are in Greenwich area', () {
        for (final point in ActiveZoneFixture.walkSession.points) {
          expect(point.position.latitude, closeTo(51.477, 0.01));
        }
      });
    });
  });
}
