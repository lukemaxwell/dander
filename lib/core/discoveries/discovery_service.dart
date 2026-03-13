import 'dart:async';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'discovery.dart';
import 'discovery_repository.dart';
import 'overpass_client.dart';
import 'proximity_detector.dart';

/// Coordinates POI loading, caching, proximity detection, and discovery
/// event emission.
///
/// Listen to [discoveryStream] to receive a [Discovery] each time the user
/// enters the proximity radius of a previously undiscovered POI.
class DiscoveryService {
  DiscoveryService({
    required OverpassClient overpassClient,
    required DiscoveryRepository repository,
  })  : _client = overpassClient,
        _repo = repository;

  final OverpassClient _client;
  final DiscoveryRepository _repo;

  LatLngBounds? _currentBounds;

  final StreamController<Discovery> _discoveryController =
      StreamController<Discovery>.broadcast();

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Emits a [Discovery] each time the user enters the proximity radius of an
  /// undiscovered POI.
  ///
  /// This is a broadcast stream; multiple listeners are supported.
  Stream<Discovery> get discoveryStream => _discoveryController.stream;

  /// Loads POIs for [bounds], using the local cache when available.
  ///
  /// When no cache is present, queries the Overpass API and persists the
  /// result.  Subsequent calls for the same bounds serve the cache.
  Future<void> loadPOIsForArea(LatLngBounds bounds) async {
    _currentBounds = bounds;
    final cached = await _repo.hasCache(bounds);
    if (!cached) {
      final pois = await _client.fetchPOIs(bounds);
      await _repo.savePOIs(pois);
    }
  }

  /// Returns all [Discovery] records for the currently loaded area.
  ///
  /// Returns an empty list if [loadPOIsForArea] has not yet been called or
  /// no data is available.
  Future<List<Discovery>> getDiscoveries() async {
    if (_currentBounds == null) {
      return _repo.getPOIs(
        LatLngBounds(const LatLng(0, 0), const LatLng(0, 0)),
      );
    }
    return _repo.getPOIs(_currentBounds!);
  }

  /// Evaluates [position] against cached undiscovered POIs.
  ///
  /// Any POI within [ProximityDetector.discoveryRadiusMeters] that has not
  /// yet been discovered is emitted on [discoveryStream] and persisted via
  /// [DiscoveryRepository.markDiscovered].
  Future<void> processLocationUpdate(LatLng position) async {
    final all = await getDiscoveries();
    final undiscovered = all.where((d) => !d.isDiscovered).toList();

    final triggered = ProximityDetector.detectNew(
      position,
      undiscovered,
      ProximityDetector.discoveryRadiusMeters,
    );

    final now = DateTime.now();
    for (final discovery in triggered) {
      await _repo.markDiscovered(discovery.id, now);
      _discoveryController.add(discovery);
    }
  }

  /// Releases resources.  Call when the service is no longer needed.
  Future<void> dispose() async {
    await _discoveryController.close();
  }
}
