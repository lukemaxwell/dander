import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/zone/mystery_poi.dart';
import 'package:dander/core/zone/mystery_poi_repository.dart';

void main() {
  late Box<dynamic> box;
  late HiveMysteryPoiRepository repo;

  MysteryPoi makePoi({
    String id = 'poi_1',
    double lat = 51.5074,
    double lng = -0.1278,
    String category = 'pub',
    String? name,
    PoiState state = PoiState.unrevealed,
  }) =>
      MysteryPoi(
        id: id,
        position: LatLng(lat, lng),
        category: category,
        name: name,
        state: state,
      );

  setUp(() async {
    Hive.init(
      '/tmp/hive_mystery_poi_test_${DateTime.now().millisecondsSinceEpoch}',
    );
    box = await Hive.openBox('mystery_pois_test');
    repo = HiveMysteryPoiRepository.withBox(box);
  });

  tearDown(() async {
    await box.close();
  });

  // ---------------------------------------------------------------------------
  // savePois / loadPois
  // ---------------------------------------------------------------------------

  group('savePois and loadPois', () {
    test('saves and loads pois for a zone', () async {
      final pois = [makePoi(id: 'poi_1'), makePoi(id: 'poi_2')];
      await repo.savePois('zone_1', pois);

      final loaded = await repo.loadPois('zone_1');
      expect(loaded, hasLength(2));
      expect(loaded.map((p) => p.id).toSet(), {'poi_1', 'poi_2'});
    });

    test('returns empty list when no pois saved for zone', () async {
      final loaded = await repo.loadPois('zone_unknown');
      expect(loaded, isEmpty);
    });

    test('overwrites existing pois for same zone on re-save', () async {
      final first = [makePoi(id: 'poi_1'), makePoi(id: 'poi_2')];
      final second = [makePoi(id: 'poi_3')];

      await repo.savePois('zone_1', first);
      await repo.savePois('zone_1', second);

      final loaded = await repo.loadPois('zone_1');
      expect(loaded, hasLength(1));
      expect(loaded.first.id, 'poi_3');
    });

    test('preserves revealed state across save/load', () async {
      final pois = [makePoi(id: 'poi_1', name: 'The Crown', state: PoiState.revealed)];
      await repo.savePois('zone_1', pois);

      final loaded = await repo.loadPois('zone_1');
      expect(loaded.first.isRevealed, isTrue);
      expect(loaded.first.name, 'The Crown');
    });

    test('preserves unrevealed state across save/load', () async {
      final pois = [makePoi(id: 'poi_1', name: null)];
      await repo.savePois('zone_1', pois);

      final loaded = await repo.loadPois('zone_1');
      expect(loaded.first.isRevealed, isFalse);
      expect(loaded.first.name, isNull);
    });

    test('preserves position accurately', () async {
      final pois = [makePoi(lat: 48.8566, lng: 2.3522)];
      await repo.savePois('zone_1', pois);

      final loaded = await repo.loadPois('zone_1');
      expect(loaded.first.position.latitude, closeTo(48.8566, 0.00001));
      expect(loaded.first.position.longitude, closeTo(2.3522, 0.00001));
    });

    test('preserves category', () async {
      final pois = [makePoi(category: 'historic')];
      await repo.savePois('zone_1', pois);

      final loaded = await repo.loadPois('zone_1');
      expect(loaded.first.category, 'historic');
    });

    test('saves empty list successfully', () async {
      await repo.savePois('zone_1', []);

      final loaded = await repo.loadPois('zone_1');
      expect(loaded, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // deletePois
  // ---------------------------------------------------------------------------

  group('deletePois', () {
    test('removes all pois for a zone', () async {
      final pois = [makePoi(id: 'poi_1'), makePoi(id: 'poi_2')];
      await repo.savePois('zone_1', pois);

      await repo.deletePois('zone_1');

      final loaded = await repo.loadPois('zone_1');
      expect(loaded, isEmpty);
    });

    test('does not affect pois for other zones', () async {
      await repo.savePois('zone_1', [makePoi(id: 'poi_1')]);
      await repo.savePois('zone_2', [makePoi(id: 'poi_2')]);

      await repo.deletePois('zone_1');

      final zone2Pois = await repo.loadPois('zone_2');
      expect(zone2Pois, hasLength(1));
      expect(zone2Pois.first.id, 'poi_2');
    });

    test('no-op for non-existent zone (no throw)', () async {
      await expectLater(
        repo.deletePois('nonexistent'),
        completes,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Zone isolation
  // ---------------------------------------------------------------------------

  group('zone isolation', () {
    test('pois for different zones are stored independently', () async {
      final zone1Pois = [makePoi(id: 'poi_a', category: 'pub')];
      final zone2Pois = [
        makePoi(id: 'poi_b', category: 'park'),
        makePoi(id: 'poi_c', category: 'cafe'),
      ];

      await repo.savePois('zone_1', zone1Pois);
      await repo.savePois('zone_2', zone2Pois);

      final loaded1 = await repo.loadPois('zone_1');
      final loaded2 = await repo.loadPois('zone_2');

      expect(loaded1, hasLength(1));
      expect(loaded2, hasLength(2));
      expect(loaded1.first.id, 'poi_a');
      expect(loaded2.map((p) => p.id).toSet(), {'poi_b', 'poi_c'});
    });

    test('deleting zone_1 does not delete zone_2 pois', () async {
      await repo.savePois('zone_1', [makePoi(id: 'poi_1')]);
      await repo.savePois('zone_2', [makePoi(id: 'poi_2')]);

      await repo.deletePois('zone_1');

      expect(await repo.loadPois('zone_1'), isEmpty);
      expect(await repo.loadPois('zone_2'), hasLength(1));
    });
  });

  // ---------------------------------------------------------------------------
  // saveTotalCount / loadTotalCount
  // ---------------------------------------------------------------------------

  group('saveTotalCount and loadTotalCount', () {
    test('saves and loads total count for a zone', () async {
      await repo.saveTotalCount('zone_1', 42);
      final count = await repo.loadTotalCount('zone_1');
      expect(count, 42);
    });

    test('returns null when no count saved', () async {
      final count = await repo.loadTotalCount('zone_unknown');
      expect(count, isNull);
    });

    test('overwrites existing count', () async {
      await repo.saveTotalCount('zone_1', 42);
      await repo.saveTotalCount('zone_1', 99);
      final count = await repo.loadTotalCount('zone_1');
      expect(count, 99);
    });

    test('counts for different zones are independent', () async {
      await repo.saveTotalCount('zone_1', 10);
      await repo.saveTotalCount('zone_2', 20);
      expect(await repo.loadTotalCount('zone_1'), 10);
      expect(await repo.loadTotalCount('zone_2'), 20);
    });
  });

  // ---------------------------------------------------------------------------
  // saveWaveState / loadWaveState
  // ---------------------------------------------------------------------------

  group('saveWaveState and loadWaveState', () {
    test('saves and loads wave state for a zone', () async {
      await repo.saveWaveState('zone_1', 1, 3);
      final state = await repo.loadWaveState('zone_1');
      expect(state, isNotNull);
      expect(state!.currentWave, 1);
      expect(state.discoveredInWave, 3);
    });

    test('returns null when no wave state saved', () async {
      final state = await repo.loadWaveState('zone_unknown');
      expect(state, isNull);
    });

    test('overwrites existing wave state', () async {
      await repo.saveWaveState('zone_1', 1, 2);
      await repo.saveWaveState('zone_1', 2, 0);
      final state = await repo.loadWaveState('zone_1');
      expect(state!.currentWave, 2);
      expect(state.discoveredInWave, 0);
    });

    test('wave states for different zones are independent', () async {
      await repo.saveWaveState('zone_1', 1, 4);
      await repo.saveWaveState('zone_2', 2, 1);

      final state1 = await repo.loadWaveState('zone_1');
      final state2 = await repo.loadWaveState('zone_2');

      expect(state1!.currentWave, 1);
      expect(state1.discoveredInWave, 4);
      expect(state2!.currentWave, 2);
      expect(state2.discoveredInWave, 1);
    });

    test('wave state survives currentWave = 3 (final wave)', () async {
      await repo.saveWaveState('zone_1', 3, 0);
      final state = await repo.loadWaveState('zone_1');
      expect(state!.currentWave, 3);
      expect(state.discoveredInWave, 0);
    });

    test('wave state with discoveredInWave = 0 is preserved', () async {
      await repo.saveWaveState('zone_1', 1, 0);
      final state = await repo.loadWaveState('zone_1');
      expect(state!.discoveredInWave, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // Data integrity
  // ---------------------------------------------------------------------------

  group('data integrity', () {
    test('loading corrupted data returns empty list (graceful degradation)', () async {
      // Manually write corrupt data into the box
      await box.put('mystery_pois_zone_corrupt', 'not-valid-json{{{');

      final loaded = await repo.loadPois('zone_corrupt');
      expect(loaded, isEmpty);
    });

    test('round-trips all valid category values', () async {
      const categories = ['pub', 'park', 'historic', 'street_art', 'viewpoint', 'cafe', 'library'];
      final pois = categories
          .asMap()
          .entries
          .map((e) => makePoi(id: 'poi_${e.key}', category: e.value))
          .toList();

      await repo.savePois('zone_1', pois);

      final loaded = await repo.loadPois('zone_1');
      expect(loaded.map((p) => p.category).toSet(), categories.toSet());
    });
  });
}
