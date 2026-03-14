import 'dart:convert';

import 'package:hive/hive.dart';

import '../storage/hive_boxes.dart';
import 'mystery_poi.dart';

/// Immutable record of wave progression state for a zone.
class WaveState {
  const WaveState({
    required this.currentWave,
    required this.discoveredInWave,
  });

  /// The wave number currently active (1, 2, or 3).
  final int currentWave;

  /// Number of POIs discovered within [currentWave] since it unlocked.
  final int discoveredInWave;
}

/// Abstract persistence interface for [MysteryPoi] records.
abstract class MysteryPoiRepository {
  /// Saves [pois] for the given [zoneId], replacing any existing entries.
  Future<void> savePois(String zoneId, List<MysteryPoi> pois);

  /// Returns all persisted [MysteryPoi] records for [zoneId].
  Future<List<MysteryPoi>> loadPois(String zoneId);

  /// Deletes all [MysteryPoi] records for [zoneId].
  Future<void> deletePois(String zoneId);

  /// Persists the total POI count for [zoneId] (before capping).
  Future<void> saveTotalCount(String zoneId, int count);

  /// Returns the persisted total POI count for [zoneId], or `null` if none.
  Future<int?> loadTotalCount(String zoneId);

  /// Persists the wave progression state for [zoneId].
  Future<void> saveWaveState(
    String zoneId,
    int currentWave,
    int discoveredInWave,
  );

  /// Returns the persisted wave state for [zoneId], or `null` if none saved.
  Future<WaveState?> loadWaveState(String zoneId);
}

/// Hive-backed implementation of [MysteryPoiRepository].
///
/// POI lists are stored as JSON strings keyed by `'mystery_pois_<zoneId>'`
/// within a dedicated 'mystery_pois' box.
class HiveMysteryPoiRepository implements MysteryPoiRepository {
  HiveMysteryPoiRepository({String boxName = HiveBoxes.mysteryPois})
      : _box = null,
        _boxName = boxName;

  /// Inject an already-open [Box] — used in tests.
  HiveMysteryPoiRepository.withBox(Box<dynamic> box)
      : _box = box,
        _boxName = HiveBoxes.mysteryPois;

  final Box<dynamic>? _box;
  final String _boxName;

  Future<Box<dynamic>> _openBox() async {
    if (_box != null) return _box!;
    if (Hive.isBoxOpen(_boxName)) return Hive.box(_boxName);
    return Hive.openBox(_boxName);
  }

  String _key(String zoneId) => 'mystery_pois_$zoneId';

  @override
  Future<void> savePois(String zoneId, List<MysteryPoi> pois) async {
    final box = await _openBox();
    final encoded = jsonEncode(pois.map((p) => p.toJson()).toList());
    await box.put(_key(zoneId), encoded);
  }

  @override
  Future<List<MysteryPoi>> loadPois(String zoneId) async {
    final box = await _openBox();
    final raw = box.get(_key(zoneId));
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw as String) as List<dynamic>;
      return list
          .map((item) => MysteryPoi.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> deletePois(String zoneId) async {
    final box = await _openBox();
    await box.delete(_key(zoneId));
  }

  String _countKey(String zoneId) => 'mystery_pois_count_$zoneId';

  @override
  Future<void> saveTotalCount(String zoneId, int count) async {
    final box = await _openBox();
    await box.put(_countKey(zoneId), count);
  }

  @override
  Future<int?> loadTotalCount(String zoneId) async {
    final box = await _openBox();
    final raw = box.get(_countKey(zoneId));
    if (raw == null) return null;
    return raw as int;
  }

  String _waveKey(String zoneId) => 'mystery_pois_wave_$zoneId';

  @override
  Future<void> saveWaveState(
    String zoneId,
    int currentWave,
    int discoveredInWave,
  ) async {
    final box = await _openBox();
    await box.put(_waveKey(zoneId), '$currentWave,$discoveredInWave');
  }

  @override
  Future<WaveState?> loadWaveState(String zoneId) async {
    final box = await _openBox();
    final raw = box.get(_waveKey(zoneId));
    if (raw == null) return null;
    try {
      final parts = (raw as String).split(',');
      return WaveState(
        currentWave: int.parse(parts[0]),
        discoveredInWave: int.parse(parts[1]),
      );
    } catch (_) {
      return null;
    }
  }
}
