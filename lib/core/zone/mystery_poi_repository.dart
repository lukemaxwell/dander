import 'dart:convert';

import 'package:hive/hive.dart';

import 'mystery_poi.dart';

/// Abstract persistence interface for [MysteryPoi] records.
abstract class MysteryPoiRepository {
  /// Saves [pois] for the given [zoneId], replacing any existing entries.
  Future<void> savePois(String zoneId, List<MysteryPoi> pois);

  /// Returns all persisted [MysteryPoi] records for [zoneId].
  Future<List<MysteryPoi>> loadPois(String zoneId);

  /// Deletes all [MysteryPoi] records for [zoneId].
  Future<void> deletePois(String zoneId);
}

/// Hive-backed implementation of [MysteryPoiRepository].
///
/// POI lists are stored as JSON strings keyed by `'mystery_pois_<zoneId>'`
/// within a dedicated 'mystery_pois' box.
class HiveMysteryPoiRepository implements MysteryPoiRepository {
  HiveMysteryPoiRepository({String boxName = 'mystery_pois'})
      : _box = null,
        _boxName = boxName;

  /// Inject an already-open [Box] — used in tests.
  HiveMysteryPoiRepository.withBox(Box<dynamic> box)
      : _box = box,
        _boxName = 'mystery_pois';

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
}
