import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/discoveries/discovery_repository.dart';
import 'package:dander/core/discoveries/discovery_service.dart';
import 'package:dander/core/discoveries/overpass_client.dart';

class MockOverpassClient extends Mock implements OverpassClient {}

class MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

void main() {
  late MockOverpassClient mockClient;
  late MockDiscoveryRepository mockRepo;
  late DiscoveryService service;

  final bounds = LatLngBounds(
    const LatLng(51.50, -0.13),
    const LatLng(51.52, -0.11),
  );

  // ~22 m north of (51.5074, -0.1278) — within 30 m radius
  const nearbyPosition = LatLng(51.5074, -0.1278);
  const poiPosition = LatLng(51.5076, -0.1278);

  setUpAll(() {
    registerFallbackValue(bounds);
    registerFallbackValue(const LatLng(0, 0));
    registerFallbackValue(DateTime(2024));
  });

  setUp(() {
    mockClient = MockOverpassClient();
    mockRepo = MockDiscoveryRepository();
    service = DiscoveryService(
      overpassClient: mockClient,
      repository: mockRepo,
    );
  });

  Discovery buildPoi({
    String id = 'node/1',
    LatLng? position,
    DateTime? discoveredAt,
  }) {
    return Discovery(
      id: id,
      name: 'Test POI',
      category: 'cafe',
      rarity: RarityTier.common,
      position: position ?? poiPosition,
      osmTags: const {'amenity': 'cafe'},
      discoveredAt: discoveredAt,
    );
  }

  // ---------------------------------------------------------------------------
  // loadPOIsForArea
  // ---------------------------------------------------------------------------
  group('loadPOIsForArea', () {
    test('fetches from Overpass when no cache exists', () async {
      when(() => mockRepo.hasCache(any())).thenAnswer((_) async => false);
      when(() => mockClient.fetchPOIs(any())).thenAnswer((_) async => []);
      when(() => mockRepo.savePOIs(any(), any())).thenAnswer((_) async {});

      await service.loadPOIsForArea(bounds);

      verify(() => mockClient.fetchPOIs(any())).called(1);
    });

    test('saves fetched POIs to repository', () async {
      final pois = [buildPoi()];
      when(() => mockRepo.hasCache(any())).thenAnswer((_) async => false);
      when(() => mockClient.fetchPOIs(any())).thenAnswer((_) async => pois);
      when(() => mockRepo.savePOIs(any(), any())).thenAnswer((_) async {});

      await service.loadPOIsForArea(bounds);

      verify(() => mockRepo.savePOIs(any(), any())).called(1);
    });

    test('uses cached data when cache exists (no Overpass call)', () async {
      when(() => mockRepo.hasCache(any())).thenAnswer((_) async => true);
      when(() => mockRepo.getPOIs(any())).thenAnswer((_) async => [buildPoi()]);

      await service.loadPOIsForArea(bounds);

      verifyNever(() => mockClient.fetchPOIs(any()));
    });
  });

  // ---------------------------------------------------------------------------
  // getDiscoveries
  // ---------------------------------------------------------------------------
  group('getDiscoveries', () {
    test('delegates to repository.getPOIs with current bounds', () async {
      when(() => mockRepo.hasCache(any())).thenAnswer((_) async => false);
      when(() => mockClient.fetchPOIs(any())).thenAnswer((_) async => []);
      when(() => mockRepo.savePOIs(any(), any())).thenAnswer((_) async {});
      when(() => mockRepo.getPOIs(any())).thenAnswer((_) async => [buildPoi()]);

      await service.loadPOIsForArea(bounds);
      final result = await service.getDiscoveries();

      expect(result, hasLength(1));
    });

    test('returns empty list when no POIs loaded yet', () async {
      when(() => mockRepo.getPOIs(any())).thenAnswer((_) async => []);

      final result = await service.getDiscoveries();
      expect(result, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // processLocationUpdate — discovery stream
  // ---------------------------------------------------------------------------
  group('processLocationUpdate', () {
    test('emits discovery on stream when user enters POI radius', () async {
      final poi = buildPoi(position: poiPosition);

      when(() => mockRepo.getPOIs(any())).thenAnswer((_) async => [poi]);
      when(() => mockRepo.markDiscovered(any(), any()))
          .thenAnswer((_) async {});

      // Collect stream emissions.
      final emitted = <Discovery>[];
      final sub = service.discoveryStream.listen(emitted.add);

      await service.processLocationUpdate(nearbyPosition);

      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(emitted, hasLength(1));
      expect(emitted.first.id, equals('node/1'));
    });

    test('marks discovered in repository when discovery triggered', () async {
      final poi = buildPoi(position: poiPosition);

      when(() => mockRepo.getPOIs(any())).thenAnswer((_) async => [poi]);
      when(() => mockRepo.markDiscovered(any(), any()))
          .thenAnswer((_) async {});

      final sub = service.discoveryStream.listen((_) {});
      await service.processLocationUpdate(nearbyPosition);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      verify(() => mockRepo.markDiscovered('node/1', any())).called(1);
    });

    test('does not emit when user is outside POI radius', () async {
      // Far position, ~1km north
      const farPosition = LatLng(51.517, -0.1278);
      final poi = buildPoi(position: poiPosition);

      when(() => mockRepo.getPOIs(any())).thenAnswer((_) async => [poi]);

      final emitted = <Discovery>[];
      final sub = service.discoveryStream.listen(emitted.add);

      await service.processLocationUpdate(farPosition);

      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(emitted, isEmpty);
    });

    test('does not emit for already-discovered POIs', () async {
      final discoveredPoi = buildPoi(
        position: poiPosition,
        discoveredAt: DateTime(2024, 1, 1),
      );

      // Repository returns already-discovered POI.
      when(() => mockRepo.getPOIs(any()))
          .thenAnswer((_) async => [discoveredPoi]);

      final emitted = <Discovery>[];
      final sub = service.discoveryStream.listen(emitted.add);

      await service.processLocationUpdate(nearbyPosition);

      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(emitted, isEmpty);
    });

    test('emits multiple discoveries when multiple POIs are within radius',
        () async {
      const nearPos1 = LatLng(51.5076, -0.1278);
      const nearPos2 = LatLng(51.5075, -0.1279);
      final poi1 = buildPoi(id: 'node/1', position: nearPos1);
      final poi2 = buildPoi(id: 'node/2', position: nearPos2);

      when(() => mockRepo.getPOIs(any())).thenAnswer((_) async => [poi1, poi2]);
      when(() => mockRepo.markDiscovered(any(), any()))
          .thenAnswer((_) async {});

      final emitted = <Discovery>[];
      final sub = service.discoveryStream.listen(emitted.add);

      await service.processLocationUpdate(nearbyPosition);

      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(emitted, hasLength(2));
    });

    test('discoveryStream is a broadcast stream (supports multiple listeners)',
        () async {
      when(() => mockRepo.getPOIs(any())).thenAnswer((_) async => []);

      final sub1 = service.discoveryStream.listen((_) {});
      final sub2 = service.discoveryStream.listen((_) {});

      // Should not throw StateError about single-subscription stream.
      await sub1.cancel();
      await sub2.cancel();
    });
  });
}
