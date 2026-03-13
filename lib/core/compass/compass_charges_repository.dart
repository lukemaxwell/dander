import 'dart:convert';

import 'package:hive/hive.dart';

import '../storage/hive_boxes.dart';
import 'compass_charges.dart';

/// Abstract interface for persisting [CompassCharges] data.
abstract class CompassChargesRepository {
  /// Loads the current compass charges, returning defaults if none are stored.
  Future<CompassCharges> load();

  /// Saves [charges] to persistent storage.
  Future<void> save(CompassCharges charges);
}

/// Hive-backed implementation of [CompassChargesRepository].
///
/// Charges are stored as a JSON string under a fixed key.
class HiveCompassChargesRepository implements CompassChargesRepository {
  HiveCompassChargesRepository({String boxName = HiveBoxes.compassCharges})
      : _box = null,
        _boxName = boxName;

  /// Constructor that injects an already-open [Box] — used in tests.
  HiveCompassChargesRepository.withBox(Box<dynamic> box)
      : _box = box,
        _boxName = HiveBoxes.compassCharges;

  static const String _key = 'compass_charges';

  final Box<dynamic>? _box;
  final String _boxName;

  Future<Box<dynamic>> _openBox() async {
    if (_box != null) return _box!;
    if (Hive.isBoxOpen(_boxName)) return Hive.box(_boxName);
    return Hive.openBox(_boxName);
  }

  @override
  Future<CompassCharges> load() async {
    final box = await _openBox();
    final raw = box.get(_key);
    if (raw == null) return const CompassCharges();
    try {
      final map = jsonDecode(raw as String) as Map<String, dynamic>;
      return CompassCharges.fromJson(map);
    } catch (_) {
      return const CompassCharges();
    }
  }

  @override
  Future<void> save(CompassCharges charges) async {
    final box = await _openBox();
    await box.put(_key, jsonEncode(charges.toJson()));
  }
}
