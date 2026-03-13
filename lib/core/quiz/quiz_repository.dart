import 'dart:convert';

import 'package:hive/hive.dart';

import 'street_memory_record.dart';

/// Abstract interface for persisting quiz memory records.
abstract class QuizRepository {
  /// Persists [record], overwriting any existing entry for the same street.
  Future<void> saveRecord(StreetMemoryRecord record);

  /// Returns all persisted [StreetMemoryRecord]s.
  Future<List<StreetMemoryRecord>> getAllRecords();

  /// Returns the record for [streetId], or `null` if none exists.
  Future<StreetMemoryRecord?> getRecord(String streetId);

  /// Creates an initial record for [streetId] if one does not already exist.
  ///
  /// Has no effect when a record already exists for [streetId].
  Future<void> ensureRecord(String streetId);
}

/// Hive-backed implementation of [QuizRepository].
///
/// Each record is stored as a JSON string keyed by [StreetMemoryRecord.streetId].
class HiveQuizRepository implements QuizRepository {
  HiveQuizRepository({String boxName = 'quiz'})
      : _box = null,
        _boxName = boxName;

  /// Injects an already-open [Box] — used in tests.
  HiveQuizRepository.withBox(Box<dynamic> box)
      : _box = box,
        _boxName = 'quiz';

  final Box<dynamic>? _box;
  final String _boxName;

  Future<Box<dynamic>> _openBox() async {
    if (_box != null) return _box!;
    if (Hive.isBoxOpen(_boxName)) return Hive.box(_boxName);
    return Hive.openBox(_boxName);
  }

  @override
  Future<void> saveRecord(StreetMemoryRecord record) async {
    final box = await _openBox();
    await box.put(record.streetId, jsonEncode(record.toJson()));
  }

  @override
  Future<List<StreetMemoryRecord>> getAllRecords() async {
    final box = await _openBox();
    final results = <StreetMemoryRecord>[];
    for (final value in box.values) {
      final record = _decodeRecord(value);
      if (record != null) results.add(record);
    }
    return results;
  }

  @override
  Future<StreetMemoryRecord?> getRecord(String streetId) async {
    final box = await _openBox();
    final raw = box.get(streetId);
    return _decodeRecord(raw);
  }

  @override
  Future<void> ensureRecord(String streetId) async {
    final existing = await getRecord(streetId);
    if (existing != null) return;
    await saveRecord(StreetMemoryRecord.initial(streetId));
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  StreetMemoryRecord? _decodeRecord(dynamic raw) {
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      return StreetMemoryRecord.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}
