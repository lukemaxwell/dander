import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import 'zone.dart';

/// Pure domain class for zone detection logic.
///
/// Stateless — create once and reuse freely (or register as a singleton in
/// the service locator).
class ZoneDetector {
  /// Distance threshold in metres beyond which a position qualifies for a
  /// new zone (50 km).
  static const double newZoneThresholdMeters = 50000.0;

  /// Returns `true` if [position] is more than [newZoneThresholdMeters] from
  /// **every** zone centre in [existingZones], or if [existingZones] is empty.
  ///
  /// A `true` result signals that the user has travelled far enough to warrant
  /// prompting them to create a new zone.
  bool detectNewZone(LatLng position, List<Zone> existingZones) {
    if (existingZones.isEmpty) return true;
    return existingZones.every(
      (zone) => distanceBetween(position, zone.centre) > newZoneThresholdMeters,
    );
  }

  /// Returns the [Zone] whose centre is closest to [position], or `null` if
  /// [zones] is empty.
  ///
  /// The input list is not mutated.
  Zone? findActiveZone(LatLng position, List<Zone> zones) {
    if (zones.isEmpty) return null;

    Zone closest = zones.first;
    double closestDist = distanceBetween(position, zones.first.centre);

    for (var i = 1; i < zones.length; i++) {
      final dist = distanceBetween(position, zones[i].centre);
      if (dist < closestDist) {
        closestDist = dist;
        closest = zones[i];
      }
    }

    return closest;
  }

  /// Haversine distance in metres between two geographic points [a] and [b].
  ///
  /// Uses Earth radius 6 371 000 m, consistent with [FogGrid].
  double distanceBetween(LatLng a, LatLng b) {
    const r = 6371000.0; // Earth radius in metres
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
