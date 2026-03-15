import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/zone/zone.dart';
import 'package:dander/features/sharing/presentation/widgets/turf_share_card_data.dart';

Zone _makeZone({
  String id = 'zone-1',
  String name = 'Hackney',
  int xp = 300,
}) {
  return Zone(
    id: id,
    name: name,
    centre: const LatLng(51.5, -0.08),
    xp: xp,
    createdAt: DateTime(2024, 1, 1),
  );
}

void main() {
  group('TurfShareCardData', () {
    group('direct construction', () {
      test('stores all fields correctly', () {
        const data = TurfShareCardData(
          zoneName: 'Hackney',
          level: 3,
          streetCount: 42,
          exploredCellCount: 150,
          exploredPct: 0.42,
        );

        expect(data.zoneName, equals('Hackney'));
        expect(data.level, equals(3));
        expect(data.streetCount, equals(42));
        expect(data.exploredCellCount, equals(150));
        expect(data.exploredPct, equals(0.42));
      });

      test('stores zero values without error', () {
        const data = TurfShareCardData(
          zoneName: 'Empty Zone',
          level: 1,
          streetCount: 0,
          exploredCellCount: 0,
          exploredPct: 0.0,
        );

        expect(data.streetCount, equals(0));
        expect(data.exploredCellCount, equals(0));
        expect(data.exploredPct, equals(0.0));
      });

      test('stores large values without error', () {
        const data = TurfShareCardData(
          zoneName: 'Mega Zone',
          level: 5,
          streetCount: 99999,
          exploredCellCount: 500000,
          exploredPct: 0.99,
        );

        expect(data.streetCount, equals(99999));
        expect(data.exploredCellCount, equals(500000));
        expect(data.exploredPct, equals(0.99));
      });

      test('stores special characters in zone name', () {
        const data = TurfShareCardData(
          zoneName: "O'Brien's & Co. \u2013 Caf\u00e9",
          level: 2,
          streetCount: 10,
          exploredCellCount: 50,
          exploredPct: 0.5,
        );

        expect(data.zoneName, equals("O'Brien's & Co. \u2013 Caf\u00e9"));
      });

      test('exploredPct stores 1.0 (fully explored)', () {
        const data = TurfShareCardData(
          zoneName: 'Full Zone',
          level: 5,
          streetCount: 100,
          exploredCellCount: 1000,
          exploredPct: 1.0,
        );

        expect(data.exploredPct, equals(1.0));
      });
    });

    group('fromZone factory', () {
      test('derives zone name from zone', () {
        final zone = _makeZone(name: 'Shoreditch');
        final data = TurfShareCardData.fromZone(
          zone,
          streetCount: 10,
          exploredCellCount: 80,
          exploredPct: 0.3,
        );

        expect(data.zoneName, equals('Shoreditch'));
      });

      test('derives level from zone xp — level 1 (0 xp)', () {
        final zone = _makeZone(xp: 0);
        final data = TurfShareCardData.fromZone(
          zone,
          streetCount: 5,
          exploredCellCount: 20,
          exploredPct: 0.1,
        );

        expect(data.level, equals(1));
      });

      test('derives level from zone xp — level 2 (100 xp)', () {
        final zone = _makeZone(xp: 100);
        final data = TurfShareCardData.fromZone(
          zone,
          streetCount: 5,
          exploredCellCount: 20,
          exploredPct: 0.2,
        );

        expect(data.level, equals(2));
      });

      test('derives level from zone xp — level 3 (300 xp)', () {
        final zone = _makeZone(xp: 300);
        final data = TurfShareCardData.fromZone(
          zone,
          streetCount: 5,
          exploredCellCount: 20,
          exploredPct: 0.3,
        );

        expect(data.level, equals(3));
      });

      test('derives level from zone xp — level 5 (1500 xp)', () {
        final zone = _makeZone(xp: 1500);
        final data = TurfShareCardData.fromZone(
          zone,
          streetCount: 5,
          exploredCellCount: 20,
          exploredPct: 0.5,
        );

        expect(data.level, equals(5));
      });

      test('passes through streetCount', () {
        final zone = _makeZone();
        final data = TurfShareCardData.fromZone(
          zone,
          streetCount: 77,
          exploredCellCount: 100,
          exploredPct: 0.5,
        );

        expect(data.streetCount, equals(77));
      });

      test('passes through exploredCellCount', () {
        final zone = _makeZone();
        final data = TurfShareCardData.fromZone(
          zone,
          streetCount: 10,
          exploredCellCount: 999,
          exploredPct: 0.6,
        );

        expect(data.exploredCellCount, equals(999));
      });

      test('passes through exploredPct', () {
        final zone = _makeZone();
        final data = TurfShareCardData.fromZone(
          zone,
          streetCount: 10,
          exploredCellCount: 100,
          exploredPct: 0.67,
        );

        expect(data.exploredPct, closeTo(0.67, 0.001));
      });

      test('zero streetCount is valid', () {
        final zone = _makeZone();
        final data = TurfShareCardData.fromZone(
          zone,
          streetCount: 0,
          exploredCellCount: 0,
          exploredPct: 0.0,
        );

        expect(data.streetCount, equals(0));
        expect(data.exploredCellCount, equals(0));
        expect(data.exploredPct, equals(0.0));
      });
    });

    group('immutability', () {
      test('two instances with same data are equal', () {
        const a = TurfShareCardData(
          zoneName: 'Hackney',
          level: 3,
          streetCount: 42,
          exploredCellCount: 150,
          exploredPct: 0.5,
        );
        const b = TurfShareCardData(
          zoneName: 'Hackney',
          level: 3,
          streetCount: 42,
          exploredCellCount: 150,
          exploredPct: 0.5,
        );

        expect(a, equals(b));
      });

      test('two instances with different data are not equal', () {
        const a = TurfShareCardData(
          zoneName: 'Hackney',
          level: 3,
          streetCount: 42,
          exploredCellCount: 150,
          exploredPct: 0.5,
        );
        const b = TurfShareCardData(
          zoneName: 'Shoreditch',
          level: 3,
          streetCount: 42,
          exploredCellCount: 150,
          exploredPct: 0.5,
        );

        expect(a, isNot(equals(b)));
      });

      test('instances with different exploredPct are not equal', () {
        const a = TurfShareCardData(
          zoneName: 'Hackney',
          level: 3,
          streetCount: 42,
          exploredCellCount: 150,
          exploredPct: 0.4,
        );
        const b = TurfShareCardData(
          zoneName: 'Hackney',
          level: 3,
          streetCount: 42,
          exploredCellCount: 150,
          exploredPct: 0.8,
        );

        expect(a, isNot(equals(b)));
      });

      test('instances with same data have the same hashCode', () {
        const a = TurfShareCardData(
          zoneName: 'Hackney',
          level: 2,
          streetCount: 10,
          exploredCellCount: 50,
          exploredPct: 0.3,
        );
        const b = TurfShareCardData(
          zoneName: 'Hackney',
          level: 2,
          streetCount: 10,
          exploredCellCount: 50,
          exploredPct: 0.3,
        );

        expect(a.hashCode, equals(b.hashCode));
      });
    });
  });
}
