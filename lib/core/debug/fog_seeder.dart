import 'package:latlong2/latlong.dart';

import '../fog/fog_grid.dart';

/// Generates a [FogGrid] with pre-explored cells along walked paths.
///
/// Used by seed fixtures to create deterministic fog-of-war state
/// for testing, debugging, and marketing screenshots.
class FogSeeder {
  FogSeeder._();

  /// Creates a [FogGrid] anchored at [origin] with cells marked as explored
  /// along each path in [walkedPaths].
  ///
  /// Each point in a path clears a circle of [exploreRadiusMeters] (default 50m),
  /// matching the same radius used during real walks.
  static FogGrid seed({
    required LatLng origin,
    required List<List<LatLng>> walkedPaths,
    double exploreRadiusMeters = 50.0,
    double cellSizeMeters = 10.0,
  }) {
    final grid = FogGrid(origin: origin, cellSizeMeters: cellSizeMeters);

    for (final path in walkedPaths) {
      for (final point in path) {
        grid.markExplored(point, exploreRadiusMeters);
      }
    }

    return grid;
  }
}
