import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../zone/zone.dart';

/// Pure-function helper that determines whether a geographic [location] is
/// outside every configured [Zone].
///
/// Zone containment is defined as: the user is within the zone's current fog
/// reveal radius ([Zone.radiusMeters]) from the zone's [Zone.centre].
///
/// No state is held — safe to call freely without any instance lifecycle.
abstract final class OutsideZoneDetector {
  /// Returns `true` when [location] falls outside every zone in [zones].
  ///
  /// Returns `false` when:
  /// - [zones] is empty — no zone configured yet, so the banner should not
  ///   show.
  /// - [location] is within [Zone.radiusMeters] of at least one zone centre.
  static bool isOutside(LatLng location, List<Zone> zones) {
    if (zones.isEmpty) return false;
    return zones.every((zone) {
      final dist = _haversineMeters(location, zone.centre);
      return dist > zone.radiusMeters;
    });
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Haversine distance in metres between [a] and [b].
  ///
  /// Uses Earth radius 6 371 000 m, consistent with [FogGrid] / [ZoneDetector].
  static double _haversineMeters(LatLng a, LatLng b) {
    const r = 6371000.0;
    final dLat = (b.latitude - a.latitude) * math.pi / 180.0;
    final dLng = (b.longitude - a.longitude) * math.pi / 180.0;
    final sinHalfLat = math.sin(dLat / 2);
    final sinHalfLng = math.sin(dLng / 2);
    final hav = sinHalfLat * sinHalfLat +
        math.cos(a.latitude * math.pi / 180.0) *
            math.cos(b.latitude * math.pi / 180.0) *
            sinHalfLng *
            sinHalfLng;
    return 2 * r * math.atan2(math.sqrt(hav), math.sqrt(1 - hav));
  }
}
