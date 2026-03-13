import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/progress/badge.dart';
import 'package:dander/core/zone/global_stats_calculator.dart';
import 'package:dander/core/zone/mystery_poi.dart';
import 'package:dander/core/zone/zone.dart';

void main() {
  final now = DateTime(2026, 3, 13, 12, 0);
  final centre = LatLng(51.5074, -0.1278);

  Zone makeZone({
    String id = 'zone_1',
    String name = 'Hackney',
    int xp = 0,
  }) =>
      Zone(
        id: id,
        name: name,
        centre: centre,
        createdAt: now,
        xp: xp,
      );

  MysteryPoi makePoi({
    required String id,
    bool revealed = false,
  }) =>
      MysteryPoi(
        id: id,
        position: centre,
        category: 'pub',
        name: revealed ? 'The Pub' : null,
      );

  Badge makeBadge(BadgeId badgeId, String name) => Badge(
        id: badgeId,
        name: name,
        description: 'A badge',
        requiredExplorationPct: 0.0,
        icon: Icons.star,
      );

  group('GlobalStatsCalculator', () {
    group('empty zones', () {
      test('returns all zeros when zones list is empty', () {
        final result = GlobalStatsCalculator.calculate(
          zones: [],
          poisByZone: {},
          badgesByZone: {},
        );

        expect(result.totalZones, 0);
        expect(result.totalXp, 0);
        expect(result.totalStreetsWalked, 0);
        expect(result.totalPoisDiscovered, 0);
        expect(result.badgesByZone, isEmpty);
      });
    });

    group('single zone', () {
      test('counts the zone', () {
        final zone = makeZone(xp: 100);

        final result = GlobalStatsCalculator.calculate(
          zones: [zone],
          poisByZone: {},
          badgesByZone: {},
        );

        expect(result.totalZones, 1);
      });

      test('sums XP from the zone', () {
        final zone = makeZone(xp: 250);

        final result = GlobalStatsCalculator.calculate(
          zones: [zone],
          poisByZone: {},
          badgesByZone: {},
        );

        expect(result.totalXp, 250);
      });

      test('counts only revealed POIs', () {
        final zone = makeZone();
        final pois = [
          makePoi(id: 'p1', revealed: true),
          makePoi(id: 'p2', revealed: false),
          makePoi(id: 'p3', revealed: true),
        ];

        final result = GlobalStatsCalculator.calculate(
          zones: [zone],
          poisByZone: {zone.id: pois},
          badgesByZone: {},
        );

        expect(result.totalPoisDiscovered, 2);
      });

      test('includes zero when no POIs are revealed', () {
        final zone = makeZone();
        final pois = [
          makePoi(id: 'p1', revealed: false),
          makePoi(id: 'p2', revealed: false),
        ];

        final result = GlobalStatsCalculator.calculate(
          zones: [zone],
          poisByZone: {zone.id: pois},
          badgesByZone: {},
        );

        expect(result.totalPoisDiscovered, 0);
      });

      test('includes zero when zone has no POIs entry', () {
        final zone = makeZone();

        final result = GlobalStatsCalculator.calculate(
          zones: [zone],
          poisByZone: {},
          badgesByZone: {},
        );

        expect(result.totalPoisDiscovered, 0);
      });

      test('groups badges by zone name', () {
        final zone = makeZone(name: 'Hackney');
        final badge = makeBadge(BadgeId.firstDander, 'First Dander');

        final result = GlobalStatsCalculator.calculate(
          zones: [zone],
          poisByZone: {},
          badgesByZone: {zone.id: [badge]},
        );

        expect(result.badgesByZone.keys, contains('Hackney'));
        expect(result.badgesByZone['Hackney'], [badge]);
      });

      test('produces empty badge list for zone with no badges', () {
        final zone = makeZone(name: 'Hackney');

        final result = GlobalStatsCalculator.calculate(
          zones: [zone],
          poisByZone: {},
          badgesByZone: {},
        );

        expect(result.badgesByZone['Hackney'], isNull);
      });

      test('streetsWalked is always zero (placeholder)', () {
        final zone = makeZone(xp: 500);

        final result = GlobalStatsCalculator.calculate(
          zones: [zone],
          poisByZone: {},
          badgesByZone: {},
        );

        expect(result.totalStreetsWalked, 0);
      });
    });

    group('multiple zones aggregate correctly', () {
      test('sums zone count', () {
        final zones = [
          makeZone(id: 'zone_1', name: 'Hackney'),
          makeZone(id: 'zone_2', name: 'Shoreditch'),
          makeZone(id: 'zone_3', name: 'Peckham'),
        ];

        final result = GlobalStatsCalculator.calculate(
          zones: zones,
          poisByZone: {},
          badgesByZone: {},
        );

        expect(result.totalZones, 3);
      });

      test('sums XP across all zones', () {
        final zones = [
          makeZone(id: 'zone_1', name: 'Hackney', xp: 100),
          makeZone(id: 'zone_2', name: 'Shoreditch', xp: 250),
          makeZone(id: 'zone_3', name: 'Peckham', xp: 75),
        ];

        final result = GlobalStatsCalculator.calculate(
          zones: zones,
          poisByZone: {},
          badgesByZone: {},
        );

        expect(result.totalXp, 425);
      });

      test('sums revealed POIs across all zones', () {
        final zones = [
          makeZone(id: 'zone_1', name: 'Hackney'),
          makeZone(id: 'zone_2', name: 'Shoreditch'),
        ];
        final poisByZone = {
          'zone_1': [
            makePoi(id: 'p1', revealed: true),
            makePoi(id: 'p2', revealed: false),
            makePoi(id: 'p3', revealed: true),
          ],
          'zone_2': [
            makePoi(id: 'p4', revealed: true),
            makePoi(id: 'p5', revealed: false),
          ],
        };

        final result = GlobalStatsCalculator.calculate(
          zones: zones,
          poisByZone: poisByZone,
          badgesByZone: {},
        );

        // 2 revealed in zone_1 + 1 revealed in zone_2
        expect(result.totalPoisDiscovered, 3);
      });

      test('groups badges by zone name across all zones', () {
        final zones = [
          makeZone(id: 'zone_1', name: 'Hackney'),
          makeZone(id: 'zone_2', name: 'Shoreditch'),
        ];
        final badge1 = makeBadge(BadgeId.firstDander, 'First Dander');
        final badge2 = makeBadge(BadgeId.explorer, 'Explorer');
        final badgesByZone = <String, List<Badge>>{
          'zone_1': [badge1],
          'zone_2': [badge2],
        };

        final result = GlobalStatsCalculator.calculate(
          zones: zones,
          poisByZone: {},
          badgesByZone: badgesByZone,
        );

        expect(result.badgesByZone.keys, containsAll(['Hackney', 'Shoreditch']));
        expect(result.badgesByZone['Hackney'], [badge1]);
        expect(result.badgesByZone['Shoreditch'], [badge2]);
      });

      test('ignores POI entries for unknown zone ids', () {
        final zones = [
          makeZone(id: 'zone_1', name: 'Hackney'),
        ];
        final poisByZone = {
          'zone_1': [makePoi(id: 'p1', revealed: true)],
          'unknown_zone': [makePoi(id: 'p2', revealed: true)],
        };

        final result = GlobalStatsCalculator.calculate(
          zones: zones,
          poisByZone: poisByZone,
          badgesByZone: {},
        );

        // Only the POIs that belong to known zones are counted
        expect(result.totalZones, 1);
        expect(result.totalPoisDiscovered, 1);
      });

      test('handles zones with zero XP mixed with zones with XP', () {
        final zones = [
          makeZone(id: 'zone_1', name: 'Hackney', xp: 0),
          makeZone(id: 'zone_2', name: 'Shoreditch', xp: 400),
        ];

        final result = GlobalStatsCalculator.calculate(
          zones: zones,
          poisByZone: {},
          badgesByZone: {},
        );

        expect(result.totalXp, 400);
      });

      test('streetsWalked stays zero across many zones', () {
        final zones = [
          makeZone(id: 'zone_1', name: 'Hackney', xp: 100),
          makeZone(id: 'zone_2', name: 'Shoreditch', xp: 200),
        ];

        final result = GlobalStatsCalculator.calculate(
          zones: zones,
          poisByZone: {},
          badgesByZone: {},
        );

        expect(result.totalStreetsWalked, 0);
      });
    });

    group('only revealed POIs counted', () {
      test('all unrevealed produces zero discoveries', () {
        final zone = makeZone();
        final pois = List.generate(
          10,
          (i) => makePoi(id: 'p$i', revealed: false),
        );

        final result = GlobalStatsCalculator.calculate(
          zones: [zone],
          poisByZone: {zone.id: pois},
          badgesByZone: {},
        );

        expect(result.totalPoisDiscovered, 0);
      });

      test('all revealed produces full count', () {
        final zone = makeZone();
        final pois = List.generate(
          5,
          (i) => makePoi(id: 'p$i', revealed: true),
        );

        final result = GlobalStatsCalculator.calculate(
          zones: [zone],
          poisByZone: {zone.id: pois},
          badgesByZone: {},
        );

        expect(result.totalPoisDiscovered, 5);
      });

      test('mixed revealed state counts only revealed ones', () {
        final zones = [
          makeZone(id: 'zone_1', name: 'A'),
          makeZone(id: 'zone_2', name: 'B'),
        ];
        final poisByZone = {
          'zone_1': [
            makePoi(id: 'p1', revealed: true),
            makePoi(id: 'p2', revealed: true),
            makePoi(id: 'p3', revealed: false),
          ],
          'zone_2': [
            makePoi(id: 'p4', revealed: false),
            makePoi(id: 'p5', revealed: false),
            makePoi(id: 'p6', revealed: true),
          ],
        };

        final result = GlobalStatsCalculator.calculate(
          zones: zones,
          poisByZone: poisByZone,
          badgesByZone: {},
        );

        expect(result.totalPoisDiscovered, 3);
      });
    });

    group('badges grouped correctly by zone name', () {
      test('zone with no badge entry is omitted from badgesByZone', () {
        final zones = [
          makeZone(id: 'zone_1', name: 'Hackney'),
          makeZone(id: 'zone_2', name: 'Shoreditch'),
        ];
        final badgesByZone = <String, List<Badge>>{
          'zone_1': [makeBadge(BadgeId.firstDander, 'First Dander')],
          // zone_2 intentionally omitted
        };

        final result = GlobalStatsCalculator.calculate(
          zones: zones,
          poisByZone: {},
          badgesByZone: badgesByZone,
        );

        expect(result.badgesByZone.containsKey('Hackney'), isTrue);
        expect(result.badgesByZone.containsKey('Shoreditch'), isFalse);
      });

      test('multiple badges per zone are all included', () {
        final zone = makeZone(id: 'zone_1', name: 'Hackney');
        final badges = <Badge>[
          makeBadge(BadgeId.firstDander, 'First Dander'),
          makeBadge(BadgeId.explorer, 'Explorer'),
          makeBadge(BadgeId.pathfinder, 'Pathfinder'),
        ];

        final result = GlobalStatsCalculator.calculate(
          zones: [zone],
          poisByZone: {},
          badgesByZone: {'zone_1': badges},
        );

        expect(result.badgesByZone['Hackney'], hasLength(3));
        expect(result.badgesByZone['Hackney'], badges);
      });

      test('zone name is used as key, not zone id', () {
        final zone = makeZone(id: 'abc123', name: 'My Special Zone');
        final badge = makeBadge(BadgeId.explorer, 'Explorer');

        final result = GlobalStatsCalculator.calculate(
          zones: [zone],
          poisByZone: {},
          badgesByZone: <String, List<Badge>>{'abc123': [badge]},
        );

        expect(result.badgesByZone.containsKey('abc123'), isFalse);
        expect(result.badgesByZone.containsKey('My Special Zone'), isTrue);
      });

      test('ignores badge entries for zone ids not in zones list', () {
        final zones = [
          makeZone(id: 'zone_1', name: 'Hackney'),
        ];
        final badgesByZone = <String, List<Badge>>{
          'zone_1': [makeBadge(BadgeId.firstDander, 'First Dander')],
          'ghost_zone': [makeBadge(BadgeId.omniscient, 'Omniscient')],
        };

        final result = GlobalStatsCalculator.calculate(
          zones: zones,
          poisByZone: {},
          badgesByZone: badgesByZone,
        );

        expect(result.badgesByZone.keys, hasLength(1));
        expect(result.badgesByZone.containsKey('Hackney'), isTrue);
      });
    });
  });
}
