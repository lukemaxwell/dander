import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/zone/zone.dart';

void main() {
  final now = DateTime(2026, 3, 13, 12, 0);
  final centre = LatLng(51.5074, -0.1278);

  Zone makeZone({int xp = 0, String name = 'Hackney'}) => Zone(
        id: 'zone_1',
        name: name,
        centre: centre,
        createdAt: now,
        xp: xp,
      );

  group('Zone', () {
    group('construction', () {
      test('creates with default 0 XP', () {
        final zone = makeZone();
        expect(zone.id, 'zone_1');
        expect(zone.name, 'Hackney');
        expect(zone.centre, centre);
        expect(zone.xp, 0);
        expect(zone.createdAt, now);
      });

      test('creates with specified XP', () {
        final zone = makeZone(xp: 150);
        expect(zone.xp, 150);
      });
    });

    group('computed properties', () {
      test('level is 1 at 0 XP', () {
        expect(makeZone(xp: 0).level, 1);
      });

      test('level is 2 at 100 XP', () {
        expect(makeZone(xp: 100).level, 2);
      });

      test('radiusMeters is 500 at L1', () {
        expect(makeZone(xp: 0).radiusMeters, 500.0);
      });

      test('radiusMeters is 1500 at L2', () {
        expect(makeZone(xp: 100).radiusMeters, 1500.0);
      });

      test('xpForNextLevel is 100 at L1', () {
        expect(makeZone(xp: 0).xpForNextLevel, 100);
      });

      test('xpForNextLevel is null at max level', () {
        expect(makeZone(xp: 1500).xpForNextLevel, isNull);
      });
    });

    group('addXp', () {
      test('returns new Zone with added XP', () {
        final zone = makeZone(xp: 50);
        final updated = zone.addXp(30);
        expect(updated.xp, 80);
        expect(zone.xp, 50); // original unchanged
      });

      test('does not allow negative amounts', () {
        final zone = makeZone(xp: 50);
        expect(() => zone.addXp(-10), throwsArgumentError);
      });

      test('preserves other fields', () {
        final zone = makeZone(xp: 50);
        final updated = zone.addXp(30);
        expect(updated.id, zone.id);
        expect(updated.name, zone.name);
        expect(updated.centre, zone.centre);
        expect(updated.createdAt, zone.createdAt);
      });
    });

    group('rename', () {
      test('returns new Zone with updated name', () {
        final zone = makeZone();
        final updated = zone.rename('Shoreditch');
        expect(updated.name, 'Shoreditch');
        expect(zone.name, 'Hackney'); // original unchanged
      });

      test('preserves other fields', () {
        final zone = makeZone(xp: 200);
        final updated = zone.rename('Shoreditch');
        expect(updated.xp, 200);
        expect(updated.id, zone.id);
      });
    });

    group('copyWith', () {
      test('returns identical copy when no overrides', () {
        final zone = makeZone(xp: 100);
        final copy = zone.copyWith();
        expect(copy.id, zone.id);
        expect(copy.name, zone.name);
        expect(copy.xp, zone.xp);
        expect(copy.centre, zone.centre);
        expect(copy.createdAt, zone.createdAt);
      });

      test('overrides specified fields', () {
        final zone = makeZone();
        final copy = zone.copyWith(name: 'Dalston', xp: 999);
        expect(copy.name, 'Dalston');
        expect(copy.xp, 999);
        expect(copy.id, zone.id);
      });
    });

    group('JSON serialisation', () {
      test('round-trips through toJson/fromJson', () {
        final zone = makeZone(xp: 250);
        final json = zone.toJson();
        final restored = Zone.fromJson(json);
        expect(restored.id, zone.id);
        expect(restored.name, zone.name);
        expect(restored.centre.latitude, zone.centre.latitude);
        expect(restored.centre.longitude, zone.centre.longitude);
        expect(restored.xp, zone.xp);
        expect(restored.createdAt, zone.createdAt);
      });

      test('toJson contains expected keys', () {
        final json = makeZone(xp: 100).toJson();
        expect(json, containsPair('id', 'zone_1'));
        expect(json, containsPair('name', 'Hackney'));
        expect(json, containsPair('xp', 100));
        expect(json, contains('centreLat'));
        expect(json, contains('centreLng'));
        expect(json, contains('createdAt'));
      });
    });
  });
}
