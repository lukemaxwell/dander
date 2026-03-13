import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import 'walk_session.dart';

/// Pure utility class for geographic distance calculations.
///
/// All methods are static — no state is held.
class DistanceCalculator {
  DistanceCalculator._();

  static const double _earthRadiusMeters = 6371000.0;

  /// Computes the great-circle distance in metres between two points using the
  /// Haversine formula.
  ///
  /// Formula:
  ///   a = sin²(Δlat/2) + cos(lat1)·cos(lat2)·sin²(Δlng/2)
  ///   c = 2·atan2(√a, √(1−a))
  ///   d = R·c
  static double haversine(LatLng a, LatLng b) {
    final lat1 = a.latitude * math.pi / 180.0;
    final lat2 = b.latitude * math.pi / 180.0;
    final dLat = (b.latitude - a.latitude) * math.pi / 180.0;
    final dLng = (b.longitude - a.longitude) * math.pi / 180.0;

    final sinDLat = math.sin(dLat / 2);
    final sinDLng = math.sin(dLng / 2);

    final aVal =
        sinDLat * sinDLat + math.cos(lat1) * math.cos(lat2) * sinDLng * sinDLng;
    final c = 2 * math.atan2(math.sqrt(aVal), math.sqrt(1 - aVal));

    return _earthRadiusMeters * c;
  }

  /// Sums the haversine distances of consecutive [WalkPoint] segments.
  ///
  /// Returns 0.0 for lists with fewer than 2 points.
  static double totalDistance(List<WalkPoint> points) {
    if (points.length < 2) return 0.0;

    var total = 0.0;
    for (var i = 1; i < points.length; i++) {
      total += haversine(points[i - 1].position, points[i].position);
    }
    return total;
  }

  /// Converts metres to kilometres.
  static double metersToKilometers(double meters) => meters / 1000.0;
}
