import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/zone/level_up_detector.dart';
import 'package:dander/core/zone/zone.dart';

Zone _zone({required int xp}) => Zone(
      id: 'z1',
      name: 'Test Zone',
      centre: const LatLng(51.5, -0.1),
      createdAt: DateTime(2024),
      xp: xp,
    );

void main() {
  group('LevelUpEvent', () {
    test('is immutable — fields are final', () {
      const event = LevelUpEvent(
        previousLevel: 1,
        newLevel: 2,
        newRadiusMeters: 1500.0,
      );
      expect(event.previousLevel, 1);
      expect(event.newLevel, 2);
      expect(event.newRadiusMeters, 1500.0);
    });

    test('equality — same fields are equal', () {
      const a = LevelUpEvent(
        previousLevel: 2,
        newLevel: 3,
        newRadiusMeters: 3000.0,
      );
      const b = LevelUpEvent(
        previousLevel: 2,
        newLevel: 3,
        newRadiusMeters: 3000.0,
      );
      expect(a, equals(b));
    });

    test('equality — different fields are not equal', () {
      const a = LevelUpEvent(
        previousLevel: 1,
        newLevel: 2,
        newRadiusMeters: 1500.0,
      );
      const b = LevelUpEvent(
        previousLevel: 2,
        newLevel: 3,
        newRadiusMeters: 3000.0,
      );
      expect(a, isNot(equals(b)));
    });

    test('toString contains all field values', () {
      const event = LevelUpEvent(
        previousLevel: 3,
        newLevel: 4,
        newRadiusMeters: 8000.0,
      );
      final str = event.toString();
      expect(str, contains('3'));
      expect(str, contains('4'));
      expect(str, contains('8000'));
    });
  });

  group('LevelUpDetector.checkLevelUp', () {
    group('returns null when no level change', () {
      test('same XP — no level up', () {
        final zone = _zone(xp: 50);
        expect(LevelUpDetector.checkLevelUp(zone, zone), isNull);
      });

      test('XP increase within same level — no level up (L1: 0→90)', () {
        final before = _zone(xp: 0);
        final after = _zone(xp: 90);
        expect(LevelUpDetector.checkLevelUp(before, after), isNull);
      });

      test('XP increase within L2 — no level up (110→290)', () {
        final before = _zone(xp: 110);
        final after = _zone(xp: 290);
        expect(LevelUpDetector.checkLevelUp(before, after), isNull);
      });

      test('XP increase within L3 — no level up (310→690)', () {
        final before = _zone(xp: 310);
        final after = _zone(xp: 690);
        expect(LevelUpDetector.checkLevelUp(before, after), isNull);
      });

      test('XP increase within L4 — no level up (710→1490)', () {
        final before = _zone(xp: 710);
        final after = _zone(xp: 1490);
        expect(LevelUpDetector.checkLevelUp(before, after), isNull);
      });

      test('already at max level — no level up (1600→2000)', () {
        final before = _zone(xp: 1600);
        final after = _zone(xp: 2000);
        expect(LevelUpDetector.checkLevelUp(before, after), isNull);
      });

      test('both zones at same level with same XP (L3)', () {
        final before = _zone(xp: 300);
        final after = _zone(xp: 300);
        expect(LevelUpDetector.checkLevelUp(before, after), isNull);
      });
    });

    group('returns LevelUpEvent when level changes', () {
      test('L1 → L2: exactly at threshold (0 → 100)', () {
        final before = _zone(xp: 0);
        final after = _zone(xp: 100);
        final event = LevelUpDetector.checkLevelUp(before, after);
        expect(event, isNotNull);
        expect(event!.previousLevel, 1);
        expect(event.newLevel, 2);
        expect(event.newRadiusMeters, 1500.0);
      });

      test('L1 → L2: just past threshold (99 → 100)', () {
        final before = _zone(xp: 99);
        final after = _zone(xp: 100);
        final event = LevelUpDetector.checkLevelUp(before, after);
        expect(event, isNotNull);
        expect(event!.previousLevel, 1);
        expect(event.newLevel, 2);
        expect(event.newRadiusMeters, 1500.0);
      });

      test('L2 → L3 (299 → 300)', () {
        final before = _zone(xp: 299);
        final after = _zone(xp: 300);
        final event = LevelUpDetector.checkLevelUp(before, after);
        expect(event, isNotNull);
        expect(event!.previousLevel, 2);
        expect(event.newLevel, 3);
        expect(event.newRadiusMeters, 3000.0);
      });

      test('L3 → L4 (699 → 700)', () {
        final before = _zone(xp: 699);
        final after = _zone(xp: 700);
        final event = LevelUpDetector.checkLevelUp(before, after);
        expect(event, isNotNull);
        expect(event!.previousLevel, 3);
        expect(event.newLevel, 4);
        expect(event.newRadiusMeters, 8000.0);
      });

      test('L4 → L5 (1499 → 1500)', () {
        final before = _zone(xp: 1499);
        final after = _zone(xp: 1500);
        final event = LevelUpDetector.checkLevelUp(before, after);
        expect(event, isNotNull);
        expect(event!.previousLevel, 4);
        expect(event.newLevel, 5);
        expect(event.newRadiusMeters, 100000.0);
      });

      test('L1 → L3 (big XP jump, skipping a level)', () {
        // Only the final state matters — report the new level vs old level
        final before = _zone(xp: 50);
        final after = _zone(xp: 350);
        final event = LevelUpDetector.checkLevelUp(before, after);
        expect(event, isNotNull);
        expect(event!.previousLevel, 1);
        expect(event.newLevel, 3);
        expect(event.newRadiusMeters, 3000.0);
      });

      test('L1 → L5 (extreme XP jump)', () {
        final before = _zone(xp: 0);
        final after = _zone(xp: 99999);
        final event = LevelUpDetector.checkLevelUp(before, after);
        expect(event, isNotNull);
        expect(event!.previousLevel, 1);
        expect(event.newLevel, 5);
        expect(event.newRadiusMeters, 100000.0);
      });
    });

    group('edge cases', () {
      test('XP decreases — no level up reported', () {
        // Should not happen in practice but must not crash
        final before = _zone(xp: 200);
        final after = _zone(xp: 50);
        // Level went down, not up — return null
        expect(LevelUpDetector.checkLevelUp(before, after), isNull);
      });

      test('both at exactly L5 threshold (1500)', () {
        final before = _zone(xp: 1500);
        final after = _zone(xp: 1500);
        expect(LevelUpDetector.checkLevelUp(before, after), isNull);
      });
    });
  });
}
