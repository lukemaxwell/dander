import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/quiz/street_memory_record.dart';

/// The type of activity shown in the zone detail recent-activity timeline.
enum ZoneActivityType { walk, discovery }

/// A single entry in the zone's recent activity timeline.
class ZoneActivity {
  const ZoneActivity({
    required this.type,
    required this.description,
    required this.timestamp,
  });

  final ZoneActivityType type;
  final String description;
  final DateTime timestamp;
}

/// Aggregated statistics for a single zone, computed by [ZoneStatsService].
///
/// All counts are filtered to entities within the zone's geographic radius.
/// Immutable value object.
class ZoneStats {
  const ZoneStats({
    required this.streetsWalkedCount,
    required this.discoveryCount,
    required this.discoveriesByCategory,
    required this.discoveriesByRarity,
    required this.totalDistanceMeters,
    required this.masteryStates,
    required this.explorationPct,
    required this.recentActivity,
  });

  /// Number of streets walked within the zone radius.
  final int streetsWalkedCount;

  /// Number of discovered POIs within the zone radius.
  final int discoveryCount;

  /// Discovery count grouped by category (e.g. "cafe" → 3).
  final Map<String, int> discoveriesByCategory;

  /// Discovery count grouped by rarity tier.
  final Map<RarityTier, int> discoveriesByRarity;

  /// Total distance walked (metres) from walks that overlap the zone.
  final double totalDistanceMeters;

  /// Quiz mastery state distribution for zone-scoped streets.
  final Map<MemoryState, int> masteryStates;

  /// Exploration percentage: discovered POIs / total cached POIs in zone.
  final double explorationPct;

  /// Recent activity timeline (walks + discoveries), newest first.
  final List<ZoneActivity> recentActivity;

  /// Empty stats — all zeros, no activity.
  static const empty = ZoneStats(
    streetsWalkedCount: 0,
    discoveryCount: 0,
    discoveriesByCategory: {},
    discoveriesByRarity: {},
    totalDistanceMeters: 0.0,
    masteryStates: {},
    explorationPct: 0.0,
    recentActivity: [],
  );
}
