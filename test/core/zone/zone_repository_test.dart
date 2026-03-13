import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/zone/zone.dart';
import 'package:dander/core/zone/zone_repository.dart';

void main() {
  late Box<dynamic> box;
  late HiveZoneRepository repo;

  final now = DateTime(2026, 3, 13, 12, 0);

  Zone makeZone({
    String id = 'zone_1',
    String name = 'Hackney',
    int xp = 0,
  }) =>
      Zone(
        id: id,
        name: name,
        centre: LatLng(51.5074, -0.1278),
        createdAt: now,
        xp: xp,
      );

  setUp(() async {
    Hive.init('/tmp/hive_zone_test_${DateTime.now().millisecondsSinceEpoch}');
    box = await Hive.openBox('zones_test');
    repo = HiveZoneRepository.withBox(box);
  });

  tearDown(() async {
    await box.close();
  });

  group('HiveZoneRepository', () {
    group('save and load', () {
      test('saves and loads a zone by id', () async {
        final zone = makeZone(xp: 150);
        await repo.save(zone);

        final loaded = await repo.load('zone_1');
        expect(loaded, isNotNull);
        expect(loaded!.id, 'zone_1');
        expect(loaded.name, 'Hackney');
        expect(loaded.xp, 150);
        expect(loaded.centre.latitude, 51.5074);
        expect(loaded.centre.longitude, -0.1278);
      });

      test('returns null for non-existent zone', () async {
        final loaded = await repo.load('nonexistent');
        expect(loaded, isNull);
      });

      test('overwrites existing zone on re-save', () async {
        await repo.save(makeZone(xp: 100));
        await repo.save(makeZone(xp: 200));

        final loaded = await repo.load('zone_1');
        expect(loaded!.xp, 200);
      });
    });

    group('loadAll', () {
      test('returns empty list when no zones', () async {
        final zones = await repo.loadAll();
        expect(zones, isEmpty);
      });

      test('returns all saved zones', () async {
        await repo.save(makeZone(id: 'zone_1', name: 'Hackney'));
        await repo.save(makeZone(id: 'zone_2', name: 'Barcelona'));

        final zones = await repo.loadAll();
        expect(zones, hasLength(2));
        expect(zones.map((z) => z.id).toSet(), {'zone_1', 'zone_2'});
      });
    });

    group('delete', () {
      test('removes a zone by id', () async {
        await repo.save(makeZone());
        await repo.delete('zone_1');

        final loaded = await repo.load('zone_1');
        expect(loaded, isNull);
      });

      test('does not affect other zones', () async {
        await repo.save(makeZone(id: 'zone_1'));
        await repo.save(makeZone(id: 'zone_2', name: 'Barcelona'));
        await repo.delete('zone_1');

        final zones = await repo.loadAll();
        expect(zones, hasLength(1));
        expect(zones.first.id, 'zone_2');
      });

      test('no-ops for non-existent id', () async {
        await repo.delete('nonexistent'); // should not throw
        final zones = await repo.loadAll();
        expect(zones, isEmpty);
      });
    });

    group('data isolation', () {
      test('zones stored independently — no data bleed', () async {
        await repo.save(makeZone(id: 'zone_1', xp: 100));
        await repo.save(makeZone(id: 'zone_2', xp: 500));

        final z1 = await repo.load('zone_1');
        final z2 = await repo.load('zone_2');
        expect(z1!.xp, 100);
        expect(z2!.xp, 500);
      });
    });
  });
}
