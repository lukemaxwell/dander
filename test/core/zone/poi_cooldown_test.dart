import 'package:flutter_test/flutter_test.dart';

import 'package:dander/core/zone/poi_cooldown.dart';

void main() {
  const zoneId = 'zone_1';
  final fourHours = const Duration(hours: 4);

  PoiCooldown makeCooldown({
    String id = zoneId,
    DateTime? lastRequestedAt,
    Duration cooldownDuration = const Duration(hours: 4),
  }) =>
      PoiCooldown(
        zoneId: id,
        lastRequestedAt: lastRequestedAt,
        cooldownDuration: cooldownDuration,
      );

  final baseTime = DateTime(2026, 3, 13, 12, 0);

  group('PoiCooldown', () {
    group('isOnCooldown', () {
      test('returns false when no previous request', () {
        final cooldown = makeCooldown();
        expect(cooldown.isOnCooldown(baseTime), isFalse);
      });

      test('returns true when request was made less than 4 hours ago', () {
        final requestedAt = baseTime.subtract(const Duration(hours: 2));
        final cooldown = makeCooldown(lastRequestedAt: requestedAt);
        expect(cooldown.isOnCooldown(baseTime), isTrue);
      });

      test('returns true when request was made exactly at cooldown boundary', () {
        // Exactly 4 hours ago — still on cooldown (boundary is exclusive)
        final requestedAt = baseTime.subtract(fourHours);
        final cooldown = makeCooldown(lastRequestedAt: requestedAt);
        expect(cooldown.isOnCooldown(baseTime), isFalse);
      });

      test('returns false when request was made more than 4 hours ago', () {
        final requestedAt = baseTime.subtract(const Duration(hours: 4, minutes: 1));
        final cooldown = makeCooldown(lastRequestedAt: requestedAt);
        expect(cooldown.isOnCooldown(baseTime), isFalse);
      });

      test('returns true just before cooldown expires (1 second remaining)', () {
        final requestedAt = baseTime.subtract(
          const Duration(hours: 3, minutes: 59, seconds: 59),
        );
        final cooldown = makeCooldown(lastRequestedAt: requestedAt);
        expect(cooldown.isOnCooldown(baseTime), isTrue);
      });

      test('respects custom cooldown duration', () {
        final requestedAt = baseTime.subtract(const Duration(hours: 1));
        final cooldown = makeCooldown(
          lastRequestedAt: requestedAt,
          cooldownDuration: const Duration(hours: 2),
        );
        expect(cooldown.isOnCooldown(baseTime), isTrue);
      });

      test('returns false with custom cooldown that has expired', () {
        final requestedAt = baseTime.subtract(const Duration(hours: 3));
        final cooldown = makeCooldown(
          lastRequestedAt: requestedAt,
          cooldownDuration: const Duration(hours: 2),
        );
        expect(cooldown.isOnCooldown(baseTime), isFalse);
      });
    });

    group('remainingCooldown', () {
      test('returns Duration.zero when no previous request', () {
        final cooldown = makeCooldown();
        expect(cooldown.remainingCooldown(baseTime), Duration.zero);
      });

      test('returns Duration.zero when cooldown has expired', () {
        final requestedAt = baseTime.subtract(const Duration(hours: 5));
        final cooldown = makeCooldown(lastRequestedAt: requestedAt);
        expect(cooldown.remainingCooldown(baseTime), Duration.zero);
      });

      test('returns correct remaining duration when still on cooldown', () {
        final requestedAt = baseTime.subtract(const Duration(hours: 2));
        final cooldown = makeCooldown(lastRequestedAt: requestedAt);
        // 4h cooldown, 2h elapsed → 2h remaining
        expect(cooldown.remainingCooldown(baseTime), const Duration(hours: 2));
      });

      test('returns correct remaining at 1 second before expiry', () {
        final requestedAt = baseTime.subtract(
          const Duration(hours: 3, minutes: 59, seconds: 59),
        );
        final cooldown = makeCooldown(lastRequestedAt: requestedAt);
        expect(
          cooldown.remainingCooldown(baseTime),
          const Duration(seconds: 1),
        );
      });

      test('returns Duration.zero at exact cooldown boundary', () {
        final requestedAt = baseTime.subtract(fourHours);
        final cooldown = makeCooldown(lastRequestedAt: requestedAt);
        expect(cooldown.remainingCooldown(baseTime), Duration.zero);
      });

      test('respects custom cooldown duration', () {
        final requestedAt = baseTime.subtract(const Duration(minutes: 30));
        final cooldown = makeCooldown(
          lastRequestedAt: requestedAt,
          cooldownDuration: const Duration(hours: 1),
        );
        expect(
          cooldown.remainingCooldown(baseTime),
          const Duration(minutes: 30),
        );
      });
    });

    group('recordRequest', () {
      test('returns new PoiCooldown with updated lastRequestedAt', () {
        final cooldown = makeCooldown();
        final updated = cooldown.recordRequest(baseTime);
        expect(updated.lastRequestedAt, baseTime);
      });

      test('original is not mutated', () {
        final cooldown = makeCooldown();
        cooldown.recordRequest(baseTime);
        expect(cooldown.lastRequestedAt, isNull);
      });

      test('preserves zoneId', () {
        final cooldown = makeCooldown(id: 'zone_42');
        final updated = cooldown.recordRequest(baseTime);
        expect(updated.zoneId, 'zone_42');
      });

      test('preserves cooldownDuration', () {
        final customDuration = const Duration(hours: 6);
        final cooldown = makeCooldown(cooldownDuration: customDuration);
        final updated = cooldown.recordRequest(baseTime);
        expect(updated.cooldownDuration, customDuration);
      });

      test('overwrites previous lastRequestedAt', () {
        final firstTime = baseTime.subtract(const Duration(hours: 3));
        final cooldown = makeCooldown(lastRequestedAt: firstTime);
        final updated = cooldown.recordRequest(baseTime);
        expect(updated.lastRequestedAt, baseTime);
      });

      test('updated cooldown correctly reflects new state', () {
        final cooldown = makeCooldown();
        final updated = cooldown.recordRequest(baseTime);
        // Should be on cooldown right after recording
        expect(updated.isOnCooldown(baseTime), isTrue);
      });
    });

    group('JSON serialisation', () {
      test('round-trips with lastRequestedAt set', () {
        final cooldown = PoiCooldown(
          zoneId: zoneId,
          lastRequestedAt: baseTime,
          cooldownDuration: fourHours,
        );
        final json = cooldown.toJson();
        final restored = PoiCooldown.fromJson(json);
        expect(restored.zoneId, cooldown.zoneId);
        expect(restored.lastRequestedAt, cooldown.lastRequestedAt);
        expect(restored.cooldownDuration, cooldown.cooldownDuration);
      });

      test('round-trips with null lastRequestedAt', () {
        final cooldown = makeCooldown();
        final json = cooldown.toJson();
        final restored = PoiCooldown.fromJson(json);
        expect(restored.zoneId, cooldown.zoneId);
        expect(restored.lastRequestedAt, isNull);
        expect(restored.cooldownDuration, cooldown.cooldownDuration);
      });

      test('toJson contains expected keys', () {
        final cooldown = makeCooldown(lastRequestedAt: baseTime);
        final json = cooldown.toJson();
        expect(json, contains('zoneId'));
        expect(json, contains('lastRequestedAt'));
        expect(json, contains('cooldownSeconds'));
      });

      test('toJson encodes lastRequestedAt as ISO 8601 string', () {
        final cooldown = makeCooldown(lastRequestedAt: baseTime);
        final json = cooldown.toJson();
        expect(json['lastRequestedAt'], baseTime.toIso8601String());
      });

      test('toJson encodes null lastRequestedAt as null', () {
        final cooldown = makeCooldown();
        final json = cooldown.toJson();
        expect(json['lastRequestedAt'], isNull);
      });

      test('round-trips custom cooldown duration', () {
        final cooldown = makeCooldown(
          cooldownDuration: const Duration(hours: 8),
        );
        final json = cooldown.toJson();
        final restored = PoiCooldown.fromJson(json);
        expect(restored.cooldownDuration, const Duration(hours: 8));
      });
    });

    group('immutability', () {
      test('copyWith returns new instance with overrides', () {
        final cooldown = makeCooldown(id: 'zone_1', lastRequestedAt: baseTime);
        final copy = cooldown.copyWith(zoneId: 'zone_2');
        expect(copy.zoneId, 'zone_2');
        expect(copy.lastRequestedAt, baseTime);
        expect(cooldown.zoneId, 'zone_1'); // original unchanged
      });

      test('copyWith with no overrides returns equivalent object', () {
        final cooldown = makeCooldown(lastRequestedAt: baseTime);
        final copy = cooldown.copyWith();
        expect(copy.zoneId, cooldown.zoneId);
        expect(copy.lastRequestedAt, cooldown.lastRequestedAt);
        expect(copy.cooldownDuration, cooldown.cooldownDuration);
      });
    });
  });
}
