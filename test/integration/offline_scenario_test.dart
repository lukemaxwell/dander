/// Integration test: simulates full offline walk scenario.
///
/// Flow:
///   1. App initialises (first launch)
///   2. POIs are loaded (simulating initial online fetch)
///   3. Connectivity goes offline
///   4. User walks — fog clears and discoveries trigger
///   5. All state is readable from local storage after "restart"
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:latlong2/latlong.dart';
import 'package:hive/hive.dart';

import 'package:dander/core/app/app_initializer.dart';
import 'package:dander/core/network/connectivity_service.dart';
import 'package:dander/core/storage/app_state_repository.dart';
import 'package:dander/core/sync/sync_service.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockBox extends Mock implements Box<dynamic> {}

class MockAppStateRepository extends Mock implements AppStateRepository {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// In-memory implementation of AppStateRepository for integration testing.
class InMemoryAppStateRepository implements AppStateRepository {
  LatLng? _lastPosition;
  NeighbourhoodBounds? _bounds;
  bool _firstLaunchComplete = false;

  @override
  Future<void> saveLastPosition(LatLng position) async {
    _lastPosition = position;
  }

  @override
  Future<LatLng?> getLastPosition() async => _lastPosition;

  @override
  Future<void> saveNeighbourhoodBounds(NeighbourhoodBounds bounds) async {
    _bounds = bounds;
  }

  @override
  Future<NeighbourhoodBounds?> getNeighbourhoodBounds() async => _bounds;

  @override
  Future<void> markFirstLaunchComplete() async {
    _firstLaunchComplete = true;
  }

  @override
  Future<bool> isFirstLaunch() async => !_firstLaunchComplete;

  bool _firstWalkContractCompleted = false;
  bool _firstWalkContractDismissed = false;

  @override
  Future<void> markFirstWalkContractCompleted() async {
    _firstWalkContractCompleted = true;
  }

  @override
  Future<bool> isFirstWalkContractCompleted() async =>
      _firstWalkContractCompleted;

  @override
  Future<void> markFirstWalkContractDismissed() async {
    _firstWalkContractDismissed = true;
  }

  @override
  Future<bool> isFirstWalkContractDismissed() async =>
      _firstWalkContractDismissed;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('Offline walk scenario — integration', () {
    late InMemoryAppStateRepository appStateRepo;
    late AlwaysOfflineConnectivityService offlineConnectivity;

    setUp(() {
      appStateRepo = InMemoryAppStateRepository();
      offlineConnectivity = AlwaysOfflineConnectivityService();
    });

    test('first launch is detected correctly', () async {
      final initializer = AppInitializer(appStateRepository: appStateRepo);
      final result = await initializer.initialize();

      expect(result.isFirstLaunch, isTrue);
      expect(result.lastKnownPosition, isNull);
    });

    test('after marking first launch complete, isFirstLaunch returns false',
        () async {
      await appStateRepo.markFirstLaunchComplete();

      final initializer = AppInitializer(appStateRepository: appStateRepo);
      final result = await initializer.initialize();

      expect(result.isFirstLaunch, isFalse);
    });

    test('position persists across simulated app restart', () async {
      // "First launch" — save position
      const position = LatLng(51.5074, -0.1278);
      await appStateRepo.saveLastPosition(position);
      await appStateRepo.markFirstLaunchComplete();

      // "App restart" — read back position
      final initializer = AppInitializer(appStateRepository: appStateRepo);
      final result = await initializer.initialize();

      expect(result.isFirstLaunch, isFalse);
      expect(result.lastKnownPosition, isNotNull);
      expect(
        result.lastKnownPosition!.latitude,
        closeTo(position.latitude, 0.0001),
      );
      expect(
        result.lastKnownPosition!.longitude,
        closeTo(position.longitude, 0.0001),
      );
    });

    test('bounds persist across simulated app restart', () async {
      const bounds = NeighbourhoodBounds(
        southWestLat: 51.4,
        southWestLng: -0.2,
        northEastLat: 51.6,
        northEastLng: 0.0,
      );
      await appStateRepo.saveNeighbourhoodBounds(bounds);
      await appStateRepo.markFirstLaunchComplete();

      final stored = await appStateRepo.getNeighbourhoodBounds();

      expect(stored, isNotNull);
      expect(stored!.southWestLat, closeTo(bounds.southWestLat, 0.0001));
      expect(stored.northEastLat, closeTo(bounds.northEastLat, 0.0001));
    });

    test('SyncService does NOT call poiSyncCallback when offline', () async {
      var syncCalled = false;
      final service = SyncService(
        connectivity: offlineConnectivity,
        appStateRepository: appStateRepo,
        poiSyncCallback: (_) async {
          syncCalled = true;
        },
      );

      // Simulate connectivity check — offline service emits false
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(syncCalled, isFalse);
      await service.dispose();
    });

    test('walk positions can be saved and retrieved after multiple updates',
        () async {
      final positions = [
        const LatLng(51.5074, -0.1278),
        const LatLng(51.5075, -0.1279),
        const LatLng(51.5076, -0.1280),
      ];

      for (final pos in positions) {
        await appStateRepo.saveLastPosition(pos);
      }

      final finalPosition = await appStateRepo.getLastPosition();
      // Should have the last saved position
      expect(finalPosition, isNotNull);
      expect(
        finalPosition!.latitude,
        closeTo(positions.last.latitude, 0.0001),
      );
    });

    test('full offline flow: init → store bounds → walk → verify', () async {
      // Step 1: First launch
      final initializer = AppInitializer(appStateRepository: appStateRepo);
      final initResult = await initializer.initialize();
      expect(initResult.isFirstLaunch, isTrue);

      // Step 2: Store neighbourhood bounds (simulating initial online load)
      const bounds = NeighbourhoodBounds(
        southWestLat: 51.4,
        southWestLng: -0.2,
        northEastLat: 51.6,
        northEastLng: 0.0,
      );
      await appStateRepo.saveNeighbourhoodBounds(bounds);
      await appStateRepo.markFirstLaunchComplete();

      // Step 3: Verify offline connectivity
      expect(await offlineConnectivity.isOnline, isFalse);

      // Step 4: Simulate walking (position updates)
      const walkPositions = [
        LatLng(51.501, -0.12),
        LatLng(51.502, -0.13),
        LatLng(51.503, -0.14),
      ];

      for (final pos in walkPositions) {
        await appStateRepo.saveLastPosition(pos);
      }

      // Step 5: Simulate restart and verify data survives
      final restartResult = await initializer.initialize();
      expect(restartResult.isFirstLaunch, isFalse);
      expect(restartResult.lastKnownPosition, isNotNull);
      expect(
        restartResult.lastKnownPosition!.latitude,
        closeTo(walkPositions.last.latitude, 0.0001),
      );

      final storedBounds = await appStateRepo.getNeighbourhoodBounds();
      expect(storedBounds, isNotNull);
      expect(
        storedBounds!.southWestLat,
        closeTo(bounds.southWestLat, 0.0001),
      );
    });

    test('isOnlineStream from AlwaysOfflineConnectivityService emits false',
        () async {
      final first = await offlineConnectivity.isOnlineStream.first;
      expect(first, isFalse);
    });

    test('AlwaysOnlineConnectivityService emits true', () async {
      final online = AlwaysOnlineConnectivityService();
      final first = await online.isOnlineStream.first;
      expect(first, isTrue);
    });
  });
}
