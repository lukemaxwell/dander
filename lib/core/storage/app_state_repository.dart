import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';

// ---------------------------------------------------------------------------
// Value objects
// ---------------------------------------------------------------------------

/// Lightweight representation of a geographic bounding box.
///
/// Uses raw [double] fields rather than a third-party type so that it is
/// trivially serialisable to a plain [Map] and storable in Hive without
/// needing a generated adapter.
class NeighbourhoodBounds {
  const NeighbourhoodBounds({
    required this.southWestLat,
    required this.southWestLng,
    required this.northEastLat,
    required this.northEastLng,
  });

  final double southWestLat;
  final double southWestLng;
  final double northEastLat;
  final double northEastLng;

  Map<String, dynamic> toMap() => {
        'sw_lat': southWestLat,
        'sw_lng': southWestLng,
        'ne_lat': northEastLat,
        'ne_lng': northEastLng,
      };

  static NeighbourhoodBounds fromMap(Map<dynamic, dynamic> map) =>
      NeighbourhoodBounds(
        southWestLat: (map['sw_lat'] as num).toDouble(),
        southWestLng: (map['sw_lng'] as num).toDouble(),
        northEastLat: (map['ne_lat'] as num).toDouble(),
        northEastLng: (map['ne_lng'] as num).toDouble(),
      );
}

// ---------------------------------------------------------------------------
// Abstract interface
// ---------------------------------------------------------------------------

/// Stores lightweight app-level state between sessions.
abstract interface class AppStateRepository {
  /// Saves the most-recently-known GPS [position].
  Future<void> saveLastPosition(LatLng position);

  /// Returns the last-saved GPS position, or `null` if none exists yet.
  Future<LatLng?> getLastPosition();

  /// Saves the user's neighbourhood [bounds].
  Future<void> saveNeighbourhoodBounds(NeighbourhoodBounds bounds);

  /// Returns the stored neighbourhood bounds, or `null` if not yet set.
  Future<NeighbourhoodBounds?> getNeighbourhoodBounds();

  /// Records that the first-launch flow has been completed.
  Future<void> markFirstLaunchComplete();

  /// Returns `true` if the user has never completed the first-launch flow.
  Future<bool> isFirstLaunch();
}

// ---------------------------------------------------------------------------
// Hive-backed implementation
// ---------------------------------------------------------------------------

/// Hive-backed implementation of [AppStateRepository].
///
/// All keys are private constants to prevent typo bugs.
class AppStateRepositoryImpl implements AppStateRepository {
  AppStateRepositoryImpl({required Box<dynamic> box}) : _box = box;

  final Box<dynamic> _box;

  static const _keyLastPosition = 'last_position';
  static const _keyNeighbourhoodBounds = 'neighbourhood_bounds';
  static const _keyFirstLaunchComplete = 'first_launch_complete';

  @override
  Future<void> saveLastPosition(LatLng position) async {
    await _box.put(_keyLastPosition, {
      'lat': position.latitude,
      'lng': position.longitude,
    });
  }

  @override
  Future<LatLng?> getLastPosition() async {
    final raw = _box.get(_keyLastPosition);
    if (raw == null) return null;
    final map = raw as Map<dynamic, dynamic>;
    return LatLng(
      (map['lat'] as num).toDouble(),
      (map['lng'] as num).toDouble(),
    );
  }

  @override
  Future<void> saveNeighbourhoodBounds(NeighbourhoodBounds bounds) async {
    await _box.put(_keyNeighbourhoodBounds, bounds.toMap());
  }

  @override
  Future<NeighbourhoodBounds?> getNeighbourhoodBounds() async {
    final raw = _box.get(_keyNeighbourhoodBounds);
    if (raw == null) return null;
    return NeighbourhoodBounds.fromMap(raw as Map<dynamic, dynamic>);
  }

  @override
  Future<void> markFirstLaunchComplete() async {
    await _box.put(_keyFirstLaunchComplete, true);
  }

  @override
  Future<bool> isFirstLaunch() async {
    final value = _box.get(_keyFirstLaunchComplete);
    // Treat null or false as first-launch-not-complete
    return value != true;
  }
}
