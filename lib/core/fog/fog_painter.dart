import 'dart:math' as math;
import 'dart:ui' as ui;
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
/// Paints a deep navy fog over the entire canvas, optionally overlaid with a
/// tileable [fogTexture] for atmospheric depth, then "punches" transparent
/// holes for every explored cell.
///
/// When [glowColor] is set, a second compositing pass draws a coloured fringe
/// at the boundary of explored territory by painting a wide blur and then
/// removing the interior.
///
/// Only cells within the current [viewport] are processed so rendering stays
/// efficient even with tens of thousands of explored cells.
class FogPainter extends CustomPainter {
  FogPainter({
    required this.fogGrid,
    required this.viewport,
    this.fogTexture,
    this.glowColor,
    this.glowSigma = 16.0,
  });

  /// Deep navy/purple fog colour matching the Dander aesthetic.
  static const Color fogColor = Color(0xFF1A1A2E);

  final FogGrid fogGrid;
  final FogViewport viewport;

  /// Optional tileable noise image painted over the fog at low opacity.
  final ui.Image? fogTexture;

  /// Colour of the glow fringe at the fog boundary. When null, no glow is
  /// painted.
  final Color? glowColor;

  /// Blur sigma for the glow fringe (default 16).
  final double glowSigma;

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

    final origin = fogGrid.origin;
    final cellDegLat = fogGrid.cellSizeMeters / 111111.0;
    final cellDegLng = fogGrid.cellSizeMeters /
        (111111.0 * math.cos(origin.latitude * math.pi / 180.0));

    // ------------------------------------------------------------------
    // Pass 1: Fog layer (solid fill + optional texture + hole-punching)
    // ------------------------------------------------------------------
    final fogPaint = Paint()..color = fogColor;
    final clearPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..blendMode = BlendMode.dstOut
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.saveLayer(Offset.zero & size, Paint());

    // Solid fog background.
    canvas.drawRect(Offset.zero & size, fogPaint);

    // Overlay noise texture if available.
    final texture = fogTexture;
    if (texture != null) {
      final shader = ImageShader(
        texture,
        TileMode.repeated,
        TileMode.repeated,
        Matrix4.identity().storage,
      );
      final texturePaint = Paint()
        ..shader = shader
        ..color = const Color(0x0FFFFFFF); // ~6% opacity
      canvas.drawRect(Offset.zero & size, texturePaint);
    }

    // Punch transparent holes for explored cells.
    _forEachVisibleExploredCell(
      xMin, xMax, yMin, yMax, origin, cellDegLat, cellDegLng,
      (rect) => canvas.drawRect(rect, clearPaint),
    );

    canvas.restore();

    // ------------------------------------------------------------------
    // Pass 2: Edge glow (optional)
    // ------------------------------------------------------------------
    final glow = glowColor;
    if (glow != null) {
      canvas.saveLayer(Offset.zero & size, Paint());

      // Draw wide coloured blur for all explored cells.
      final glowPaint = Paint()
        ..color = glow
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowSigma);

      _forEachVisibleExploredCell(
        xMin, xMax, yMin, yMax, origin, cellDegLat, cellDegLng,
        (rect) => canvas.drawRect(rect, glowPaint),
      );

      // Punch out the interior — leaves only the fringe.
      final glowClearPaint = Paint()
        ..color = const Color(0xFFFFFFFF)
        ..blendMode = BlendMode.dstOut
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowSigma * 0.35);

      _forEachVisibleExploredCell(
        xMin, xMax, yMin, yMax, origin, cellDegLat, cellDegLng,
        (rect) => canvas.drawRect(rect, glowClearPaint),
      );

      canvas.restore();
    }
  }

  /// Iterates over every explored cell in the visible range and calls
  /// [callback] with its pixel [Rect].
  void _forEachVisibleExploredCell(
    int xMin,
    int xMax,
    int yMin,
    int yMax,
    LatLng origin,
    double cellDegLat,
    double cellDegLng,
    void Function(Rect rect) callback,
  ) {
    for (var y = yMin; y <= yMax; y++) {
      for (var x = xMin; x <= xMax; x++) {
        if (!fogGrid.isCellExplored(x, y)) continue;

        final cellLngLeft = origin.longitude + x * cellDegLng;
        final cellLatBottom = origin.latitude + y * cellDegLat;
        final cellLngRight = cellLngLeft + cellDegLng;
        final cellLatTop = cellLatBottom + cellDegLat;

        final left = viewport.lngToX(cellLngLeft);
        final top = viewport.latToY(cellLatTop);
        final right = viewport.lngToX(cellLngRight);
        final bottom = viewport.latToY(cellLatBottom);

        callback(Rect.fromLTRB(left, top, right, bottom));
      }
    }
  }

  @override
  bool shouldRepaint(FogPainter oldDelegate) =>
      !identical(fogGrid, oldDelegate.fogGrid) ||
      viewport != oldDelegate.viewport ||
      !identical(fogTexture, oldDelegate.fogTexture) ||
      glowColor != oldDelegate.glowColor ||
      glowSigma != oldDelegate.glowSigma;
}
