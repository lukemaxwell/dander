import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/core/progress/badge.dart';
import 'package:dander/core/zone/global_stats.dart';

void main() {
  group('GlobalStats', () {
    group('construction', () {
      test('stores all fields correctly', () {
        final badgesByZone = <String, List<Badge>>{
          'Hackney': [
            const Badge(
              id: BadgeId.firstDander,
              name: 'First Dander',
              description: 'Complete your first walk',
              requiredExplorationPct: 0.0,
              icon: Icons.directions_walk,
            ),
          ],
        };

        final stats = GlobalStats(
          totalZones: 2,
          totalXp: 500,
          totalStreetsWalked: 0,
          totalPoisDiscovered: 7,
          badgesByZone: badgesByZone,
        );

        expect(stats.totalZones, 2);
        expect(stats.totalXp, 500);
        expect(stats.totalStreetsWalked, 0);
        expect(stats.totalPoisDiscovered, 7);
        expect(stats.badgesByZone, badgesByZone);
      });

      test('allows empty badgesByZone', () {
        const stats = GlobalStats(
          totalZones: 0,
          totalXp: 0,
          totalStreetsWalked: 0,
          totalPoisDiscovered: 0,
          badgesByZone: {},
        );

        expect(stats.totalZones, 0);
        expect(stats.totalXp, 0);
        expect(stats.totalStreetsWalked, 0);
        expect(stats.totalPoisDiscovered, 0);
        expect(stats.badgesByZone, isEmpty);
      });

      test('allows multiple zones in badgesByZone', () {
        final badge1 = const Badge(
          id: BadgeId.explorer,
          name: 'Explorer',
          description: 'Explore 10%',
          requiredExplorationPct: 0.10,
          icon: Icons.explore,
        );
        final badge2 = const Badge(
          id: BadgeId.pathfinder,
          name: 'Pathfinder',
          description: 'Explore 25%',
          requiredExplorationPct: 0.25,
          icon: Icons.map,
        );

        final stats = GlobalStats(
          totalZones: 2,
          totalXp: 300,
          totalStreetsWalked: 0,
          totalPoisDiscovered: 3,
          badgesByZone: <String, List<Badge>>{
            'Zone A': [badge1],
            'Zone B': [badge2],
          },
        );

        expect(stats.badgesByZone.keys, containsAll(['Zone A', 'Zone B']));
        expect(stats.badgesByZone['Zone A'], [badge1]);
        expect(stats.badgesByZone['Zone B'], [badge2]);
      });
    });

    group('immutability', () {
      test('is a const-constructible value object', () {
        const stats1 = GlobalStats(
          totalZones: 1,
          totalXp: 100,
          totalStreetsWalked: 0,
          totalPoisDiscovered: 2,
          badgesByZone: {},
        );
        const stats2 = GlobalStats(
          totalZones: 1,
          totalXp: 100,
          totalStreetsWalked: 0,
          totalPoisDiscovered: 2,
          badgesByZone: {},
        );

        expect(stats1.totalZones, stats2.totalZones);
        expect(stats1.totalXp, stats2.totalXp);
        expect(stats1.totalPoisDiscovered, stats2.totalPoisDiscovered);
      });
    });
  });
}
