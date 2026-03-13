import 'package:dander/core/progress/badge.dart';

/// Immutable aggregate of stats across all zones.
///
/// Produced by [GlobalStatsCalculator.calculate] — never construct directly
/// in production code; use the calculator instead.
class GlobalStats {
  const GlobalStats({
    required this.totalZones,
    required this.totalXp,
    required this.totalStreetsWalked,
    required this.totalPoisDiscovered,
    required this.badgesByZone,
  });

  /// Number of zones the user has created.
  final int totalZones;

  /// Sum of XP earned across all zones.
  final int totalXp;

  /// Total number of distinct streets walked (placeholder — always 0).
  final int totalStreetsWalked;

  /// Number of mystery POIs that have been revealed across all zones.
  final int totalPoisDiscovered;

  /// Badges grouped by zone name (zone name → list of badges).
  ///
  /// Only zones that have at least one badge entry appear as keys.
  final Map<String, List<Badge>> badgesByZone;
}
