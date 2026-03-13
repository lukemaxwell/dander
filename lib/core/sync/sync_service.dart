import 'dart:async';

import 'package:flutter/foundation.dart';

import '../network/connectivity_service.dart';
import '../storage/app_state_repository.dart';

// ---------------------------------------------------------------------------
// Status enum
// ---------------------------------------------------------------------------

/// Represents the current state of a POI sync operation.
enum SyncStatus {
  /// No sync is running or queued.
  idle,

  /// A sync is currently in progress.
  syncing,

  /// The most-recent sync completed successfully.
  completed,

  /// The most-recent sync failed.
  failed,
}

// ---------------------------------------------------------------------------
// Sync service
// ---------------------------------------------------------------------------

/// Orchestrates online syncing of POI data.
///
/// Listens to [ConnectivityService.isOnlineStream] and automatically triggers
/// a POI sync when the device comes online, provided neighbourhood bounds have
/// been stored previously.
///
/// Call [dispose] when the service is no longer needed to cancel the
/// connectivity subscription.
class SyncService {
  SyncService({
    required ConnectivityService connectivity,
    required AppStateRepository appStateRepository,
    required Future<void> Function(NeighbourhoodBounds) poiSyncCallback,
  })  : _connectivity = connectivity,
        _appStateRepository = appStateRepository,
        _poiSyncCallback = poiSyncCallback {
    _subscribeToConnectivity();
  }

  final ConnectivityService _connectivity;
  final AppStateRepository _appStateRepository;
  final Future<void> Function(NeighbourhoodBounds) _poiSyncCallback;

  SyncStatus _lastStatus = SyncStatus.idle;

  // Using a single-subscription StreamController that replays the last value
  // to new subscribers by wrapping in _ReplaySubject-style logic.
  final _statusController = StreamController<SyncStatus>.broadcast();
  StreamSubscription<bool>? _connectivitySubscription;

  /// Broadcasts [SyncStatus] updates to subscribers.
  ///
  /// Always emits the current status immediately upon subscription, followed
  /// by any future updates.
  Stream<SyncStatus> get syncStream {
    // Capture current status at subscription time so new subscribers always
    // get a seed value without missing any events from the broadcast stream.
    final seed = _lastStatus;
    late StreamController<SyncStatus> output;
    StreamSubscription<SyncStatus>? upstream;

    output = StreamController<SyncStatus>(
      onListen: () {
        // Emit seed synchronously before any async events can arrive.
        output.add(seed);
        // Subscribe to future events from the broadcast controller.
        upstream = _statusController.stream.listen(
          output.add,
          onError: output.addError,
          onDone: output.close,
        );
      },
      onCancel: () {
        upstream?.cancel();
      },
    );

    return output.stream;
  }

  /// Syncs POIs for the given [bounds].
  ///
  /// Emits [SyncStatus.syncing] → [SyncStatus.completed] on success, or
  /// [SyncStatus.syncing] → [SyncStatus.failed] on error.
  Future<void> syncPOIs(NeighbourhoodBounds bounds) async {
    _emit(SyncStatus.syncing);
    try {
      await _poiSyncCallback(bounds);
      _emit(SyncStatus.completed);
    } catch (_) {
      _emit(SyncStatus.failed);
    }
  }

  void _emit(SyncStatus status) {
    _lastStatus = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  void _subscribeToConnectivity() {
    _connectivitySubscription = _connectivity.isOnlineStream.listen(
      (isOnline) async {
        if (!isOnline) return;
        final bounds = await _appStateRepository.getNeighbourhoodBounds();
        if (bounds == null) return;
        await syncPOIs(bounds);
      },
      onError: (Object error, StackTrace stack) {
        debugPrint('SyncService: connectivity stream error: $error');
        _emit(SyncStatus.failed);
      },
    );
  }

  /// Cancels the connectivity subscription and closes internal streams.
  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await _statusController.close();
  }
}
