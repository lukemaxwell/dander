import 'package:latlong2/latlong.dart';

import 'discovery.dart';

/// Pure utility class for detecting when a user position is within
/// the discovery radius of undiscovered points of interest.
class ProximityDetector {
  ProximityDetector._();

  /// Default radius in metres within which a discovery is triggered.
  static const double discoveryRadiusMeters = 30.0;

  // Haversine distance calculator from latlong2.
  static final Distance _distance = const Distance();

  /// Returns the subset of [undiscovered] POIs whose distance from [position]
  /// is ≤ [radiusMeters].
  ///
  /// The [undiscovered] list is treated as read-only; it is never mutated.
  /// Callers are responsible for passing only undiscovered items.
  static List<Discovery> detectNew(
    LatLng position,
    List<Discovery> undiscovered,
    double radiusMeters,
  ) {
    final triggered = <Discovery>[];
    for (final poi in undiscovered) {
      final meters = _distance.as(LengthUnit.Meter, position, poi.position);
      if (meters <= radiusMeters) {
        triggered.add(poi);
      }
    }
    return triggered;
  }
}
