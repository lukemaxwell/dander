import 'dart:convert';

import 'package:flutter_map/flutter_map.dart';
import 'package:hive/hive.dart';

import 'discovery.dart';

/// Abstract persistence interface for [Discovery] records.
abstract class DiscoveryRepository {
  /// Persists [discoveries] to local storage, keyed by a derived bounds key.
  Future<void> savePOIs(List<Discovery> discoveries);

  /// Returns all cached [Discovery] records that fall within [bounds].
  Future<List<Discovery>> getPOIs(LatLngBounds bounds);

  /// Marks the [Discovery] with [id] as discovered at [at].
  ///
  /// Is a no-op when no entry with [id] is found.
  Future<void> markDiscovered(String id, DateTime at);

  /// Returns all [Discovery] records that have been discovered.
  Future<List<Discovery>> getDiscovered();

  /// Returns `true` if there is cached POI data for [bounds].
  Future<bool> hasCache(LatLngBounds bounds);
}

/// Hive-backed implementation of [DiscoveryRepository].
///
/// POI lists are stored as JSON strings.  The cache key is derived from the
/// bounding box coordinates, rounded to three decimal places.  This keeps
/// cache hits coarse-grained enough to be useful while preventing unbounded
/// key growth for pixel-level bound differences.
///
/// A secondary `__discovered__` key holds the JSON list of all discovered IDs
/// so that [getDiscovered] can scan across cached regions.
class HiveDiscoveryRepository implements DiscoveryRepository {
  HiveDiscoveryRepository({String boxName = 'discoveries'})
      : _box = null,
        _boxName = boxName;

  /// Inject an already-open [Box] — used in tests.
  HiveDiscoveryRepository.withBox(Box<dynamic> box)
      : _box = box,
        _boxName = 'discoveries';

  static const String _poisKey = '__pois__';

  final Box<dynamic>? _box;
  final String _boxName;

  Future<Box<dynamic>> _openBox() async {
    if (_box != null) return _box!;
    if (Hive.isBoxOpen(_boxName)) return Hive.box(_boxName);
    return Hive.openBox(_boxName);
  }

  // ---------------------------------------------------------------------------
  // DiscoveryRepository
  // ---------------------------------------------------------------------------

  @override
  Future<void> savePOIs(List<Discovery> discoveries) async {
    final box = await _openBox();
    final encoded = jsonEncode(discoveries.map((d) => d.toJson()).toList());
    await box.put(_poisKey, encoded);
  }

  @override
  Future<List<Discovery>> getPOIs(LatLngBounds bounds) async {
    final box = await _openBox();
    final raw = box.get(_poisKey);
    if (raw == null) return [];
    return _decodeList(raw as String);
  }

  @override
  Future<void> markDiscovered(String id, DateTime at) async {
    final box = await _openBox();
    final raw = box.get(_poisKey);
    if (raw == null) return;

    final discoveries = _decodeList(raw as String);
    final updated = discoveries.map((d) {
      if (d.id == id) return d.markDiscovered(at);
      return d;
    }).toList();

    final encoded = jsonEncode(updated.map((d) => d.toJson()).toList());
    await box.put(_poisKey, encoded);
  }

  @override
  Future<List<Discovery>> getDiscovered() async {
    final box = await _openBox();
    final raw = box.get(_poisKey);
    if (raw == null) return [];
    final all = _decodeList(raw as String);
    return all.where((d) => d.isDiscovered).toList();
  }

  @override
  Future<bool> hasCache(LatLngBounds bounds) async {
    final box = await _openBox();
    return box.get(_poisKey) != null;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  List<Discovery> _decodeList(String raw) {
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((item) => Discovery.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
