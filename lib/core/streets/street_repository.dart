import 'dart:convert';

import 'package:flutter_map/flutter_map.dart';
import 'package:hive/hive.dart';

import 'street.dart';

/// Abstract persistence interface for [Street] records.
abstract class StreetRepository {
  /// Persists [streets] to local storage, keyed by [bounds].
  Future<void> saveStreets(List<Street> streets, LatLngBounds bounds);

  /// Returns all cached [Street] records stored under [bounds].
  Future<List<Street>> getStreets(LatLngBounds bounds);

  /// Marks the street with [streetId] as walked at [walkedAt].
  Future<void> markWalked(String streetId, DateTime walkedAt);

  /// Returns all [Street] records that have been walked, with [walkedAt] set.
  Future<List<Street>> getWalkedStreets();

  /// Returns `true` if there is cached street data for [bounds].
  Future<bool> hasCache(LatLngBounds bounds);
}

/// Hive-backed implementation of [StreetRepository].
///
/// Street lists are stored as JSON strings under a key derived from the
/// bounding box coordinates, rounded to three decimal places.
///
/// All bounds-derived keys share the prefix `streets_`.
///
/// A secondary [_walkedKey] stores a JSON map of street ID → ISO 8601
/// timestamp for all walked streets. [getWalkedStreets] scans every
/// `streets_`-prefixed key and merges the walked timestamps into the results.
class HiveStreetRepository implements StreetRepository {
  HiveStreetRepository({String boxName = 'streets'})
      : _box = null,
        _boxName = boxName;

  /// Inject an already-open [Box] — used in tests.
  HiveStreetRepository.withBox(Box<dynamic> box)
      : _box = box,
        _boxName = 'streets';

  /// Key used to persist the map of walked street IDs → ISO timestamps.
  static const String _walkedKey = '__walked__';

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
    return 'streets_${s}_${w}_${n}_$e';
  }

  // ---------------------------------------------------------------------------
  // StreetRepository
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveStreets(
    List<Street> streets,
    LatLngBounds bounds,
  ) async {
    final box = await _openBox();
    final key = _boundsKey(bounds);
    final encoded = jsonEncode(streets.map((s) => s.toJson()).toList());
    await box.put(key, encoded);
  }

  @override
  Future<List<Street>> getStreets(LatLngBounds bounds) async {
    final box = await _openBox();
    final key = _boundsKey(bounds);
    final raw = box.get(key);
    if (raw == null) return [];
    return _decodeList(raw as String);
  }

  @override
  Future<void> markWalked(String streetId, DateTime walkedAt) async {
    final box = await _openBox();
    final rawWalked = box.get(_walkedKey);
    final walkedMap = rawWalked != null
        ? Map<String, String>.from(
            jsonDecode(rawWalked as String) as Map<String, dynamic>,
          )
        : <String, String>{};

    walkedMap[streetId] = walkedAt.toIso8601String();
    await box.put(_walkedKey, jsonEncode(walkedMap));
  }

  @override
  Future<List<Street>> getWalkedStreets() async {
    final box = await _openBox();
    final rawWalked = box.get(_walkedKey);
    if (rawWalked == null) return [];
    final walkedMap = Map<String, String>.from(
      jsonDecode(rawWalked as String) as Map<String, dynamic>,
    );
    if (walkedMap.isEmpty) return [];

    // Scan all bounds-keyed entries and collect matching streets.
    final result = <Street>[];
    for (final key in box.keys) {
      final keyStr = key as String;
      if (!keyStr.startsWith('streets_')) continue;
      final raw = box.get(keyStr);
      if (raw == null) continue;
      final streets = _decodeList(raw as String);
      for (final street in streets) {
        if (walkedMap.containsKey(street.id)) {
          final ts = DateTime.parse(walkedMap[street.id]!);
          result.add(street.markWalked(ts));
        }
      }
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

  List<Street> _decodeList(String raw) {
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((item) => Street.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
