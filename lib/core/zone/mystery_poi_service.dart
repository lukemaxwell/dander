import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../discoveries/overpass_client.dart';
import 'mystery_poi.dart';
import 'mystery_poi_repository.dart';

/// Maximum number of active (unrevealed) mystery POIs per zone.
const int _maxActivePois = 3;

/// Service that orchestrates mystery POI generation, retrieval, and arrival
/// detection.
class MysteryPoiService {
  MysteryPoiService({
    required MysteryPoiRepository repository,
    required OverpassClient overpassClient,
  })  : _repository = repository,
        _overpassClient = overpassClient;

  final MysteryPoiRepository _repository;
  final OverpassClient _overpassClient;

  /// Returns up to [_maxActivePois] unrevealed [MysteryPoi] for [zoneId].
  Future<List<MysteryPoi>> getActivePois(String zoneId) async {
    final all = await _repository.loadPois(zoneId);
    return all.where((p) => !p.isRevealed).take(_maxActivePois).toList();
  }

  /// Fetches POIs from the Overpass API within [radiusMeters] of [centre],
  /// picks a random selection of up to [_maxActivePois], and returns a list
  /// of new unrevealed [MysteryPoi].
  ///
  /// Optionally filters results by [category] (unused in current Overpass
  /// query but can be applied as a post-filter).
  Future<List<MysteryPoi>> generatePois(
    LatLng centre,
    double radiusMeters, {
    String? category,
  }) async {
    // Build a square bounding box around the centre that circumscribes the
    // circular radius.  1 degree ≈ 111 320 m at the equator.
    final latDelta = radiusMeters / 111320.0;
    final lngDelta =
        radiusMeters / (111320.0 * math.cos(centre.latitude * math.pi / 180.0));

    final bounds = LatLngBounds(
      LatLng(centre.latitude - latDelta, centre.longitude - lngDelta),
      LatLng(centre.latitude + latDelta, centre.longitude + lngDelta),
    );

    // Fetch from Overpass (may throw OverpassException — callers handle it).
    final discoveries = await _overpassClient.fetchPOIs(bounds);

    // Optional category post-filter.
    final filtered = category == null
        ? discoveries
        : discoveries.where((d) => d.category == category).toList();

    if (filtered.isEmpty) return [];

    // Pick a random selection capped at _maxActivePois.
    final rng = math.Random();
    final shuffled = List.of(filtered)..shuffle(rng);
    final selected = shuffled.take(_maxActivePois).toList();

    return selected
        .map(
          (d) => MysteryPoi(
            id: d.id,
            position: d.position,
            category: d.category,
            // name intentionally null — revealed on arrival
          ),
        )
        .toList();
  }

  /// Returns the first unrevealed [MysteryPoi] from [activePois] that the user
  /// has arrived at (within [thresholdMeters]), or `null` if none qualify.
  MysteryPoi? checkArrival(
    LatLng userPosition,
    List<MysteryPoi> activePois, {
    double thresholdMeters = 50.0,
  }) {
    for (final poi in activePois) {
      if (poi.isRevealed) continue;
      final dist = _haversineMeters(userPosition, poi.position);
      if (dist <= thresholdMeters) return poi;
    }
    return null;
  }

  /// Returns a new revealed [MysteryPoi] with [revealedName] set.
  ///
  /// Does not mutate [poi].
  MysteryPoi revealPoi(MysteryPoi poi, String revealedName) =>
      poi.reveal(revealedName);

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Haversine distance in metres between [a] and [b].
  ///
  /// Uses Earth radius 6 371 000 m, consistent with [ZoneDetector].
  double _haversineMeters(LatLng a, LatLng b) {
    const r = 6371000.0;
    final dLat = (b.latitude - a.latitude) * math.pi / 180.0;
    final dLng = (b.longitude - a.longitude) * math.pi / 180.0;
    final sinHalfLat = math.sin(dLat / 2);
    final sinHalfLng = math.sin(dLng / 2);
    final hav = sinHalfLat * sinHalfLat +
        math.cos(a.latitude * math.pi / 180.0) *
            math.cos(b.latitude * math.pi / 180.0) *
            sinHalfLng *
            sinHalfLng;
    return 2 * r * math.atan2(math.sqrt(hav), math.sqrt(1 - hav));
  }
}
