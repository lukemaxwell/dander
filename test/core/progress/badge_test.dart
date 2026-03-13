import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_test/flutter_test.dart';
import 'package:dander/core/progress/badge.dart';

void main() {
  group('Badge', () {
    final lockedBadge = Badge(
      id: BadgeId.explorer,
      name: 'Explorer',
      description: 'Explore 10% of your neighbourhood',
      requiredExplorationPct: 0.10,
      icon: Icons.explore,
    );

    group('isUnlocked', () {
      test('returns false when unlockedAt is null', () {
        expect(lockedBadge.isUnlocked, isFalse);
      });

      test('returns true when unlockedAt is set', () {
        final unlocked = lockedBadge.unlock(DateTime(2024, 6, 1));
        expect(unlocked.isUnlocked, isTrue);
      });
    });

    group('unlock', () {
      test('returns a new Badge instance (immutable)', () {
        final at = DateTime(2024, 6, 1);
        final unlocked = lockedBadge.unlock(at);
        expect(unlocked, isNot(same(lockedBadge)));
      });

      test('sets unlockedAt to provided DateTime', () {
        final at = DateTime(2024, 6, 1, 12, 0, 0);
        final unlocked = lockedBadge.unlock(at);
        expect(unlocked.unlockedAt, equals(at));
      });

      test('preserves all other fields when unlocking', () {
        final at = DateTime(2024, 6, 1);
        final unlocked = lockedBadge.unlock(at);
        expect(unlocked.id, equals(lockedBadge.id));
        expect(unlocked.name, equals(lockedBadge.name));
        expect(unlocked.description, equals(lockedBadge.description));
        expect(unlocked.requiredExplorationPct,
            equals(lockedBadge.requiredExplorationPct));
        expect(unlocked.icon, equals(lockedBadge.icon));
      });

      test('original badge remains locked after unlock call', () {
        lockedBadge.unlock(DateTime(2024, 6, 1));
        expect(lockedBadge.isUnlocked, isFalse);
      });

      test('can unlock an already-unlocked badge (idempotent)', () {
        final first = lockedBadge.unlock(DateTime(2024, 6, 1));
        final second = first.unlock(DateTime(2024, 6, 2));
        expect(second.isUnlocked, isTrue);
        expect(second.unlockedAt, equals(DateTime(2024, 6, 2)));
      });
    });
  });

  group('BadgeDefinitions', () {
    test('contains exactly 6 badges', () {
      expect(BadgeDefinitions.badges.length, equals(6));
    });

    test('badge IDs are all unique', () {
      final ids = BadgeDefinitions.badges.map((b) => b.id).toList();
      expect(ids.toSet().length, equals(ids.length));
    });

    test('includes all 6 required BadgeIds', () {
      final ids = BadgeDefinitions.badges.map((b) => b.id).toSet();
      expect(ids, containsAll(BadgeId.values));
    });

    test('firstDander requires 0% exploration (first walk)', () {
      final badge = BadgeDefinitions.badges
          .firstWhere((b) => b.id == BadgeId.firstDander);
      expect(badge.requiredExplorationPct, equals(0.0));
    });

    test('explorer requires 10% exploration', () {
      final badge =
          BadgeDefinitions.badges.firstWhere((b) => b.id == BadgeId.explorer);
      expect(badge.requiredExplorationPct, equals(0.10));
    });

    test('pathfinder requires 25% exploration', () {
      final badge =
          BadgeDefinitions.badges.firstWhere((b) => b.id == BadgeId.pathfinder);
      expect(badge.requiredExplorationPct, equals(0.25));
    });

    test('localLegend requires 50% exploration', () {
      final badge = BadgeDefinitions.badges
          .firstWhere((b) => b.id == BadgeId.localLegend);
      expect(badge.requiredExplorationPct, equals(0.50));
    });

    test('cartographer requires 75% exploration', () {
      final badge = BadgeDefinitions.badges
          .firstWhere((b) => b.id == BadgeId.cartographer);
      expect(badge.requiredExplorationPct, equals(0.75));
    });

    test('omniscient requires 100% exploration', () {
      final badge =
          BadgeDefinitions.badges.firstWhere((b) => b.id == BadgeId.omniscient);
      expect(badge.requiredExplorationPct, equals(1.0));
    });

    test('badges are ordered by requiredExplorationPct ascending', () {
      final pcts =
          BadgeDefinitions.badges.map((b) => b.requiredExplorationPct).toList();
      for (var i = 1; i < pcts.length; i++) {
        expect(pcts[i], greaterThanOrEqualTo(pcts[i - 1]));
      }
    });

    test('all badges start locked (unlockedAt is null)', () {
      for (final badge in BadgeDefinitions.badges) {
        expect(badge.unlockedAt, isNull,
            reason: '${badge.id} should start locked');
      }
    });
  });
}
