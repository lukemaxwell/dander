import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' show LatLngBounds;
import 'package:latlong2/latlong.dart';
import 'fog_grid.dart';

/// Marker radius for mystery POIs in the fog (logical pixels).
const double _markerBaseRadius = 5.0;
const double _markerPulseExtra = 3.0; // added at peak pulse

/// Describes the visible region of the map that the painter should cover,
/// mapping geographic coordinates to canvas pixels.
class FogViewport {
  const FogViewport({
    required this.bounds,
    required this.canvasSize,
  });

  final LatLngBounds bounds;
  final Size canvasSize;

  double lngToX(double lng) {
    final west = bounds.west;
    final east = bounds.east;
    if (east == west) return 0.0;
    return (lng - west) / (east - west) * canvasSize.width;
  }

  double latToY(double lat) {
    final south = bounds.south;
    final north = bounds.north;
    if (north == south) return 0.0;
    return (north - lat) / (north - south) * canvasSize.height;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FogViewport &&
          bounds == other.bounds &&
          canvasSize == other.canvasSize;

  @override
  int get hashCode => Object.hash(bounds, canvasSize);
}

/// Fog-of-war overlay [CustomPainter].
///
/// Paints a deep navy fog over the entire canvas, then:
///   1. Draws a radial vignette — the fog is slightly lighter at the canvas
///      centre (where the user sits) and darker at the edges, giving depth.
///   2. Punches transparent holes for every explored cell using
///      [BlendMode.dstOut] with a soft [MaskFilter] for smooth edges.
///
/// Only cells within the current [viewport] are processed.
class FogPainter extends CustomPainter {
  FogPainter({
    required this.fogGrid,
    required this.viewport,
    this.mysteryPois = const [],
    this.pulseValue = 0.0,
    this.shimmerValue = 0.0,
    this.reducedMotion = false,
  });

  static const Color fogColor = Color(0xFF1A1A2E);

  final FogGrid fogGrid;
  final FogViewport viewport;

  /// Undiscovered POI positions to render as pulsing markers in the fog.
  final List<LatLng> mysteryPois;

  /// Animation value [0.0, 1.0] driving the pulse size/opacity of markers.
  final double pulseValue;

  /// Animation value [0.0, 1.0] driving the fog boundary shimmer sweep.
  final double shimmerValue;

  /// When true, animations are static (reduced-motion preference).
  final bool reducedMotion;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = viewport.bounds;

    final swCell = fogGrid.latLngToCell(bounds.southWest);
    final neCell = fogGrid.latLngToCell(bounds.northEast);

    final xMin = math.min(swCell.x, neCell.x) - 1;
    final xMax = math.max(swCell.x, neCell.x) + 1;
    final yMin = math.min(swCell.y, neCell.y) - 1;
    final yMax = math.max(swCell.y, neCell.y) + 1;

    final origin = fogGrid.origin;
    final cellDegLat = fogGrid.cellSizeMeters / 111111.0;
    final cellDegLng = fogGrid.cellSizeMeters /
        (111111.0 * math.cos(origin.latitude * math.pi / 180.0));

    canvas.saveLayer(Offset.zero & size, Paint());

    // 1. Solid fog base.
    canvas.drawRect(Offset.zero & size, Paint()..color = fogColor);

    // 2. Radial vignette — lighter at centre, darker at edges.
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = size.longestSide * 0.7;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: const [
            Color(0x22FFFFFF), // white ~13% at centre
            Color(0x00000000), // transparent at edge
          ],
        ).createShader(Rect.fromCircle(center: centre, radius: radius)),
    );

    // 3. Punch transparent holes for explored cells.
    final clearPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..blendMode = BlendMode.dstOut
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    for (var y = yMin; y <= yMax; y++) {
      for (var x = xMin; x <= xMax; x++) {
        if (!fogGrid.isCellExplored(x, y)) continue;

        final cellLngLeft = origin.longitude + x * cellDegLng;
        final cellLatBottom = origin.latitude + y * cellDegLat;
        final cellLngRight = cellLngLeft + cellDegLng;
        final cellLatTop = cellLatBottom + cellDegLat;

        canvas.drawRect(
          Rect.fromLTRB(
            viewport.lngToX(cellLngLeft),
            viewport.latToY(cellLatTop),
            viewport.lngToX(cellLngRight),
            viewport.latToY(cellLatBottom),
          ),
          clearPaint,
        );
      }
    }

    // 4. Mystery POI pulse markers in unexplored fog areas.
    _paintMysteryMarkers(canvas);

    // 5. Fog boundary shimmer sweep (only when not reduced-motion).
    if (!reducedMotion) {
      _paintBoundaryShimmer(canvas, size);
    }

    canvas.restore();
  }

  void _paintMysteryMarkers(Canvas canvas) {
    if (mysteryPois.isEmpty) return;

    final pulse = reducedMotion ? 0.5 : pulseValue;
    final radius = _markerBaseRadius + pulse * _markerPulseExtra;
    final opacity = 0.35 + pulse * 0.35; // 0.35..0.70

    final markerPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final ringPaint = Paint()
      ..color = const Color(0xFFBBDDFF).withValues(alpha: opacity * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final poi in mysteryPois) {
      // Only draw if the cell containing this poi is still fogged.
      final cell = fogGrid.latLngToCell(poi);
      if (fogGrid.isCellExplored(cell.x, cell.y)) continue;

      final x = viewport.lngToX(poi.longitude);
      final y = viewport.latToY(poi.latitude);
      final center = Offset(x, y);

      canvas.drawCircle(center, radius, markerPaint);
      canvas.drawCircle(center, radius + 3 + pulse * 4, ringPaint);
    }
  }

  void _paintBoundaryShimmer(Canvas canvas, Size size) {
    // A diagonal light stripe that sweeps from top-left to bottom-right.
    // shimmerValue [0..1] maps the stripe's offset across the canvas.
    final sweep = shimmerValue;
    final diagonal = size.width + size.height;
    final offset = sweep * diagonal;

    final start = Offset(offset - size.height, 0);
    final end = Offset(offset, size.height);

    final shimmerShader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: const [
        Color(0x00FFFFFF),
        Color(0x0AFFFFFF), // ~4% white at peak
        Color(0x00FFFFFF),
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(Rect.fromPoints(start, end));

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = shimmerShader
        ..blendMode = BlendMode.srcOver,
    );
  }

  @override
  bool shouldRepaint(FogPainter oldDelegate) {
    if (!identical(fogGrid, oldDelegate.fogGrid)) return true;
    if (viewport != oldDelegate.viewport) return true;
    if (!identical(mysteryPois, oldDelegate.mysteryPois)) return true;
    if (pulseValue != oldDelegate.pulseValue) return true;
    if (shimmerValue != oldDelegate.shimmerValue) return true;
    return false;
  }
}
