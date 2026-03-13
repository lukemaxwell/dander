import 'dart:typed_data';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';
import 'fog_grid.dart';

/// Persists [FogGrid] state to a Hive box as compact binary data.
class FogRepository {
  FogRepository({
    required LatLng origin,
    double cellSizeMeters = 10.0,
    String boxName = 'fog_state',
  })  : _origin = origin,
        _cellSizeMeters = cellSizeMeters,
        _boxName = boxName,
        _box = null;

  /// Constructor that injects an already-open [Box] — used in tests.
  FogRepository.withBox(
    Box<dynamic> box, {
    required LatLng origin,
    double cellSizeMeters = 10.0,
  })  : _origin = origin,
        _cellSizeMeters = cellSizeMeters,
        _boxName = 'fog_state',
        _box = box;

  /// The key under which the binary blob is stored in Hive.
  static const String boxKey = 'fog_grid';

  final LatLng _origin;
  final double _cellSizeMeters;
  final String _boxName;
  final Box<dynamic>? _box;

  Future<Box<dynamic>> _openBox() async {
    if (_box != null) return _box;
    if (Hive.isBoxOpen(_boxName)) return Hive.box(_boxName);
    return Hive.openBox(_boxName);
  }

  /// Serialises [grid] and writes it to Hive.
  Future<void> save(FogGrid grid) async {
    final box = await _openBox();
    await box.put(boxKey, grid.toBytes());
  }

  /// Reads and deserialises the stored [FogGrid], or returns `null` if none.
  Future<FogGrid?> load() async {
    final box = await _openBox();
    final raw = box.get(boxKey);
    if (raw == null) return null;
    final bytes = raw as Uint8List;
    return FogGrid.fromBytes(
      bytes,
      origin: _origin,
      cellSizeMeters: _cellSizeMeters,
    );
  }

  /// Removes persisted fog state from storage.
  Future<void> clear() async {
    final box = await _openBox();
    await box.delete(boxKey);
  }
}
