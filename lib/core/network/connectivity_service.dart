import 'package:connectivity_plus/connectivity_plus.dart';

// ---------------------------------------------------------------------------
// Abstract interface
// ---------------------------------------------------------------------------

/// Provides network connectivity status.
///
/// The abstract interface is kept minimal so that production code and tests
/// both depend on the same contract without importing platform packages.
abstract interface class ConnectivityService {
  /// Emits `true` when the device comes online, `false` when it goes offline.
  Stream<bool> get isOnlineStream;

  /// Returns the current connectivity status as a one-shot [Future].
  Future<bool> get isOnline;
}

// ---------------------------------------------------------------------------
// Production implementation
// ---------------------------------------------------------------------------

/// Production implementation backed by the [connectivity_plus] package.
class ConnectivityServiceImpl implements ConnectivityService {
  ConnectivityServiceImpl() : _connectivity = Connectivity();

  final Connectivity _connectivity;

  @override
  Stream<bool> get isOnlineStream => _connectivity.onConnectivityChanged.map(
        (results) => _resultsToOnline(results),
      );

  @override
  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return _resultsToOnline(results);
  }

  static bool _resultsToOnline(List<ConnectivityResult> results) => results.any(
        (r) =>
            r == ConnectivityResult.wifi ||
            r == ConnectivityResult.mobile ||
            r == ConnectivityResult.ethernet,
      );
}

// ---------------------------------------------------------------------------
// Test / stub implementations
// ---------------------------------------------------------------------------

/// Always-online stub — useful for tests and offline-not-yet-implemented paths.
class AlwaysOnlineConnectivityService implements ConnectivityService {
  @override
  Stream<bool> get isOnlineStream => Stream.value(true);

  @override
  Future<bool> get isOnline async => true;
}

/// Always-offline stub — used in offline integration tests.
class AlwaysOfflineConnectivityService implements ConnectivityService {
  @override
  Stream<bool> get isOnlineStream => Stream.value(false);

  @override
  Future<bool> get isOnline async => false;
}
