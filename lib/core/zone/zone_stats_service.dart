import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/discoveries/discovery_repository.dart';
import 'package:dander/core/location/distance_calculator.dart' as dc;
import 'package:dander/core/location/walk_repository.dart';
import 'package:dander/core/location/walk_session.dart';
import 'package:dander/core/quiz/quiz_repository.dart';
import 'package:dander/core/quiz/street_memory_record.dart';
import 'package:dander/core/streets/street.dart';
import 'package:dander/core/streets/street_repository.dart';
import 'package:dander/core/zone/zone.dart';
import 'package:dander/core/zone/zone_stats.dart';

/// Aggregates zone-scoped stats from multiple repositories.
///
/// Uses bounding box pre-filter then Haversine distance check to determine
/// which entities fall within a zone's radius.
class ZoneStatsService {
  const ZoneStatsService({
    required StreetRepository streetRepository,
    required DiscoveryRepository discoveryRepository,
    required WalkRepository walkRepository,
    required QuizRepository quizRepository,
  })  : _streetRepo = streetRepository,
        _discoveryRepo = discoveryRepository,
        _walkRepo = walkRepository,
        _quizRepo = quizRepository;

  final StreetRepository _streetRepo;
  final DiscoveryRepository _discoveryRepo;
  final WalkRepository _walkRepo;
  final QuizRepository _quizRepo;

  /// Approximate degrees per metre at the equator.
  /// Used for bounding box pre-filter.
  static const double _degPerMeter = 1.0 / 111320.0;

  /// Returns aggregated stats for [zone], filtered by geographic proximity.
  Future<ZoneStats> getStats(Zone zone) async {
    final radius = zone.radiusMeters;
    final centre = zone.centre;

    // Fetch all data in parallel.
    final results = await Future.wait([
      _streetRepo.getWalkedStreets(),
      _discoveryRepo.getAllCached(),
      _walkRepo.getWalks(),
      _quizRepo.getAllRecords(),
    ]);

    final allStreets = results[0] as List<Street>;
    final allDiscoveries = results[1] as List<Discovery>;
    final allWalks = results[2] as List<WalkSession>;
    final allRecords = results[3] as List<StreetMemoryRecord>;

    // --- Streets ---
    final zoneStreets = _filterStreets(allStreets, centre, radius);
    final zoneStreetIds = zoneStreets.map((s) => s.id).toSet();

    // --- Discoveries ---
    final zoneDiscoveries =
        _filterDiscoveriesByProximity(allDiscoveries, centre, radius);
    final discoveredInZone =
        zoneDiscoveries.where((d) => d.isDiscovered).toList();

    final discoveriesByCategory = <String, int>{};
    final discoveriesByRarity = <RarityTier, int>{};
    for (final d in discoveredInZone) {
      discoveriesByCategory[d.category] =
          (discoveriesByCategory[d.category] ?? 0) + 1;
      discoveriesByRarity[d.rarity] =
          (discoveriesByRarity[d.rarity] ?? 0) + 1;
    }

    final explorationPct = zoneDiscoveries.isEmpty
        ? 0.0
        : discoveredInZone.length / zoneDiscoveries.length;

    // --- Walks ---
    final zoneWalks = _filterWalks(allWalks, centre, radius);
    final totalDistance = zoneWalks.fold<double>(
      0.0,
      (sum, w) => sum + w.distanceMeters,
    );

    // --- Quiz mastery ---
    final recordsByStreetId = <String, StreetMemoryRecord>{};
    for (final r in allRecords) {
      recordsByStreetId[r.streetId] = r;
    }
    final masteryStates = <MemoryState, int>{};
    for (final street in zoneStreets) {
      final record = recordsByStreetId[street.id];
      final state = record?.state ?? MemoryState.newCard;
      masteryStates[state] = (masteryStates[state] ?? 0) + 1;
    }

    // --- Recent activity ---
    final activities = <ZoneActivity>[];
    for (final walk in zoneWalks) {
      final endTime = walk.endTime ?? walk.startTime;
      activities.add(ZoneActivity(
        type: ZoneActivityType.walk,
        description: 'Walk',
        timestamp: endTime,
      ));
    }
    for (final d in discoveredInZone) {
      activities.add(ZoneActivity(
        type: ZoneActivityType.discovery,
        description: d.name,
        timestamp: d.discoveredAt!,
      ));
    }
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final recentActivity = activities.take(5).toList();

    return ZoneStats(
      streetsWalkedCount: zoneStreets.length,
      discoveryCount: discoveredInZone.length,
      discoveriesByCategory: discoveriesByCategory,
      discoveriesByRarity: discoveriesByRarity,
      totalDistanceMeters: totalDistance,
      masteryStates: masteryStates,
      explorationPct: explorationPct,
      recentActivity: recentActivity,
    );
  }

  // ---------------------------------------------------------------------------
  // Private geo-filtering helpers
  // ---------------------------------------------------------------------------

  /// Returns true if [point] is within [radiusMeters] of [centre].
  ///
  /// First checks a bounding box for fast rejection, then uses Haversine.
  bool _isWithinRadius(LatLng point, LatLng centre, double radiusMeters) {
    // Bounding box pre-filter
    final latDelta = radiusMeters * _degPerMeter;
    final lngDelta =
        radiusMeters * _degPerMeter / math.cos(centre.latitude * math.pi / 180);

    if ((point.latitude - centre.latitude).abs() > latDelta) return false;
    if ((point.longitude - centre.longitude).abs() > lngDelta) return false;

    // Precise Haversine check
    return dc.DistanceCalculator.haversine(point, centre) <= radiusMeters;
  }

  /// Returns streets where at least one node falls within the zone radius.
  List<Street> _filterStreets(
    List<Street> streets,
    LatLng centre,
    double radius,
  ) {
    return streets.where((street) {
      return street.nodes.any((node) => _isWithinRadius(node, centre, radius));
    }).toList();
  }

  /// Returns discoveries whose position falls within the zone radius.
  List<Discovery> _filterDiscoveriesByProximity(
    List<Discovery> discoveries,
    LatLng centre,
    double radius,
  ) {
    return discoveries.where((d) {
      return _isWithinRadius(d.position, centre, radius);
    }).toList();
  }

  /// Returns walks where at least one point falls within the zone radius.
  List<WalkSession> _filterWalks(
    List<WalkSession> walks,
    LatLng centre,
    double radius,
  ) {
    return walks.where((walk) {
      return walk.points
          .any((p) => _isWithinRadius(p.position, centre, radius));
    }).toList();
  }
}
