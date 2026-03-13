import 'dart:convert';

import 'package:hive/hive.dart';

import 'walk_session.dart';

/// Abstract walk-persistence interface.
abstract class WalkRepository {
  /// Saves [session] to persistent storage, overwriting any existing record
  /// with the same [WalkSession.id].
  Future<void> saveWalk(WalkSession session);

  /// Returns all stored walks.  The list may be in any order.
  Future<List<WalkSession>> getWalks();

  /// Returns the walk with [id], or `null` if not found.
  Future<WalkSession?> getWalk(String id);
}

/// Hive-backed implementation of [WalkRepository].
///
/// Each [WalkSession] is stored as a JSON string under its own key.  A
/// secondary `__index__` key holds a JSON-encoded `List<String>` of all
/// stored walk ids, allowing [getWalks] to enumerate them without scanning
/// the entire box.
///
/// Corrupted entries are silently skipped by [getWalks]; callers should
/// assume the returned list may be shorter than the index in degraded states.
class HiveWalkRepository implements WalkRepository {
  HiveWalkRepository({String boxName = 'walks'})
      : _box = null,
        _boxName = boxName;

  /// Inject an already-open [Box] — used in tests.
  HiveWalkRepository.withBox(Box<dynamic> box)
      : _box = box,
        _boxName = 'walks';

  static const String _indexKey = '__index__';

  final Box<dynamic>? _box;
  final String _boxName;

  Future<Box<dynamic>> _openBox() async {
    if (_box != null) return _box!;
    if (Hive.isBoxOpen(_boxName)) return Hive.box(_boxName);
    return Hive.openBox(_boxName);
  }

  @override
  Future<void> saveWalk(WalkSession session) async {
    final box = await _openBox();
    final encoded = jsonEncode(session.toJson());
    await box.put(session.id, encoded);
    await _updateIndex(box, session.id);
  }

  @override
  Future<WalkSession?> getWalk(String id) async {
    final box = await _openBox();
    final raw = box.get(id);
    if (raw == null) return null;
    return _decode(raw as String);
  }

  @override
  Future<List<WalkSession>> getWalks() async {
    final box = await _openBox();
    final ids = _readIndex(box);
    final results = <WalkSession>[];
    for (final id in ids) {
      final raw = box.get(id);
      if (raw == null) continue;
      final session = _decode(raw as String);
      if (session != null) results.add(session);
    }
    return results;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<void> _updateIndex(Box<dynamic> box, String id) async {
    final ids = _readIndex(box);
    if (!ids.contains(id)) {
      final updated = [...ids, id];
      await box.put(_indexKey, jsonEncode(updated));
    }
  }

  List<String> _readIndex(Box<dynamic> box) {
    final raw = box.get(_indexKey);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw as String) as List<dynamic>;
      return decoded.cast<String>();
    } catch (_) {
      return [];
    }
  }

  WalkSession? _decode(String raw) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return WalkSession.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}
