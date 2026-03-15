import 'package:dander/core/zone/zone.dart';

/// Immutable data container for [TurfShareCard].
///
/// Use [fromZone] to derive all fields from a [Zone] plus street/cell counts.
class TurfShareCardData {
  const TurfShareCardData({
    required this.zoneName,
    required this.level,
    required this.streetCount,
    required this.exploredCellCount,
    required this.exploredPct,
  });

  /// Human-readable zone name (e.g. "Hackney").
  final String zoneName;

  /// 1-based explorer level derived from zone XP.
  final int level;

  /// Number of distinct streets the user has walked in this zone.
  final int streetCount;

  /// Number of fog grid cells the user has explored in this zone.
  final int exploredCellCount;

  /// Fraction of zone cells explored, from 0.0 to 1.0.
  final double exploredPct;

  /// Creates [TurfShareCardData] from a [Zone] and additional counters.
  factory TurfShareCardData.fromZone(
    Zone zone, {
    required int streetCount,
    required int exploredCellCount,
    required double exploredPct,
  }) {
    return TurfShareCardData(
      zoneName: zone.name,
      level: zone.level,
      streetCount: streetCount,
      exploredCellCount: exploredCellCount,
      exploredPct: exploredPct,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TurfShareCardData &&
          runtimeType == other.runtimeType &&
          zoneName == other.zoneName &&
          level == other.level &&
          streetCount == other.streetCount &&
          exploredCellCount == other.exploredCellCount &&
          exploredPct == other.exploredPct;

  @override
  int get hashCode =>
      zoneName.hashCode ^
      level.hashCode ^
      streetCount.hashCode ^
      exploredCellCount.hashCode ^
      exploredPct.hashCode;

  @override
  String toString() => 'TurfShareCardData('
      'zoneName: $zoneName, '
      'level: $level, '
      'streetCount: $streetCount, '
      'exploredCellCount: $exploredCellCount, '
      'exploredPct: $exploredPct)';
}
