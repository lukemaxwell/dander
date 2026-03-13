import 'dart:convert';

import 'package:flutter_map/flutter_map.dart';
import 'package:hive/hive.dart';

import 'discovery.dart';

/// Abstract persistence interface for [Discovery] records.
abstract class DiscoveryRepository {
  /// Persists [discoveries] to local storage, keyed by [bounds].
  Future<void> savePOIs(List<Discovery> discoveries, LatLngBounds bounds);

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
/// POI lists are stored as JSON strings under a key derived from the
/// bounding box coordinates, rounded to three decimal places.  This keeps
/// cache hits coarse-grained enough to be useful while preventing unbounded
/// key growth for pixel-level bound differences.
///
/// All bounds-derived keys share the prefix 'pois_'.
///
/// A secondary [_discoveredKey] stores a JSON list of all discovered POI IDs.
/// [markDiscovered] appends to this list; [getDiscovered] scans every 'pois_'
/// key and returns POIs whose IDs appear in the discovered-IDs list.
class HiveDiscoveryRepository implements DiscoveryRepository {
  HiveDiscoveryRepository({String boxName = 'discoveries'})
      : _box = null,
        _boxName = boxName;

  /// Inject an already-open [Box] — used in tests.
  HiveDiscoveryRepository.withBox(Box<dynamic> box)
      : _box = box,
        _boxName = 'discoveries';

  /// Key used to persist the set of all discovered POI IDs.
  static const String _discoveredKey = '__discovered__';

  final Box<dynamic>? _box;
  final String _boxName;

  Future<Box<dynamic>> _openBox() async {
    if (_box != null) return _box!;
    if (Hive.isBoxOpen(_boxName)) return Hive.box(_boxName);
    return Hive.openBox(_boxName);
  }

  /// Derives a stable Hive key from [bounds] coordinates rounded to 3 d.p.
  String _boundsKey(LatLngBounds bounds) {
    final s = bounds.south.toStringAsFixed(3);
    final w = bounds.west.toStringAsFixed(3);
    final n = bounds.north.toStringAsFixed(3);
    final e = bounds.east.toStringAsFixed(3);
    return 'pois_${s}_${w}_${n}_${e}';
  }

  // ---------------------------------------------------------------------------
  // DiscoveryRepository
  // ---------------------------------------------------------------------------

  @override
  Future<void> savePOIs(
    List<Discovery> discoveries,
    LatLngBounds bounds,
  ) async {
    final box = await _openBox();
    final key = _boundsKey(bounds);
    final encoded = jsonEncode(discoveries.map((d) => d.toJson()).toList());
    await box.put(key, encoded);
  }

  @override
  Future<List<Discovery>> getPOIs(LatLngBounds bounds) async {
    final box = await _openBox();
    final key = _boundsKey(bounds);
    final raw = box.get(key);
    if (raw == null) return [];
    return _decodeList(raw as String);
  }

  @override
  Future<void> markDiscovered(String id, DateTime at) async {
    final box = await _openBox();

    final rawIds = box.get(_discoveredKey);
    final discoveredIds = rawIds != null
        ? (jsonDecode(rawIds as String) as List<dynamic>)
            .map((e) => e as String)
            .toSet()
        : <String>{};

    if (discoveredIds.contains(id)) return;
    discoveredIds.add(id);

    await box.put(_discoveredKey, jsonEncode(discoveredIds.toList()));
  }

  @override
  Future<List<Discovery>> getDiscovered() async {
    final box = await _openBox();

    final rawIds = box.get(_discoveredKey);
    if (rawIds == null) return [];
    final discoveredIds = (jsonDecode(rawIds as String) as List<dynamic>)
        .map((e) => e as String)
        .toSet();
    if (discoveredIds.isEmpty) return [];

    // Scan all bounds-keyed entries and collect matching POIs.
    final result = <Discovery>[];
    for (final key in box.keys) {
      final keyStr = key as String;
      if (!keyStr.startsWith('pois_')) continue;
      final raw = box.get(keyStr);
      if (raw == null) continue;
      final pois = _decodeList(raw as String);
      result.addAll(pois.where((d) => discoveredIds.contains(d.id)));
    }
    return result;
  }

  @override
  Future<bool> hasCache(LatLngBounds bounds) async {
    final box = await _openBox();
    return box.get(_boundsKey(bounds)) != null;
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
