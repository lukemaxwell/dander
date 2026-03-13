import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' show LatLngBounds;
import 'fog_grid.dart';

/// Describes the visible region of the map that the painter should cover,
/// mapping geographic coordinates to canvas pixels.
class FogViewport {
  const FogViewport({
    required this.bounds,
    required this.canvasSize,
  });

  /// The geographic bounding box currently visible on screen.
  final LatLngBounds bounds;

  /// The pixel dimensions of the canvas.
  final Size canvasSize;

  /// Converts a longitude value to a canvas x-coordinate.
  double lngToX(double lng) {
    final west = bounds.west;
    final east = bounds.east;
    if (east == west) return 0.0;
    return (lng - west) / (east - west) * canvasSize.width;
  }

  /// Converts a latitude value to a canvas y-coordinate.
  ///
  /// Note: higher latitude = further north = smaller y (canvas top = 0).
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
/// Paints a deep navy/purple fog (#1A1A2E at 85% opacity) over the entire
/// canvas, then "punches" transparent holes for every explored cell.
///
/// Only cells within the current [viewport] are processed so rendering stays
/// efficient even with tens of thousands of explored cells.
class FogPainter extends CustomPainter {
  FogPainter({
    required this.fogGrid,
    required this.viewport,
  });

  /// Deep navy/purple fog colour matching the Dander aesthetic.
  static const Color fogColor = Color(0xFF1A1A2E); // #1A1A2E fully opaque

  final FogGrid fogGrid;
  final FogViewport viewport;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = viewport.bounds;

    // Determine which grid cells are visible.
    final swCell = fogGrid.latLngToCell(bounds.southWest);
    final neCell = fogGrid.latLngToCell(bounds.northEast);

    final xMin = math.min(swCell.x, neCell.x) - 1;
    final xMax = math.max(swCell.x, neCell.x) + 1;
    final yMin = math.min(swCell.y, neCell.y) - 1;
    final yMax = math.max(swCell.y, neCell.y) + 1;

    // Use saveLayer + BlendMode.dstOut to punch holes in the fog.
    final fogPaint = Paint()..color = fogColor;
    final clearPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..blendMode = BlendMode.dstOut
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.saveLayer(Offset.zero & size, Paint());

    // Draw the solid fog background.
    canvas.drawRect(Offset.zero & size, fogPaint);

    final origin = fogGrid.origin;
    final cellDegLat = fogGrid.cellSizeMeters / 111111.0;
    final cellDegLng = fogGrid.cellSizeMeters /
        (111111.0 * math.cos(origin.latitude * math.pi / 180.0));

    for (var y = yMin; y <= yMax; y++) {
      for (var x = xMin; x <= xMax; x++) {
        if (!fogGrid.isCellExplored(x, y)) continue;

        // Pixel coordinates of the cell's top-left corner.
        // Cell (x, y) spans longitude [origin.lng + x*dLng, origin.lng + (x+1)*dLng]
        // and latitude [origin.lat + y*dLat, origin.lat + (y+1)*dLat].
        final cellLngLeft = origin.longitude + x * cellDegLng;
        final cellLatBottom = origin.latitude + y * cellDegLat;
        final cellLngRight = cellLngLeft + cellDegLng;
        final cellLatTop = cellLatBottom + cellDegLat;

        final left = viewport.lngToX(cellLngLeft);
        final top = viewport.latToY(cellLatTop); // higher lat = smaller y
        final right = viewport.lngToX(cellLngRight);
        final bottom = viewport.latToY(cellLatBottom);

        canvas.drawRect(
          Rect.fromLTRB(left, top, right, bottom),
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
