import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' show LatLngBounds;
import 'package:latlong2/latlong.dart';
import 'fog_grid.dart';

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
  });

  static const Color fogColor = Color(0xFF1A1A2E);

  final FogGrid fogGrid;
  final FogViewport viewport;

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

    canvas.restore();
  }

  @override
  bool shouldRepaint(FogPainter oldDelegate) =>
      !identical(fogGrid, oldDelegate.fogGrid) ||
      viewport != oldDelegate.viewport;
}
