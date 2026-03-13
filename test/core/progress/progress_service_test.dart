import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart' show LatLngBounds;
import 'package:latlong2/latlong.dart';
import 'package:dander/core/fog/fog_grid.dart';
import 'package:dander/core/progress/badge.dart';
import 'package:dander/core/progress/streak_tracker.dart';
import 'package:dander/core/progress/progress_service.dart';

void main() {
  late ProgressService service;
  const origin = LatLng(51.5, -0.05);

  setUp(() {
    service = ProgressService();
  });

  group('ProgressService.computeExplorationPct', () {
    test('returns 0.0 for empty grid', () {
      final grid = FogGrid(origin: origin);
      final bounds = LatLngBounds(
        const LatLng(51.49, -0.06),
        const LatLng(51.51, -0.04),
      );
      final pct = service.computeExplorationPct(grid, bounds);
      expect(pct, equals(0.0));
    });

    test('returns 1.0 when all cells in bounds are explored', () {
      final grid = FogGrid(origin: origin);
      final bounds = LatLngBounds(
        const LatLng(51.499, -0.051),
        const LatLng(51.501, -0.049),
      );
      // Mark entire bounding box explored with a large radius
      grid.markExplored(origin, 500.0);
      final pct = service.computeExplorationPct(grid, bounds);
      expect(pct, equals(1.0));
    });

    test('returns value between 0 and 1 for partial exploration', () {
      final grid = FogGrid(origin: origin);
      final bounds = LatLngBounds(
        const LatLng(51.49, -0.06),
        const LatLng(51.51, -0.04),
      );
      // Explore a small area within bounds
      grid.markExplored(origin, 30.0);
      final pct = service.computeExplorationPct(grid, bounds);
      expect(pct, greaterThan(0.0));
      expect(pct, lessThan(1.0));
    });

    test('delegates to FogGrid.explorationPercentage', () {
      final grid = FogGrid(origin: origin);
      final bounds = LatLngBounds(
        const LatLng(51.499, -0.051),
        const LatLng(51.501, -0.049),
      );
      grid.markExplored(origin, 100.0);
      final servicePct = service.computeExplorationPct(grid, bounds);
      final directPct = grid.explorationPercentage(bounds);
      expect(servicePct, equals(directPct));
    });

    test('result is clamped to 0.0–1.0', () {
      final grid = FogGrid(origin: origin);
      final bounds = LatLngBounds(
        const LatLng(51.499, -0.051),
        const LatLng(51.501, -0.049),
      );
      final pct = service.computeExplorationPct(grid, bounds);
      expect(pct, greaterThanOrEqualTo(0.0));
      expect(pct, lessThanOrEqualTo(1.0));
    });
  });

  group('ProgressService.checkBadges', () {
    final now = DateTime(2024, 6, 1);

    List<Badge> freshBadges() => BadgeDefinitions.badges
        .map((b) => Badge(
              id: b.id,
              name: b.name,
              description: b.description,
              requiredExplorationPct: b.requiredExplorationPct,
              icon: b.icon,
            ))
        .toList();

    test('unlocks firstDander badge at any exploration > 0', () {
      final badges = service.checkBadges(0.01, freshBadges(), now);
      final firstDander = badges.firstWhere((b) => b.id == BadgeId.firstDander);
      expect(firstDander.isUnlocked, isTrue);
    });

    test('does not unlock explorer badge at 9% exploration', () {
      final badges = service.checkBadges(0.09, freshBadges(), now);
      final explorer = badges.firstWhere((b) => b.id == BadgeId.explorer);
      expect(explorer.isUnlocked, isFalse);
    });

    test('unlocks explorer badge at exactly 10% exploration', () {
      final badges = service.checkBadges(0.10, freshBadges(), now);
      final explorer = badges.firstWhere((b) => b.id == BadgeId.explorer);
      expect(explorer.isUnlocked, isTrue);
    });

    test('unlocks pathfinder badge at 25%', () {
      final badges = service.checkBadges(0.25, freshBadges(), now);
      final pathfinder = badges.firstWhere((b) => b.id == BadgeId.pathfinder);
      expect(pathfinder.isUnlocked, isTrue);
    });

    test('unlocks localLegend badge at 50%', () {
      final badges = service.checkBadges(0.50, freshBadges(), now);
      final localLegend = badges.firstWhere((b) => b.id == BadgeId.localLegend);
      expect(localLegend.isUnlocked, isTrue);
    });

    test('unlocks cartographer badge at 75%', () {
      final badges = service.checkBadges(0.75, freshBadges(), now);
      final cartographer =
          badges.firstWhere((b) => b.id == BadgeId.cartographer);
      expect(cartographer.isUnlocked, isTrue);
    });

    test('unlocks omniscient badge at 100%', () {
      final badges = service.checkBadges(1.0, freshBadges(), now);
      final omniscient = badges.firstWhere((b) => b.id == BadgeId.omniscient);
      expect(omniscient.isUnlocked, isTrue);
    });

    test('at 100% all badges are unlocked', () {
      final badges = service.checkBadges(1.0, freshBadges(), now);
      for (final badge in badges) {
        expect(badge.isUnlocked, isTrue,
            reason: '${badge.id} should be unlocked');
      }
    });

    test(
        'already-unlocked badge is not re-unlocked (preserves original timestamp)',
        () {
      final originalTime = DateTime(2024, 1, 1);
      final badgesWithExplorer = freshBadges().map((b) {
        if (b.id == BadgeId.explorer) return b.unlock(originalTime);
        return b;
      }).toList();

      final updated =
          service.checkBadges(0.50, badgesWithExplorer, DateTime(2024, 6, 1));
      final explorer = updated.firstWhere((b) => b.id == BadgeId.explorer);
      expect(explorer.unlockedAt, equals(originalTime));
    });

    test('returns new list (immutable — does not modify input)', () {
      final input = freshBadges();
      final output = service.checkBadges(0.10, input, now);
      // Explorer should be unlocked in output but input should be unchanged
      final inputExplorer = input.firstWhere((b) => b.id == BadgeId.explorer);
      expect(inputExplorer.isUnlocked, isFalse);
      final outputExplorer = output.firstWhere((b) => b.id == BadgeId.explorer);
      expect(outputExplorer.isUnlocked, isTrue);
    });

    test('at 0% no badges are unlocked', () {
      final badges = service.checkBadges(0.0, freshBadges(), now);
      for (final badge in badges) {
        expect(badge.isUnlocked, isFalse,
            reason: '${badge.id} should remain locked');
      }
    });
  });

  group('ProgressService.recordWalk', () {
    test('delegates to StreakTracker.recordWalk', () {
      final tracker = StreakTracker.empty();
      final date = DateTime(2024, 6, 3);
      final updated = service.recordWalk(tracker, date);
      expect(updated.currentStreak, equals(1));
      expect(updated.lastWalkDate, equals(date));
    });

    test('returns new StreakTracker (immutable)', () {
      final tracker = StreakTracker.empty();
      final updated = service.recordWalk(tracker, DateTime(2024, 6, 3));
      expect(updated, isNot(same(tracker)));
    });
  });
}
