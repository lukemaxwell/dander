import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:dander/core/zone/poi_cooldown.dart';
import 'package:dander/core/zone/poi_cooldown_repository.dart';

void main() {
  late Box<dynamic> box;
  late HivePoiCooldownRepository repo;

  final baseTime = DateTime(2026, 3, 13, 12, 0);

  PoiCooldown makeCooldown({
    String zoneId = 'zone_1',
    DateTime? lastRequestedAt,
    Duration cooldownDuration = const Duration(hours: 4),
  }) =>
      PoiCooldown(
        zoneId: zoneId,
        lastRequestedAt: lastRequestedAt,
        cooldownDuration: cooldownDuration,
      );

  setUp(() async {
    Hive.init(
      '/tmp/hive_poi_cooldown_test_${DateTime.now().millisecondsSinceEpoch}',
    );
    box = await Hive.openBox('poi_cooldowns_test');
    repo = HivePoiCooldownRepository.withBox(box);
  });

  tearDown(() async {
    await box.close();
  });

  group('HivePoiCooldownRepository', () {
    group('save and load round-trip', () {
      test('saves and loads a cooldown with lastRequestedAt set', () async {
        final cooldown = makeCooldown(lastRequestedAt: baseTime);
        await repo.save(cooldown);

        final loaded = await repo.load('zone_1');
        expect(loaded, isNotNull);
        expect(loaded!.zoneId, 'zone_1');
        expect(loaded.lastRequestedAt, baseTime);
        expect(loaded.cooldownDuration, const Duration(hours: 4));
      });

      test('saves and loads a cooldown with null lastRequestedAt', () async {
        final cooldown = makeCooldown();
        await repo.save(cooldown);

        final loaded = await repo.load('zone_1');
        expect(loaded, isNotNull);
        expect(loaded!.lastRequestedAt, isNull);
      });

      test('saves and loads with custom cooldown duration', () async {
        final cooldown = makeCooldown(
          lastRequestedAt: baseTime,
          cooldownDuration: const Duration(hours: 8),
        );
        await repo.save(cooldown);

        final loaded = await repo.load('zone_1');
        expect(loaded!.cooldownDuration, const Duration(hours: 8));
      });
    });

    group('load', () {
      test('returns null for an unknown zone id', () async {
        final loaded = await repo.load('nonexistent_zone');
        expect(loaded, isNull);
      });

      test('returns null when box is empty', () async {
        final loaded = await repo.load('zone_1');
        expect(loaded, isNull);
      });
    });

    group('overwrite on re-save', () {
      test('overwrites existing cooldown with updated data', () async {
        final original = makeCooldown(lastRequestedAt: baseTime);
        await repo.save(original);

        final newTime = baseTime.add(const Duration(hours: 5));
        final updated = original.recordRequest(newTime);
        await repo.save(updated);

        final loaded = await repo.load('zone_1');
        expect(loaded!.lastRequestedAt, newTime);
      });

      test('overwrites null lastRequestedAt with set value', () async {
        await repo.save(makeCooldown());
        await repo.save(makeCooldown(lastRequestedAt: baseTime));

        final loaded = await repo.load('zone_1');
        expect(loaded!.lastRequestedAt, baseTime);
      });
    });

    group('per-zone isolation', () {
      test('zone_1 cooldown does not affect zone_2', () async {
        final zone1Time = DateTime(2026, 3, 13, 8, 0);
        final zone2Time = DateTime(2026, 3, 13, 10, 0);

        await repo.save(makeCooldown(zoneId: 'zone_1', lastRequestedAt: zone1Time));
        await repo.save(makeCooldown(zoneId: 'zone_2', lastRequestedAt: zone2Time));

        final loaded1 = await repo.load('zone_1');
        final loaded2 = await repo.load('zone_2');

        expect(loaded1!.lastRequestedAt, zone1Time);
        expect(loaded2!.lastRequestedAt, zone2Time);
      });

      test('saving zone_2 does not overwrite zone_1', () async {
        await repo.save(makeCooldown(zoneId: 'zone_1', lastRequestedAt: baseTime));
        await repo.save(
          makeCooldown(
            zoneId: 'zone_2',
            lastRequestedAt: baseTime.add(const Duration(hours: 1)),
          ),
        );

        final loaded1 = await repo.load('zone_1');
        expect(loaded1, isNotNull);
        expect(loaded1!.zoneId, 'zone_1');
        expect(loaded1.lastRequestedAt, baseTime);
      });

      test('loading zone_2 returns null when only zone_1 is saved', () async {
        await repo.save(makeCooldown(zoneId: 'zone_1', lastRequestedAt: baseTime));

        final loaded2 = await repo.load('zone_2');
        expect(loaded2, isNull);
      });

      test('three independent zones are stored and retrieved correctly', () async {
        final t1 = DateTime(2026, 3, 13, 6, 0);
        final t2 = DateTime(2026, 3, 13, 8, 0);
        final t3 = DateTime(2026, 3, 13, 10, 0);

        await repo.save(makeCooldown(zoneId: 'zone_a', lastRequestedAt: t1));
        await repo.save(makeCooldown(zoneId: 'zone_b', lastRequestedAt: t2));
        await repo.save(makeCooldown(zoneId: 'zone_c', lastRequestedAt: t3));

        final a = await repo.load('zone_a');
        final b = await repo.load('zone_b');
        final c = await repo.load('zone_c');

        expect(a!.lastRequestedAt, t1);
        expect(b!.lastRequestedAt, t2);
        expect(c!.lastRequestedAt, t3);
      });
    });

    group('abstract interface', () {
      test('HivePoiCooldownRepository satisfies PoiCooldownRepository contract', () {
        expect(repo, isA<PoiCooldownRepository>());
      });
    });
  });
}
