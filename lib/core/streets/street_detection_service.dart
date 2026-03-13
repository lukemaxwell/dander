import 'dart:async';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../location/distance_calculator.dart' as calc;
import 'street.dart';
import 'street_repository.dart';

/// Detects when the user walks along a street based on GPS position updates.
///
/// On each position update, checks all unwalked cached streets. When the
/// user's position comes within [detectionRadiusMeters] of any node on a
/// street, that street is marked as walked and emitted on [newlyWalkedStreets].
///
/// Streets already walked (either before or during this session) are never
/// re-emitted.
class StreetDetectionService {
  StreetDetectionService({
    required StreetRepository streetRepository,
    required Stream<LatLng> positionStream,
  })  : _streetRepository = streetRepository,
        _positionStream = positionStream;

  static const double detectionRadiusMeters = 20.0;

  final StreetRepository _streetRepository;
  final Stream<LatLng> _positionStream;

  final StreamController<Street> _walkedController =
      StreamController<Street>.broadcast();

  StreamSubscription<LatLng>? _positionSub;

  /// In-memory cache of unwalked streets to avoid Hive reads on every GPS update.
  List<Street> _unwalkedStreets = [];

  /// IDs of streets walked during this session (prevents re-emission).
  final Set<String> _walkedThisSession = {};

  /// Broadcasts newly walked [Street] instances as the user walks.
  Stream<Street> get newlyWalkedStreets => _walkedController.stream;

  /// Starts listening to position updates and detecting street walks.
  ///
  /// Loads unwalked streets from the local cache for [bounds] before
  /// subscribing to the position stream.
  Future<void> start(LatLngBounds bounds) async {
    final allStreets = await _streetRepository.getStreets(bounds);
    _unwalkedStreets = allStreets.where((s) => !s.isWalked).toList();
    _walkedThisSession.clear();

    _positionSub = _positionStream.listen(_onPosition);
  }

  /// Stops listening to position updates.
  ///
  /// The [newlyWalkedStreets] stream remains open; call [dispose] to close it.
  Future<void> stop() async {
    await _positionSub?.cancel();
    _positionSub = null;
  }

  /// Cancels the position subscription and closes the walked stream.
  Future<void> dispose() async {
    await stop();
    await _walkedController.close();
  }

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  void _onPosition(LatLng position) {
    final toRemove = <Street>[];

    for (final street in _unwalkedStreets) {
      if (_walkedThisSession.contains(street.id)) continue;
      if (_isNearStreet(position, street)) {
        _walkedThisSession.add(street.id);
        toRemove.add(street);
        final walkedStreet = street.markWalked(DateTime.now());
        _streetRepository.markWalked(street.id, walkedStreet.walkedAt!);
        _walkedController.add(walkedStreet);
      }
    }

    if (toRemove.isNotEmpty) {
      _unwalkedStreets = _unwalkedStreets
          .where((s) => !toRemove.any((r) => r.id == s.id))
          .toList();
    }
  }

  /// Returns `true` if [position] is within [detectionRadiusMeters] of any
  /// node in [street].
  bool _isNearStreet(LatLng position, Street street) {
    for (final node in street.nodes) {
      final distance = calc.DistanceCalculator.haversine(position, node);
      if (distance <= detectionRadiusMeters) return true;
    }
    return false;
  }
}
