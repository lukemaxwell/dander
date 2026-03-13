import 'package:latlong2/latlong.dart';

import '../storage/app_state_repository.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// App-wide constants related to initialisation (used by tile cache config
/// and startup checks).
abstract final class AppInitializerConstants {
  /// Maximum age of a cached map tile before it is considered stale.
  static const int maxTileAgeDays = 7;

  /// Maximum on-disk size of the tile cache in megabytes.
  static const int maxCacheSizeMb = 100;
}

// ---------------------------------------------------------------------------
// Result value object
// ---------------------------------------------------------------------------

/// Immutable result returned by [AppInitializer.initialize].
class InitResult {
  const InitResult({
    required this.isFirstLaunch,
    required this.lastKnownPosition,
  });

  /// Whether this is the first time the app has been launched on this device.
  final bool isFirstLaunch;

  /// The last GPS position the app recorded, or `null` on first launch.
  final LatLng? lastKnownPosition;
}

// ---------------------------------------------------------------------------
// App initializer
// ---------------------------------------------------------------------------

/// Handles app startup logic: detects first launch and retrieves last state.
///
/// In production this is also responsible for opening all required Hive boxes.
/// The Hive opening itself is done outside this class (in [main]) so that
/// tests can inject a pre-configured [AppStateRepository] without touching the
/// filesystem.
class AppInitializer {
  const AppInitializer({required AppStateRepository appStateRepository})
      : _appStateRepository = appStateRepository;

  final AppStateRepository _appStateRepository;

  /// Reads persisted state and returns an [InitResult].
  ///
  /// Calls [AppStateRepository.isFirstLaunch] and
  /// [AppStateRepository.getLastPosition] exactly once each.
  Future<InitResult> initialize() async {
    final firstLaunch = await _appStateRepository.isFirstLaunch();
    final lastPosition = await _appStateRepository.getLastPosition();

    return InitResult(
      isFirstLaunch: firstLaunch,
      lastKnownPosition: lastPosition,
    );
  }
}
