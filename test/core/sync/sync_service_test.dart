import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dander/core/sync/sync_service.dart';
import 'package:dander/core/network/connectivity_service.dart';
import 'package:dander/core/storage/app_state_repository.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockAppStateRepository extends Mock implements AppStateRepository {}

class MockPoiSyncCallback extends Mock {
  Future<void> call(NeighbourhoodBounds bounds);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockConnectivityService connectivity;
  late MockAppStateRepository appStateRepo;
  late StreamController<bool> connectivityController;

  setUp(() {
    connectivity = MockConnectivityService();
    appStateRepo = MockAppStateRepository();
    connectivityController = StreamController<bool>.broadcast();
    when(
      () => connectivity.isOnlineStream,
    ).thenAnswer((_) => connectivityController.stream);
  });

  tearDown(() async {
    await connectivityController.close();
  });

  group('SyncService — syncStream initial state', () {
    test('initial sync status is idle', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => false);

      final service = SyncService(
        connectivity: connectivity,
        appStateRepository: appStateRepo,
        poiSyncCallback: (_) async {},
      );

      expect(await service.syncStream.first, equals(SyncStatus.idle));
      await service.dispose();
    });
  });

  group('SyncService — syncPOIs', () {
    test('syncPOIs emits syncing then completed on success', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => true);

      final statuses = <SyncStatus>[];
      final service = SyncService(
        connectivity: connectivity,
        appStateRepository: appStateRepo,
        poiSyncCallback: (_) async {},
      );

      service.syncStream.listen(statuses.add);

      const bounds = NeighbourhoodBounds(
        southWestLat: 51.4,
        southWestLng: -0.2,
        northEastLat: 51.6,
        northEastLng: 0.0,
      );

      await service.syncPOIs(bounds);
      await Future<void>.delayed(Duration.zero);

      expect(statuses, contains(SyncStatus.syncing));
      expect(statuses, contains(SyncStatus.completed));
      await service.dispose();
    });

    test('syncPOIs emits failed when callback throws', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => true);

      final statuses = <SyncStatus>[];
      final service = SyncService(
        connectivity: connectivity,
        appStateRepository: appStateRepo,
        poiSyncCallback: (_) async => throw Exception('network error'),
      );

      service.syncStream.listen(statuses.add);

      const bounds = NeighbourhoodBounds(
        southWestLat: 51.4,
        southWestLng: -0.2,
        northEastLat: 51.6,
        northEastLng: 0.0,
      );

      await service.syncPOIs(bounds);
      await Future<void>.delayed(Duration.zero);

      expect(statuses, contains(SyncStatus.failed));
      await service.dispose();
    });

    test('syncPOIs calls poiSyncCallback with provided bounds', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => true);

      NeighbourhoodBounds? capturedBounds;
      const bounds = NeighbourhoodBounds(
        southWestLat: 48.8,
        southWestLng: 2.3,
        northEastLat: 48.9,
        northEastLng: 2.4,
      );

      final service = SyncService(
        connectivity: connectivity,
        appStateRepository: appStateRepo,
        poiSyncCallback: (b) async {
          capturedBounds = b;
        },
      );

      await service.syncPOIs(bounds);

      expect(capturedBounds, isNotNull);
      expect(capturedBounds!.southWestLat, closeTo(48.8, 0.0001));
      await service.dispose();
    });

    test('syncPOIs does not throw when callback succeeds', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => true);

      final service = SyncService(
        connectivity: connectivity,
        appStateRepository: appStateRepo,
        poiSyncCallback: (_) async {},
      );

      const bounds = NeighbourhoodBounds(
        southWestLat: 0,
        southWestLng: 0,
        northEastLat: 1,
        northEastLng: 1,
      );

      expect(() => service.syncPOIs(bounds), returnsNormally);
      await service.dispose();
    });
  });

  group('SyncService — auto-sync on connectivity restore', () {
    test('triggers sync when connectivity comes online and bounds stored',
        () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => false);
      when(() => appStateRepo.getNeighbourhoodBounds()).thenAnswer(
        (_) async => const NeighbourhoodBounds(
          southWestLat: 51.4,
          southWestLng: -0.2,
          northEastLat: 51.6,
          northEastLng: 0.0,
        ),
      );

      var syncCalled = false;
      final service = SyncService(
        connectivity: connectivity,
        appStateRepository: appStateRepo,
        poiSyncCallback: (_) async {
          syncCalled = true;
        },
      );

      // Simulate connectivity coming online
      connectivityController.add(true);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(syncCalled, isTrue);
      await service.dispose();
    });

    test('does not trigger sync when going offline', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => true);

      var syncCalled = false;
      final service = SyncService(
        connectivity: connectivity,
        appStateRepository: appStateRepo,
        poiSyncCallback: (_) async {
          syncCalled = true;
        },
      );

      connectivityController.add(false);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(syncCalled, isFalse);
      await service.dispose();
    });

    test('does not trigger sync when no bounds stored', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => false);
      when(
        () => appStateRepo.getNeighbourhoodBounds(),
      ).thenAnswer((_) async => null);

      var syncCalled = false;
      final service = SyncService(
        connectivity: connectivity,
        appStateRepository: appStateRepo,
        poiSyncCallback: (_) async {
          syncCalled = true;
        },
      );

      connectivityController.add(true);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(syncCalled, isFalse);
      await service.dispose();
    });
  });

  group('SyncStatus enum', () {
    test('has four values', () {
      expect(SyncStatus.values.length, equals(4));
    });

    test('contains idle', () {
      expect(SyncStatus.values, contains(SyncStatus.idle));
    });

    test('contains syncing', () {
      expect(SyncStatus.values, contains(SyncStatus.syncing));
    });

    test('contains completed', () {
      expect(SyncStatus.values, contains(SyncStatus.completed));
    });

    test('contains failed', () {
      expect(SyncStatus.values, contains(SyncStatus.failed));
    });
  });
}
