import 'package:dander/core/progress/badge.dart';
import 'package:dander/core/zone/global_stats.dart';
import 'package:dander/core/zone/mystery_poi.dart';
import 'package:dander/core/zone/zone.dart';

/// Pure, stateless calculator that aggregates per-zone data into [GlobalStats].
///
/// Has no dependencies and produces a new [GlobalStats] value on every call —
/// no mutation of any input collections occurs.
class GlobalStatsCalculator {
  GlobalStatsCalculator._();

  /// Aggregates [zones], [poisByZone], and [badgesByZone] into a single
  /// [GlobalStats] snapshot.
  ///
  /// - [zones]        — all zones to aggregate.
  /// - [poisByZone]   — zone id → list of [MysteryPoi]; entries for zone ids
  ///                    absent from [zones] are ignored.
  /// - [badgesByZone] — zone id → list of [Badge]; entries for zone ids absent
  ///                    from [zones] are ignored.  Keys in the output
  ///                    [GlobalStats.badgesByZone] are zone *names*, not ids.
  static GlobalStats calculate({
    required List<Zone> zones,
    required Map<String, List<MysteryPoi>> poisByZone,
    required Map<String, List<Badge>> badgesByZone,
  }) {
    var totalXp = 0;
    var totalPoisDiscovered = 0;
    final aggregatedBadgesByZone = <String, List<Badge>>{};

    for (final zone in zones) {
      totalXp += zone.xp;

      final pois = poisByZone[zone.id];
      if (pois != null) {
        totalPoisDiscovered += pois.where((p) => p.isRevealed).length;
      }

      final badges = badgesByZone[zone.id];
      if (badges != null) {
        aggregatedBadgesByZone[zone.name] = List.unmodifiable(badges);
      }
    }

    return GlobalStats(
      totalZones: zones.length,
      totalXp: totalXp,
      totalStreetsWalked: 0,
      totalPoisDiscovered: totalPoisDiscovered,
      badgesByZone: Map.unmodifiable(aggregatedBadgesByZone),
    );
  }
}
