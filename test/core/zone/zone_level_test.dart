import 'package:flutter_test/flutter_test.dart';

import 'package:dander/core/zone/zone_level.dart';

void main() {
  group('ZoneLevel', () {
    group('levelForXp', () {
      test('returns 1 for 0 XP', () {
        expect(ZoneLevel.levelForXp(0), 1);
      });

      test('returns 1 for 99 XP (just below L2)', () {
        expect(ZoneLevel.levelForXp(99), 1);
      });

      test('returns 2 for exactly 100 XP', () {
        expect(ZoneLevel.levelForXp(100), 2);
      });

      test('returns 2 for 299 XP (just below L3)', () {
        expect(ZoneLevel.levelForXp(299), 2);
      });

      test('returns 3 for exactly 300 XP', () {
        expect(ZoneLevel.levelForXp(300), 3);
      });

      test('returns 4 for exactly 700 XP', () {
        expect(ZoneLevel.levelForXp(700), 4);
      });

      test('returns 5 for exactly 1500 XP', () {
        expect(ZoneLevel.levelForXp(1500), 5);
      });

      test('returns 5 for very high XP', () {
        expect(ZoneLevel.levelForXp(99999), 5);
      });
    });

    group('radiusForXp', () {
      test('returns 500m for L1', () {
        expect(ZoneLevel.radiusForXp(0), 500.0);
      });

      test('returns 1500m for L2', () {
        expect(ZoneLevel.radiusForXp(100), 1500.0);
      });

      test('returns 3000m for L3', () {
        expect(ZoneLevel.radiusForXp(300), 3000.0);
      });

      test('returns 8000m for L4', () {
        expect(ZoneLevel.radiusForXp(700), 8000.0);
      });

      test('returns 100000m for L5', () {
        expect(ZoneLevel.radiusForXp(1500), 100000.0);
      });
    });

    group('xpForNextLevel', () {
      test('returns 100 when at L1', () {
        expect(ZoneLevel.xpForNextLevel(0), 100);
      });

      test('returns 100 when at 50 XP (still L1)', () {
        expect(ZoneLevel.xpForNextLevel(50), 100);
      });

      test('returns 300 when at L2', () {
        expect(ZoneLevel.xpForNextLevel(100), 300);
      });

      test('returns 700 when at L3', () {
        expect(ZoneLevel.xpForNextLevel(300), 700);
      });

      test('returns 1500 when at L4', () {
        expect(ZoneLevel.xpForNextLevel(700), 1500);
      });

      test('returns null when at max level', () {
        expect(ZoneLevel.xpForNextLevel(1500), isNull);
      });

      test('returns null for very high XP', () {
        expect(ZoneLevel.xpForNextLevel(99999), isNull);
      });
    });

    group('XP constants', () {
      test('xpPerStreet is 10', () {
        expect(ZoneLevel.xpPerStreet, 10);
      });

      test('xpPerQuizCorrect is 5', () {
        expect(ZoneLevel.xpPerQuizCorrect, 5);
      });

      test('xpPerStreakBonus is 2', () {
        expect(ZoneLevel.xpPerStreakBonus, 2);
      });

      test('xpPerPoi is 50', () {
        expect(ZoneLevel.xpPerPoi, 50);
      });
    });
  });
}
