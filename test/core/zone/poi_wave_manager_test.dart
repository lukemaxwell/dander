import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/zone/mystery_poi.dart';
import 'package:dander/core/zone/poi_wave_manager.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

MysteryPoi makePoi({
  String id = 'poi_1',
  PoiState state = PoiState.unrevealed,
}) =>
    MysteryPoi(
      id: id,
      position: LatLng(51.5, -0.1),
      category: 'pub',
      state: state,
    );

List<MysteryPoi> makePoiList(int count, {int revealedCount = 0}) {
  return List.generate(count, (i) {
    final isRevealed = i < revealedCount;
    return makePoi(
      id: 'poi_$i',
      state: isRevealed ? PoiState.revealed : PoiState.unrevealed,
    );
  });
}

void main() {
  // ---------------------------------------------------------------------------
  // Constants
  // ---------------------------------------------------------------------------

  group('constants', () {
    test('wave1Size is 8', () {
      expect(PoiWaveManager.wave1Size, 8);
    });

    test('wave2Size is 6', () {
      expect(PoiWaveManager.wave2Size, 6);
    });

    test('unlock threshold is 50 percent', () {
      expect(PoiWaveManager.unlockThresholdPercent, 0.5);
    });
  });

  // ---------------------------------------------------------------------------
  // activeForWave
  // ---------------------------------------------------------------------------

  group('activeForWave', () {
    test('wave 1 returns first 8 POIs from allPois', () {
      final all = makePoiList(20);
      final active = PoiWaveManager.activeForWave(all, 1);

      expect(active, hasLength(8));
      expect(active.map((p) => p.id).toList(), [
        'poi_0', 'poi_1', 'poi_2', 'poi_3',
        'poi_4', 'poi_5', 'poi_6', 'poi_7',
      ]);
    });

    test('wave 2 returns first 14 POIs (wave1 + wave2 cumulative)', () {
      final all = makePoiList(20);
      final active = PoiWaveManager.activeForWave(all, 2);

      expect(active, hasLength(14));
      expect(active.first.id, 'poi_0');
      expect(active.last.id, 'poi_13');
    });

    test('wave 3 returns all POIs', () {
      final all = makePoiList(20);
      final active = PoiWaveManager.activeForWave(all, 3);

      expect(active, hasLength(20));
      expect(active.first.id, 'poi_0');
      expect(active.last.id, 'poi_19');
    });

    test('wave 3 with fewer than full budget returns all available', () {
      final all = makePoiList(12);
      final active = PoiWaveManager.activeForWave(all, 3);

      expect(active, hasLength(12));
    });

    test('wave 1 with fewer than wave1Size pois returns all available', () {
      final all = makePoiList(5);
      final active = PoiWaveManager.activeForWave(all, 1);

      expect(active, hasLength(5));
    });

    test('wave 2 with only wave1Size pois returns all (no wave2 items)', () {
      final all = makePoiList(8);
      final active = PoiWaveManager.activeForWave(all, 2);

      // wave1Size = 8, wave2 start = 8, no more items → still 8
      expect(active, hasLength(8));
    });

    test('returns empty list when allPois is empty', () {
      final active = PoiWaveManager.activeForWave([], 1);

      expect(active, isEmpty);
    });

    test('wave number above 3 returns all POIs', () {
      final all = makePoiList(20);
      final active = PoiWaveManager.activeForWave(all, 99);

      expect(active, hasLength(20));
    });

    test('wave 1 does not mutate original list', () {
      final all = makePoiList(20);
      final original = List<MysteryPoi>.from(all);

      PoiWaveManager.activeForWave(all, 1);

      expect(all.length, original.length);
      expect(all.map((p) => p.id).toList(),
          original.map((p) => p.id).toList());
    });
  });

  // ---------------------------------------------------------------------------
  // checkWaveUnlock
  // ---------------------------------------------------------------------------

  group('checkWaveUnlock', () {
    test('no unlock when discovered count is below 50% of wave1', () {
      // wave1Size = 8, threshold = 50% = 4; discoveredInWave = 3 → no unlock
      final newWave = PoiWaveManager.checkWaveUnlock(1, 3, 8);

      expect(newWave, 1);
    });

    test('unlocks to wave 2 when 50% of wave 1 is discovered', () {
      // 4 out of 8 = 50% → unlock
      final newWave = PoiWaveManager.checkWaveUnlock(1, 4, 8);

      expect(newWave, 2);
    });

    test('unlocks to wave 2 when more than 50% of wave 1 is discovered', () {
      final newWave = PoiWaveManager.checkWaveUnlock(1, 6, 8);

      expect(newWave, 2);
    });

    test('unlocks to wave 3 when 50% of wave 2 is discovered', () {
      // wave2Size = 6, threshold = 3 → unlock
      final newWave = PoiWaveManager.checkWaveUnlock(2, 3, 6);

      expect(newWave, 3);
    });

    test('no unlock when on wave 3 (final wave)', () {
      final newWave = PoiWaveManager.checkWaveUnlock(3, 99, 5);

      expect(newWave, 3);
    });

    test('no unlock when waveSize is 0', () {
      final newWave = PoiWaveManager.checkWaveUnlock(1, 0, 0);

      expect(newWave, 1);
    });

    test('no unlock when discoveredInWave is 0 regardless of waveSize', () {
      final newWave = PoiWaveManager.checkWaveUnlock(1, 0, 8);

      expect(newWave, 1);
    });

    test('exactly at 50% threshold triggers unlock', () {
      // 1 discovered out of 2 in wave = 50% exactly
      final newWave = PoiWaveManager.checkWaveUnlock(1, 1, 2);

      expect(newWave, 2);
    });

    test('one below 50% does not unlock', () {
      // 3 out of 8 = 37.5% → no unlock
      final newWave = PoiWaveManager.checkWaveUnlock(1, 3, 8);

      expect(newWave, 1);
    });

    test('wave unlock is bounded at 3 (does not go beyond)', () {
      // From wave 2 with full discovery
      final newWave = PoiWaveManager.checkWaveUnlock(2, 6, 6);

      expect(newWave, 3);
    });
  });

  // ---------------------------------------------------------------------------
  // waveSize helper
  // ---------------------------------------------------------------------------

  group('waveSize', () {
    test('wave 1 size is wave1Size constant', () {
      expect(PoiWaveManager.waveSize(1), PoiWaveManager.wave1Size);
    });

    test('wave 2 size is wave2Size constant', () {
      expect(PoiWaveManager.waveSize(2), PoiWaveManager.wave2Size);
    });

    test('wave 3 size is maxInt (remainder)', () {
      // Wave 3 includes everything after wave1+wave2
      expect(PoiWaveManager.waveSize(3), greaterThan(1000));
    });
  });
}
