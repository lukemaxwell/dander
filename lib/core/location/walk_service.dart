import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import 'location_service.dart';
import 'walk_repository.dart';
import 'walk_session.dart';

/// Thrown when [WalkService.startWalk] cannot obtain a location permission.
class LocationPermissionDeniedException implements Exception {
  const LocationPermissionDeniedException(
      [this.message = 'Location permission denied']);

  final String message;

  @override
  String toString() => 'LocationPermissionDeniedException: $message';
}

/// Manages the lifecycle of a walk session.
///
/// Call [startWalk] to begin tracking; the service subscribes to
/// [LocationService.positionStream] and accumulates [WalkPoint]s into an
/// immutable [WalkSession].  Each position update emits an updated session on
/// [sessionStream].  Call [stopWalk] to finalise the session and persist it
/// via [WalkRepository].
class WalkService {
  WalkService({
    required LocationService locationService,
    required WalkRepository repository,
    Uuid? uuid,
  })  : _location = locationService,
        _repo = repository,
        _uuid = uuid ?? const Uuid();

  final LocationService _location;
  final WalkRepository _repo;
  final Uuid _uuid;

  WalkSession? _session;
  StreamSubscription<Position>? _positionSub;
  final StreamController<WalkSession> _sessionController =
      StreamController<WalkSession>.broadcast();

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Emits an updated [WalkSession] each time a new GPS position is received.
  ///
  /// This is a broadcast stream; multiple subscribers are supported.
  Stream<WalkSession> get sessionStream => _sessionController.stream;

  /// The in-progress [WalkSession], or `null` when not walking.
  WalkSession? get currentSession => _session;

  /// Whether a walk is currently in progress.
  bool get isWalking => _session != null;

  /// Starts a new walk.
  ///
  /// Throws [LocationPermissionDeniedException] if permission cannot be
  /// obtained.  Throws [StateError] if a walk is already in progress.
  Future<void> startWalk() async {
    if (isWalking) {
      throw StateError('A walk is already in progress.');
    }

    // Ensure we have location permission.
    final alreadyGranted = await _location.hasPermission;
    if (!alreadyGranted) {
      final granted = await _location.requestPermission();
      if (!granted) {
        throw const LocationPermissionDeniedException();
      }
    }

    _session = WalkSession.start(
      id: _uuid.v4(),
      startTime: DateTime.now(),
    );

    _positionSub = _location.positionStream.listen(_onPosition);
  }

  /// Stops the active walk, persists it, and returns the completed session.
  ///
  /// Throws [StateError] if no walk is in progress.
  Future<WalkSession> stopWalk() async {
    if (!isWalking) {
      throw StateError('No walk is in progress.');
    }

    await _positionSub?.cancel();
    _positionSub = null;

    final completed = _session!.complete();
    _session = null;

    await _repo.saveWalk(completed);

    return completed;
  }

  /// Releases all resources held by this service.
  ///
  /// Cancels any active position subscription and closes [sessionStream].
  /// Must be called when the service is no longer needed to avoid resource
  /// leaks.
  Future<void> dispose() async {
    await _positionSub?.cancel();
    _positionSub = null;
    await _sessionController.close();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _onPosition(Position position) {
    if (!isWalking) return;

    final point = WalkPoint(
      position: LatLng(position.latitude, position.longitude),
      timestamp: position.timestamp,
    );

    _session = _session!.addPoint(point);
    _sessionController.add(_session!);
  }
}
