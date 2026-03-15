import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Public math helpers (exported so tests can reach them directly).
// ---------------------------------------------------------------------------

/// Returns the forward azimuth (bearing) from [from] to [to] in degrees,
/// measured clockwise from true/magnetic north (0–360).
///
/// Uses the standard forward azimuth formula:
///   θ = atan2( sin(Δλ)·cos(φ₂),
///              cos(φ₁)·sin(φ₂) − sin(φ₁)·cos(φ₂)·cos(Δλ) )
double bearingToTarget(LatLng from, LatLng to) {
  final lat1 = _deg2rad(from.latitude);
  final lat2 = _deg2rad(to.latitude);
  final dLon = _deg2rad(to.longitude - from.longitude);

  final y = math.sin(dLon) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

  final bearingRad = math.atan2(y, x);
  return (_rad2deg(bearingRad) + 360) % 360;
}

/// Returns the relative bearing from the user toward [target], given the
/// user's current [heading] in degrees.
///
/// The result is normalised to [0, 360) so it can be used directly as a
/// clockwise rotation angle for the arrow widget.
///
/// Returns `null` when [heading] is `null` (heading unknown).
double? relativeBearing(LatLng user, LatLng target, double? heading) {
  if (heading == null) return null;
  final absolute = bearingToTarget(user, target);
  return (absolute - heading + 360) % 360;
}

/// Formats the Haversine distance from [from] to [to].
///
/// - Below 1000 m: `"Xm"` (integer metres).
/// - 1000 m and above: `"X.Xkm"` (one decimal place kilometres).
String formatDistance(LatLng from, LatLng to) {
  final metres = _haversineMetres(from, to);
  if (metres < 1000) {
    return '${metres.round()}m';
  }
  final km = metres / 1000;
  return '${km.toStringAsFixed(1)}km';
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

/// Floating navigation HUD that guides the user toward the nearest hinted
/// mystery POI.
///
/// Renders a rotating arrow icon pointing at [targetPosition] relative to
/// the user's current [headingDegrees], plus the Haversine distance.
///
/// Behaviour:
/// - Returns [SizedBox.shrink] when distance < 10 m (arrival fires separately).
/// - Adds an amber glow box-shadow when distance < 30 m.
/// - Falls back to a [Icons.compass_calibration] icon when [headingDegrees]
///   is `null` (sensor unavailable).
class MysteryMarkerBeacon extends StatelessWidget {
  const MysteryMarkerBeacon({
    super.key,
    required this.userPosition,
    required this.targetPosition,
    required this.headingDegrees,
  });

  /// Current user position.
  final LatLng userPosition;

  /// Position of the nearest hinted POI.
  final LatLng targetPosition;

  /// Current compass heading in degrees (0–360), or `null` when unknown.
  final double? headingDegrees;

  @override
  Widget build(BuildContext context) {
    final distanceM = _haversineMetres(userPosition, targetPosition);

    // Too close — arrival check handles this; don't clutter the UI.
    if (distanceM < 10) return const SizedBox.shrink();

    final rel = relativeBearing(userPosition, targetPosition, headingDegrees);
    final distanceText = formatDistance(userPosition, targetPosition);
    final isNearby = distanceM < 30;

    // The arrow is rotated so it points at the target relative to the user's
    // facing direction.  We convert degrees → radians for Transform.rotate.
    final arrowWidget = rel != null
        ? Transform.rotate(
            angle: _deg2rad(rel),
            child: const Icon(
              Icons.navigation,
              size: 24,
              color: DanderColors.secondary,
            ),
          )
        : const Icon(
            Icons.compass_calibration,
            size: 24,
            color: DanderColors.secondary,
          );

    final glowShadow = isNearby
        ? [
            BoxShadow(
              color: DanderColors.secondary.withValues(alpha: 0.4),
              blurRadius: 12,
            ),
          ]
        : null;

    return Container(
      key: const Key('beacon_pill'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: DanderColors.cardBackground,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: DanderColors.cardBorder),
        boxShadow: glowShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          arrowWidget,
          const SizedBox(width: 8),
          Text(
            distanceText,
            style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.white) ??
                const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

double _deg2rad(double degrees) => degrees * math.pi / 180;
double _rad2deg(double radians) => radians * 180 / math.pi;

/// Haversine distance in metres between two [LatLng] points.
double _haversineMetres(LatLng from, LatLng to) {
  const earthRadius = 6371000.0; // metres

  final lat1 = _deg2rad(from.latitude);
  final lat2 = _deg2rad(to.latitude);
  final dLat = _deg2rad(to.latitude - from.latitude);
  final dLon = _deg2rad(to.longitude - from.longitude);

  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1) *
          math.cos(lat2) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);

  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadius * c;
}
