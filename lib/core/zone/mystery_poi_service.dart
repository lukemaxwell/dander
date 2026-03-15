import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../discoveries/overpass_client.dart';
import 'generate_result.dart';
import 'mystery_poi.dart';
import 'mystery_poi_repository.dart';
import 'poi_curator.dart';
import 'poi_wave_manager.dart';
import 'zone_detector.dart';

/// Maximum number of active (unrevealed) mystery POI *markers* shown on the
/// map at once.  This is separate from the wave size — waves determine how
/// many POIs from the curated set are "unlocked", while this cap limits the
/// number of visible `?` pins at any moment.
const int _maxActivePois = 3;

/// Default zone search radius in metres.
const double defaultSearchRadius = 750.0;

/// Density floor: minimum named POIs before expanding radius.
const int _densityFloor = 15;

/// Expanded radius when default yields too few POIs.
const double _expandedRadius = 1000.0;

/// Maximum radius for very sparse areas.
const double _maxRadius = 1500.0;

/// Minimum POI count at expanded radius before going to max.
const int _expandedFloor = 10;

/// Service that orchestrates mystery POI generation, retrieval, and arrival
/// detection.
class MysteryPoiService {
  MysteryPoiService({
    required MysteryPoiRepository repository,
    required OverpassClient overpassClient,
    ZoneDetector? zoneDetector,
  })  : _repository = repository,
        _overpassClient = overpassClient,
        _zoneDetector = zoneDetector ?? ZoneDetector();

  final MysteryPoiRepository _repository;
  final OverpassClient _overpassClient;
  final ZoneDetector _zoneDetector;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns up to [_maxActivePois] unrevealed [MysteryPoi] for [zoneId].
  Future<List<MysteryPoi>> getActivePois(String zoneId) async {
    final all = await _repository.loadPois(zoneId);
    return all.where((p) => !p.isRevealed).take(_maxActivePois).toList();
  }

  /// Loads cached POIs for [zoneId], or generates fresh ones from Overpass if
  /// no cache exists.  Results are persisted so subsequent calls return
  /// consistent data.
  ///
  /// Uses adaptive radius: starts at [defaultSearchRadius] (750 m), expands to
  /// 1000 m if the curated count is below [_densityFloor] (15), and further to
  /// 1500 m if still below [_expandedFloor] (10).
  ///
  /// When loading from cache, applies [PoiWaveManager.activeForWave] to return
  /// only the current wave's POIs (further capped to [_maxActivePois] markers).
  /// When generating fresh, curates via [PoiCurator], saves the full curated
  /// set, initialises wave 1, and returns wave-1 POIs.
  Future<GenerateResult> loadOrGenerate(
    String zoneId,
    LatLng centre, [
    double? radiusMeters,
  ]) async {
    final cachedPois = await _repository.loadPois(zoneId);
    final cachedCount = await _repository.loadTotalCount(zoneId);

    if (cachedPois.isNotEmpty && cachedCount != null) {
      return _loadFromCache(zoneId, cachedPois, cachedCount);
    }

    // No cache — generate fresh with adaptive radius.
    final radius = radiusMeters ?? defaultSearchRadius;
    var result = await generatePois(centre, radius);

    // Adaptive expansion: if too few POIs, try wider radius.
    if (result.totalCount < _densityFloor && radius <= defaultSearchRadius) {
      result = await generatePois(centre, _expandedRadius);
      if (result.totalCount < _expandedFloor) {
        result = await generatePois(centre, _maxRadius);
      }
    }

    await _repository.savePois(zoneId, result.activePois);
    await _repository.saveTotalCount(zoneId, result.totalCount);
    await _repository.saveWaveState(zoneId, 1, 0);
    return _activeResultFromWave(result.activePois, cachedCount: result.totalCount);
  }

  /// Fetches POIs from the Overpass API within [radiusMeters] of [centre],
  /// applies [PoiCurator.curate] to filter to high-quality results, then
  /// returns a [GenerateResult] where:
  ///   - [GenerateResult.activePois] = up to [_maxActivePois] unrevealed POIs.
  ///   - [GenerateResult.totalCount] = the curated count (not raw Overpass count).
  ///
  /// Optionally filters results by [category] as a post-filter before curation.
  Future<GenerateResult> generatePois(
    LatLng centre,
    double radiusMeters, {
    String? category,
  }) async {
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
    final categoryFiltered = category == null
        ? discoveries
        : discoveries.where((d) => d.category == category).toList();

    // Curate: name filter, scoring, tier allocation, category diversity, spacing.
    final curated = PoiCurator.curate(categoryFiltered);

    final totalCount = curated.length;

    if (curated.isEmpty) {
      return const GenerateResult(activePois: [], totalCount: 0);
    }

    // Pick up to _maxActivePois from the curated set for initial map markers.
    final rng = math.Random();
    final shuffled = List.of(curated)..shuffle(rng);
    final selected = shuffled.take(_maxActivePois).toList();

    final activePois = selected
        .map(
          (d) => MysteryPoi(
            id: d.id,
            position: d.position,
            category: d.category,
            // name intentionally null — revealed on arrival
          ),
        )
        .toList();

    return GenerateResult(activePois: activePois, totalCount: totalCount);
  }

  /// Called after a POI is revealed to check for wave progression.
  ///
  /// Increments [WaveState.discoveredInWave], checks the 50% unlock threshold
  /// via [PoiWaveManager.checkWaveUnlock], and persists the new wave state.
  /// If a new wave unlocks, [WaveState.discoveredInWave] resets to 0.
  ///
  /// Returns a [GenerateResult] with the updated active POI set.
  Future<GenerateResult> onPoiRevealed(String zoneId) async {
    final allPois = await _repository.loadPois(zoneId);
    final cachedCount = await _repository.loadTotalCount(zoneId);
    final waveState = await _repository.loadWaveState(zoneId);

    final currentWave = waveState?.currentWave ?? 1;
    final discoveredInWave = (waveState?.discoveredInWave ?? 0) + 1;

    final waveSize = PoiWaveManager.waveSize(currentWave);
    final effectiveWaveSize = waveSize > allPois.length
        ? allPois.length
        : waveSize;

    final newWave = PoiWaveManager.checkWaveUnlock(
      currentWave,
      discoveredInWave,
      effectiveWaveSize,
    );

    final waveUnlocked = newWave != currentWave;
    final newDiscoveredInWave = waveUnlocked ? 0 : discoveredInWave;

    await _repository.saveWaveState(zoneId, newWave, newDiscoveredInWave);

    return _activeResultFromWave(
      allPois,
      cachedCount: cachedCount ?? allPois.length,
      wave: newWave,
    );
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
      final dist = _zoneDetector.distanceBetween(userPosition, poi.position);
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

  /// Builds a [GenerateResult] from the cached full POI list at a given [wave].
  ///
  /// Applies [PoiWaveManager.activeForWave] to slice the wave's subset, then
  /// caps to [_maxActivePois] unrevealed for map marker display.
  Future<GenerateResult> _loadFromCache(
    String zoneId,
    List<MysteryPoi> allCached,
    int totalCount,
  ) async {
    final waveState = await _repository.loadWaveState(zoneId);
    final currentWave = waveState?.currentWave ?? 1;

    return _activeResultFromWave(
      allCached,
      cachedCount: totalCount,
      wave: currentWave,
    );
  }

  /// Derives the [GenerateResult] for the given [wave] from [allPois].
  GenerateResult _activeResultFromWave(
    List<MysteryPoi> allPois, {
    required int cachedCount,
    int wave = 1,
  }) {
    final waveActive = PoiWaveManager.activeForWave(allPois, wave);
    final unrevealed =
        waveActive.where((p) => !p.isRevealed).take(_maxActivePois).toList();
    return GenerateResult(activePois: unrevealed, totalCount: cachedCount);
  }
}
