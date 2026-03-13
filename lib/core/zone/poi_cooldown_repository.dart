import 'dart:convert';

import 'package:hive/hive.dart';

import '../storage/hive_boxes.dart';
import 'poi_cooldown.dart';

/// Abstract interface for persisting [PoiCooldown] data.
abstract class PoiCooldownRepository {
  /// Saves a cooldown record (creates or updates by [PoiCooldown.zoneId]).
  Future<void> save(PoiCooldown cooldown);

  /// Loads the cooldown for [zoneId], or returns `null` if not found.
  Future<PoiCooldown?> load(String zoneId);
}

/// Hive-backed implementation of [PoiCooldownRepository].
///
/// Each cooldown is stored as a JSON string keyed by `'cooldown_$zoneId'`.
class HivePoiCooldownRepository implements PoiCooldownRepository {
  HivePoiCooldownRepository({String boxName = HiveBoxes.poiCooldowns})
      : _box = null,
        _boxName = boxName;

  /// Constructor that injects an already-open [Box] — used in tests.
  HivePoiCooldownRepository.withBox(Box<dynamic> box)
      : _box = box,
        _boxName = HiveBoxes.poiCooldowns;

  final Box<dynamic>? _box;
  final String _boxName;

  Future<Box<dynamic>> _openBox() async {
    if (_box != null) return _box!;
    if (Hive.isBoxOpen(_boxName)) return Hive.box(_boxName);
    return Hive.openBox(_boxName);
  }

  String _key(String zoneId) => 'cooldown_$zoneId';

  @override
  Future<void> save(PoiCooldown cooldown) async {
    final box = await _openBox();
    final encoded = jsonEncode(cooldown.toJson());
    await box.put(_key(cooldown.zoneId), encoded);
  }

  @override
  Future<PoiCooldown?> load(String zoneId) async {
    final box = await _openBox();
    final raw = box.get(_key(zoneId));
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw as String) as Map<String, dynamic>;
      return PoiCooldown.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}
