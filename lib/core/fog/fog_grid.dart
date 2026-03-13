import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_map/flutter_map.dart' show LatLngBounds;
import 'package:latlong2/latlong.dart';
import 'fog_cell.dart';

/// Tile-based fog-of-war grid.
///
/// The world is divided into square cells of [cellSizeMeters] x [cellSizeMeters].
/// Cell (0, 0) is anchored at [origin].  Cells are stored in a [Set] for O(1)
/// lookup; serialisation packs the set into a compact binary format.
///
/// [FogGrid] is immutable - all mutating operations return a new instance.
///
/// Geographic math:
/// - 1 degree latitude  approx 111,111 m
/// - 1 degree longitude approx 111,111 * cos(lat) m
class FogGrid {
  FogGrid({
    required this.origin,
    this.cellSizeMeters = 10.0,
  })  : _explored = const {},
        _cellSizeDegLat = cellSizeMeters / _metersPerDegLat,
        _cellSizeDegLng = cellSizeMeters /
            (_metersPerDegLat * math.cos(origin.latitude * math.pi / 180.0));

  /// Private constructor for building a grid from a pre-populated explored set.
  FogGrid._(
    Set<FogCell> explored, {
    required this.origin,
    required this.cellSizeMeters,
  })  : _explored = Set.unmodifiable(explored),
        _cellSizeDegLat = cellSizeMeters / _metersPerDegLat,
        _cellSizeDegLng = cellSizeMeters /
            (_metersPerDegLat * math.cos(origin.latitude * math.pi / 180.0));

  static const double _metersPerDegLat = 111111.0;

  /// The geographic origin; cell (0,0) is anchored here.
  final LatLng origin;

  /// Size of each cell in meters (default 10 m).
  final double cellSizeMeters;

  final double _cellSizeDegLat;
  final double _cellSizeDegLng;

  final Set<FogCell> _explored;

  /// Number of currently explored cells.
  int get exploredCount => _explored.length;

  /// A copy of all currently explored cells.
  ///
  /// Returns a new mutable [Set] so callers can freely modify the result
  /// without affecting the grid's internal state.
  Set<FogCell> get exploredCells => Set.of(_explored);

  // ---------------------------------------------------------------------------
  // Coordinate conversion
  // ---------------------------------------------------------------------------

  /// Converts a geographic position to its grid cell.
  FogCell latLngToCell(LatLng position) {
    final dx = position.longitude - origin.longitude;
    final dy = position.latitude - origin.latitude;
    return FogCell(
      x: dx ~/ _cellSizeDegLng,
      y: dy ~/ _cellSizeDegLat,
    );
  }

  // ---------------------------------------------------------------------------
  // Immutable update helpers
  // ---------------------------------------------------------------------------

  /// Returns a new [FogGrid] with all cells within [radiusMeters] of [position]
  /// marked as explored, in addition to any already-explored cells.
  FogGrid markExplored(LatLng position, double radiusMeters) {
    final center = latLngToCell(position);

    // Number of cells that span the radius in each axis
    final radiusCellsLat = (radiusMeters / cellSizeMeters).ceil();
    final radiusCellsLng = (radiusMeters / cellSizeMeters).ceil();

    final newExplored = Set<FogCell>.from(_explored);

    for (var dy = -radiusCellsLat; dy <= radiusCellsLat; dy++) {
      for (var dx = -radiusCellsLng; dx <= radiusCellsLng; dx++) {
        // Distance from center of candidate cell to the position in meters
        final cellLat =
            origin.latitude + (center.y + dy + 0.5) * _cellSizeDegLat;
        final cellLng =
            origin.longitude + (center.x + dx + 0.5) * _cellSizeDegLng;

        final distMeters = _haversineMeters(
            position.latitude, position.longitude, cellLat, cellLng);

        if (distMeters <= radiusMeters) {
          newExplored.add(FogCell(x: center.x + dx, y: center.y + dy));
        }
      }
    }

    return FogGrid._(newExplored,
        origin: origin, cellSizeMeters: cellSizeMeters);
  }

  /// Returns whether the cell at ([x], [y]) has been explored.
  bool isCellExplored(int x, int y) => _explored.contains(FogCell(x: x, y: y));

  // ---------------------------------------------------------------------------
  // Exploration percentage
  // ---------------------------------------------------------------------------

  /// Fraction of cells inside [bounds] that have been explored (0.0-1.0).
  double explorationPercentage(LatLngBounds bounds) {
    final minCell = latLngToCell(bounds.southWest);
    final maxCell = latLngToCell(bounds.northEast);

    final xMin = math.min(minCell.x, maxCell.x);
    final xMax = math.max(minCell.x, maxCell.x);
    final yMin = math.min(minCell.y, maxCell.y);
    final yMax = math.max(minCell.y, maxCell.y);

    final total = (xMax - xMin + 1) * (yMax - yMin + 1);
    if (total <= 0) return 0.0;

    var exploredInBounds = 0;
    for (var y = yMin; y <= yMax; y++) {
      for (var x = xMin; x <= xMax; x++) {
        if (isCellExplored(x, y)) exploredInBounds++;
      }
    }

    return (exploredInBounds / total).clamp(0.0, 1.0);
  }

  // ---------------------------------------------------------------------------
  // Serialisation
  // ---------------------------------------------------------------------------

  /// Encodes the explored set as a compact binary blob.
  ///
  /// Format: each cell is 8 bytes (int32 x, int32 y), little-endian.
  Uint8List toBytes() {
    final cells = _explored.toList();
    final buffer = ByteData(cells.length * 8);
    for (var i = 0; i < cells.length; i++) {
      buffer.setInt32(i * 8, cells[i].x, Endian.little);
      buffer.setInt32(i * 8 + 4, cells[i].y, Endian.little);
    }
    return buffer.buffer.asUint8List();
  }

  /// Restores a [FogGrid] from bytes produced by [toBytes].
  factory FogGrid.fromBytes(
    Uint8List bytes, {
    required LatLng origin,
    double cellSizeMeters = 10.0,
  }) {
    if (bytes.isEmpty) {
      return FogGrid(origin: origin, cellSizeMeters: cellSizeMeters);
    }

    final buffer =
        bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
    final cellCount = bytes.length ~/ 8;
    final explored = <FogCell>{};
    for (var i = 0; i < cellCount; i++) {
      final x = buffer.getInt32(i * 8, Endian.little);
      final y = buffer.getInt32(i * 8 + 4, Endian.little);
      explored.add(FogCell(x: x, y: y));
    }
    return FogGrid._(explored,
        origin: origin, cellSizeMeters: cellSizeMeters);
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Fast haversine distance in meters between two lat/lng points.
  static double _haversineMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const r = 6371000.0; // Earth radius in metres
    final dLat = (lat2 - lat1) * math.pi / 180.0;
    final dLng = (lng2 - lng1) * math.pi / 180.0;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180.0) *
            math.cos(lat2 * math.pi / 180.0) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return 2 * r * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}
