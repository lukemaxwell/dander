import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/streets/street.dart';
import 'package:dander/core/theme/app_theme.dart';

/// A non-interactive map widget that highlights a single [street] as a gold
/// polyline, used in quiz questions so the user can identify the street.
///
/// The map is wrapped in [IgnorePointer] to prevent interaction.
/// Fixed height: 280.0.
class QuizMapSnippet extends StatelessWidget {
  const QuizMapSnippet({super.key, required this.street});

  /// The street to highlight with a gold polyline.
  final Street street;

  static const double _height = 280.0;
  static const Color _polylineColor = DanderColors.rarityRare;
  static const double _polylineWidth = 4.0;
  static const double _defaultZoom = 16.0;

  @override
  Widget build(BuildContext context) {
    final nodes = street.nodes;

    if (nodes.isEmpty) {
      return SizedBox(
        height: _height,
        child: ColoredBox(
          color: DanderColors.primary,
          child: Center(
            child: Text(
              'No map data',
              style: DanderTextStyles.labelSmall,
            ),
          ),
        ),
      );
    }

    final center = _computeCenter(nodes);
    final zoom = _computeZoom(nodes);

    return SizedBox(
      height: _height,
      child: IgnorePointer(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
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
                urlTemplate:
                    'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.dander.app',
              ),
              PolylineLayer(
                polylines: [
                  if (nodes.length > 1)
                    Polyline(
                      points: nodes,
                      color: _polylineColor,
                      strokeWidth: _polylineWidth,
                    )
                  else
                    // Single-node: render a tiny polyline at the same point
                    Polyline(
                      points: [nodes.first, nodes.first],
                      color: _polylineColor,
                      strokeWidth: _polylineWidth,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static LatLng _computeCenter(List<LatLng> nodes) {
    final latSum = nodes.fold<double>(0, (sum, n) => sum + n.latitude);
    final lngSum = nodes.fold<double>(0, (sum, n) => sum + n.longitude);
    return LatLng(latSum / nodes.length, lngSum / nodes.length);
  }

  static double _computeZoom(List<LatLng> nodes) {
    if (nodes.length <= 1) return _defaultZoom;

    final lats = nodes.map((n) => n.latitude);
    final lngs = nodes.map((n) => n.longitude);
    final latDelta = lats.reduce((a, b) => a > b ? a : b) -
        lats.reduce((a, b) => a < b ? a : b);
    final lngDelta = lngs.reduce((a, b) => a > b ? a : b) -
        lngs.reduce((a, b) => a < b ? a : b);
    final maxDelta = latDelta > lngDelta ? latDelta : lngDelta;

    if (maxDelta > 0.05) return 12.0;
    if (maxDelta > 0.01) return 14.0;
    if (maxDelta > 0.005) return 15.0;
    return _defaultZoom;
  }
}
