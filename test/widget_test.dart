import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/app/app_initializer.dart';
import 'package:dander/core/network/connectivity_service.dart';
import 'package:dander/core/storage/app_state_repository.dart';
import 'package:dander/core/sync/sync_service.dart';
import 'package:dander/main.dart';

class _FakeConnectivityService implements ConnectivityService {
  @override
  Stream<bool> get isOnlineStream => const Stream.empty();

  @override
  Future<bool> get isOnline async => true;
}

class _FakeAppStateRepository implements AppStateRepository {
  @override
  Future<bool> isFirstLaunch() async => false;

  @override
  Future<void> markFirstLaunchComplete() async {}

  @override
  Future<NeighbourhoodBounds?> getNeighbourhoodBounds() async => null;

  @override
  Future<void> saveNeighbourhoodBounds(NeighbourhoodBounds bounds) async {}

  @override
  Future<LatLng?> getLastPosition() async => null;

  @override
  Future<void> saveLastPosition(LatLng position) async {}
}

void main() {
  testWidgets('DanderApp renders without throwing', (
    WidgetTester tester,
  ) async {
    const initResult = InitResult(
      isFirstLaunch: false,
      lastKnownPosition: null,
    );
    final syncService = SyncService(
      connectivity: _FakeConnectivityService(),
      appStateRepository: _FakeAppStateRepository(),
      poiSyncCallback: (_) async {},
    );

    await tester.pumpWidget(
      DanderApp(
        initResult: initResult,
        syncService: syncService,
      ),
    );
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
