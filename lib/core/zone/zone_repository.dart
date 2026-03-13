import 'dart:convert';

import 'package:hive/hive.dart';

import 'zone.dart';

/// Abstract interface for persisting zone data.
abstract class ZoneRepository {
  /// Saves a zone (creates or updates).
  Future<void> save(Zone zone);

  /// Loads a zone by its [id], or returns `null` if not found.
  Future<Zone?> load(String id);

  /// Returns all persisted zones.
  Future<List<Zone>> loadAll();

  /// Deletes a zone by its [id].
  Future<void> delete(String id);
}

/// Hive-backed implementation of [ZoneRepository].
///
/// Each zone is stored as a JSON string keyed by its [Zone.id].
class HiveZoneRepository implements ZoneRepository {
  HiveZoneRepository({String boxName = 'zones'})
      : _box = null,
        _boxName = boxName;

  /// Constructor that injects an already-open [Box] — used in tests.
  HiveZoneRepository.withBox(Box<dynamic> box)
      : _box = box,
        _boxName = 'zones';

  final Box<dynamic>? _box;
  final String _boxName;

  Future<Box<dynamic>> _openBox() async {
    if (_box != null) return _box!;
    if (Hive.isBoxOpen(_boxName)) return Hive.box(_boxName);
    return Hive.openBox(_boxName);
  }

  @override
  Future<void> save(Zone zone) async {
    final box = await _openBox();
    final encoded = jsonEncode(zone.toJson());
    await box.put(zone.id, encoded);
  }

  @override
  Future<Zone?> load(String id) async {
    final box = await _openBox();
    final raw = box.get(id);
    if (raw == null) return null;

    try {
      final map = jsonDecode(raw as String) as Map<String, dynamic>;
      return Zone.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Zone>> loadAll() async {
    final box = await _openBox();
    final zones = <Zone>[];
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw == null) continue;
      try {
        final map = jsonDecode(raw as String) as Map<String, dynamic>;
        zones.add(Zone.fromJson(map));
      } catch (_) {
        // Skip corrupted entries.
      }
    }
    return zones;
  }

  @override
  Future<void> delete(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }
}
