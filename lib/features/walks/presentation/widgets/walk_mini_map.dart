import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// A small, non-interactive map widget showing a walk route as a polyline.
///
/// The map is centred and zoomed to fit all [points].  When [points] is empty
/// a placeholder is shown instead of an empty tile map.
///
/// Gesture detection is disabled so the widget can be embedded in scrollable
/// lists without capturing scroll events.
class WalkMiniMap extends StatelessWidget {
  const WalkMiniMap({
    super.key,
    required this.points,
  });

  /// The GPS points that make up the walk route.
  final List<LatLng> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return _EmptyMap();
    }

    final center = _computeCenter(points);
    final zoom = _computeZoom(points);

    return IgnorePointer(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: zoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.dander.app',
            ),
            if (points.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: points,
                    color: const Color(0xFF7C3AED),
                    strokeWidth: 3,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                Marker(
                  point: points.first,
                  width: 12,
                  height: 12,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF7C3AED),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Marker(
                  point: points.last,
                  width: 12,
                  height: 12,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Returns the geographic midpoint of all [points].
  static LatLng _computeCenter(List<LatLng> points) {
    final latSum = points.fold<double>(0, (sum, p) => sum + p.latitude);
    final lngSum = points.fold<double>(0, (sum, p) => sum + p.longitude);
    return LatLng(latSum / points.length, lngSum / points.length);
  }

  /// Estimates a zoom level that fits all [points] within view.
  static double _computeZoom(List<LatLng> points) {
    if (points.length == 1) return 15;

    final lats = points.map((p) => p.latitude);
    final lngs = points.map((p) => p.longitude);
    final latDelta = lats.reduce((a, b) => a > b ? a : b) -
        lats.reduce((a, b) => a < b ? a : b);
    final lngDelta = lngs.reduce((a, b) => a > b ? a : b) -
        lngs.reduce((a, b) => a < b ? a : b);
    final maxDelta = latDelta > lngDelta ? latDelta : lngDelta;

    if (maxDelta > 0.1) return 11;
    if (maxDelta > 0.05) return 12;
    if (maxDelta > 0.01) return 13;
    if (maxDelta > 0.005) return 14;
    return 15;
  }
}

// ---------------------------------------------------------------------------
// Empty state placeholder
// ---------------------------------------------------------------------------

class _EmptyMap extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: const Color(0xFF12121F),
        child: const Center(
          child: Text(
            'No route data',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
