/// A value object representing a single cell in the fog-of-war grid.
///
/// Each cell corresponds to a [cellSizeMeters] x [cellSizeMeters] area on the
/// ground, identified by integer grid coordinates [x] (easting) and [y]
/// (northing) relative to a chosen origin.
class FogCell {
  const FogCell({required this.x, required this.y});

  /// Grid coordinate in the east–west direction.
  final int x;

  /// Grid coordinate in the north–south direction.
  final int y;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FogCell &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'FogCell(x: $x, y: $y)';
}
