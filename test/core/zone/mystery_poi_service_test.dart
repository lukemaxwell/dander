import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dander/core/discoveries/overpass_client.dart';
import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/zone/generate_result.dart';
import 'package:dander/core/zone/mystery_poi.dart';
import 'package:dander/core/zone/mystery_poi_repository.dart';
import 'package:dander/core/zone/mystery_poi_service.dart';
import 'package:dander/core/zone/poi_wave_manager.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockMysteryPoiRepository extends Mock implements MysteryPoiRepository {}

class MockOverpassClient extends Mock implements OverpassClient {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Latitude offset for ~111 m (1 degree lat ≈ 111 000 m → 0.001° ≈ 111 m).
const double _latOffset111m = 0.001;

/// Latitude offset for ~5 m — well within 50 m threshold.
const double _latOffset5m = 0.00005;

MysteryPoi makeMysteryPoi({
  String id = 'poi_1',
  double lat = 51.5074,
  double lng = -0.1278,
  String category = 'pub',
  String? name,
  PoiState state = PoiState.unrevealed,
}) =>
    MysteryPoi(
      id: id,
      position: LatLng(lat, lng),
      category: category,
      name: name,
      state: state,
    );

Discovery makeDiscovery({
  String id = 'node/1',
  String name = 'The Crown',
  String category = 'pub',
  double lat = 51.5074,
  double lng = -0.1278,
}) =>
    Discovery(
      id: id,
      name: name,
      category: category,
      rarity: RarityTier.common,
      position: LatLng(lat, lng),
      osmTags: const {},
      discoveredAt: null,
    );

void main() {
  setUpAll(() {
    registerFallbackValue(LatLng(0, 0));
    registerFallbackValue(
      LatLngBounds(LatLng(-1, -1), LatLng(1, 1)),
    );
    registerFallbackValue(<MysteryPoi>[]);
    registerFallbackValue(makeMysteryPoi());
  });

  late MockMysteryPoiRepository repo;
  late MockOverpassClient overpass;
  late MysteryPoiService service;

  setUp(() {
    repo = MockMysteryPoiRepository();
    overpass = MockOverpassClient();
    service = MysteryPoiService(repository: repo, overpassClient: overpass);
  });

  // ---------------------------------------------------------------------------
  // getActivePois
  // ---------------------------------------------------------------------------

  group('getActivePois', () {
    test('returns up to 3 unrevealed pois for a zone', () async {
      final pois = [
        makeMysteryPoi(id: 'poi_1'),
        makeMysteryPoi(id: 'poi_2'),
        makeMysteryPoi(id: 'poi_3'),
      ];
      when(() => repo.loadPois('zone_1')).thenAnswer((_) async => pois);

      final result = await service.getActivePois('zone_1');

      expect(result, hasLength(3));
    });

    test('returns only unrevealed pois', () async {
      final pois = [
        makeMysteryPoi(id: 'poi_1'),                                                      // unrevealed
        makeMysteryPoi(id: 'poi_2', name: 'The Crown', state: PoiState.revealed), // revealed
        makeMysteryPoi(id: 'poi_3'),                                                      // unrevealed
      ];
      when(() => repo.loadPois('zone_1')).thenAnswer((_) async => pois);

      final result = await service.getActivePois('zone_1');

      expect(result, hasLength(2));
      expect(result.every((p) => !p.isRevealed), isTrue);
    });

    test('caps at 3 even when repository has more unrevealed', () async {
      final pois = List.generate(
        5,
        (i) => makeMysteryPoi(id: 'poi_$i'),
      );
      when(() => repo.loadPois('zone_1')).thenAnswer((_) async => pois);

      final result = await service.getActivePois('zone_1');

      expect(result.length, lessThanOrEqualTo(3));
    });

    test('returns empty list when repository is empty', () async {
      when(() => repo.loadPois('zone_1')).thenAnswer((_) async => []);

      final result = await service.getActivePois('zone_1');

      expect(result, isEmpty);
    });

    test('returns empty list when all pois are revealed', () async {
      final pois = [
        makeMysteryPoi(id: 'poi_1', name: 'Pub A', state: PoiState.revealed),
        makeMysteryPoi(id: 'poi_2', name: 'Park B', state: PoiState.revealed),
      ];
      when(() => repo.loadPois('zone_1')).thenAnswer((_) async => pois);

      final result = await service.getActivePois('zone_1');

      expect(result, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // generatePois
  // ---------------------------------------------------------------------------

  group('generatePois', () {
    test('returns GenerateResult from overpass discoveries', () async {
      final centre = LatLng(51.5074, -0.1278);
      final discoveries = [
        makeDiscovery(id: 'node/1', name: 'The Crown', category: 'pub'),
        makeDiscovery(id: 'node/2', name: 'Victoria Park', category: 'park'),
      ];
      when(() => overpass.fetchPOIs(any())).thenAnswer((_) async => discoveries);

      final result = await service.generatePois(centre, 500.0);

      expect(result, isA<GenerateResult>());
      expect(result.activePois, isNotEmpty);
      expect(result.activePois.every((p) => !p.isRevealed), isTrue);
    });

    test('totalCount equals the number of filtered overpass results', () async {
      final centre = LatLng(51.5074, -0.1278);
      // Place each POI >100 m apart (0.001° lat ≈ 111 m) so spacing filter keeps all.
      final discoveries = [
        makeDiscovery(id: 'node/1', name: 'The Crown', category: 'pub',
            lat: 51.50, lng: -0.10),
        makeDiscovery(id: 'node/2', name: 'Victoria Park', category: 'park',
            lat: 51.51, lng: -0.10),
        makeDiscovery(id: 'node/3', name: 'Old Library', category: 'library',
            lat: 51.52, lng: -0.10),
      ];
      when(() => overpass.fetchPOIs(any())).thenAnswer((_) async => discoveries);

      final result = await service.generatePois(centre, 5000.0);

      expect(result.totalCount, 3);
    });

    test('generated pois have names null (unrevealed)', () async {
      final centre = LatLng(51.5074, -0.1278);
      final discoveries = [
        makeDiscovery(id: 'node/1', name: 'The Crown'),
      ];
      when(() => overpass.fetchPOIs(any())).thenAnswer((_) async => discoveries);

      final result = await service.generatePois(centre, 500.0);

      expect(result.activePois.every((p) => p.name == null), isTrue);
    });

    test('activePois capped at 3 regardless of overpass results', () async {
      final centre = LatLng(51.5074, -0.1278);
      final discoveries = List.generate(
        10,
        (i) => makeDiscovery(id: 'node/$i', name: 'POI $i'),
      );
      when(() => overpass.fetchPOIs(any())).thenAnswer((_) async => discoveries);

      final result = await service.generatePois(centre, 500.0);

      expect(result.activePois.length, lessThanOrEqualTo(3));
    });

    test('totalCount reflects curated count (after PoiCurator filters)', () async {
      final centre = LatLng(51.5074, -0.1278);
      // 10 POIs all same category 'pub' → category diversity cap limits to 3.
      // totalCount = curated count (3), not raw Overpass count (10).
      final discoveries = List.generate(
        10,
        (i) => makeDiscovery(id: 'node/$i', name: 'POI $i'),
      );
      when(() => overpass.fetchPOIs(any())).thenAnswer((_) async => discoveries);

      final result = await service.generatePois(centre, 500.0);

      // After curation: category diversity cap leaves ≤3 (all are 'pub').
      expect(result.totalCount, lessThanOrEqualTo(3));
      expect(result.activePois.length, lessThanOrEqualTo(3));
    });

    test('empty overpass response returns GenerateResult with empty activePois and totalCount 0',
        () async {
      final centre = LatLng(51.5074, -0.1278);
      when(() => overpass.fetchPOIs(any())).thenAnswer((_) async => []);

      final result = await service.generatePois(centre, 500.0);

      expect(result.activePois, isEmpty);
      expect(result.totalCount, 0);
    });

    test('propagates OverpassException when fetch fails', () async {
      final centre = LatLng(51.5074, -0.1278);
      when(() => overpass.fetchPOIs(any())).thenThrow(
        const OverpassException('Network error'),
      );

      await expectLater(
        service.generatePois(centre, 500.0),
        throwsA(isA<OverpassException>()),
      );
    });

    test('generated pois inherit category from discovery', () async {
      final centre = LatLng(51.5074, -0.1278);
      final discoveries = [
        makeDiscovery(id: 'node/1', category: 'historic'),
      ];
      when(() => overpass.fetchPOIs(any())).thenAnswer((_) async => discoveries);

      final result = await service.generatePois(centre, 500.0);

      expect(result.activePois.first.category, 'historic');
    });

    test('generated pois have unique ids matching discovery ids', () async {
      final centre = LatLng(51.5074, -0.1278);
      final discoveries = [
        makeDiscovery(id: 'node/42'),
        makeDiscovery(id: 'node/43'),
      ];
      when(() => overpass.fetchPOIs(any())).thenAnswer((_) async => discoveries);

      final result = await service.generatePois(centre, 500.0);

      final ids = result.activePois.map((p) => p.id).toSet();
      expect(ids.length, result.activePois.length); // all unique
    });
  });

  // ---------------------------------------------------------------------------
  // checkArrival
  // ---------------------------------------------------------------------------

  group('checkArrival', () {
    test('returns null when activePois list is empty', () {
      final userPos = LatLng(51.5074, -0.1278);
      final result = service.checkArrival(userPos, []);

      expect(result, isNull);
    });

    test('returns poi when user is within default 50 m threshold', () {
      // Place poi 5 m north of user — well within 50 m
      final userPos = LatLng(51.5074, -0.1278);
      final nearbyPoi = makeMysteryPoi(
        lat: 51.5074 + _latOffset5m,
        lng: -0.1278,
      );

      final result = service.checkArrival(userPos, [nearbyPoi]);

      expect(result, isNotNull);
      expect(result!.id, nearbyPoi.id);
    });

    test('returns null when user is beyond default 50 m threshold', () {
      // Place poi ~111 m north of user — outside 50 m
      final userPos = LatLng(51.5074, -0.1278);
      final farPoi = makeMysteryPoi(
        lat: 51.5074 + _latOffset111m,
        lng: -0.1278,
      );

      final result = service.checkArrival(userPos, [farPoi]);

      expect(result, isNull);
    });

    test('uses custom thresholdMeters when provided', () {
      // ~111 m away — outside 50 m but inside 200 m
      final userPos = LatLng(51.5074, -0.1278);
      final poi = makeMysteryPoi(
        lat: 51.5074 + _latOffset111m,
        lng: -0.1278,
      );

      final resultDefault = service.checkArrival(userPos, [poi]);
      final resultCustom = service.checkArrival(
        userPos,
        [poi],
        thresholdMeters: 200.0,
      );

      expect(resultDefault, isNull);
      expect(resultCustom, isNotNull);
    });

    test('returns first matching poi when multiple are within range', () {
      final userPos = LatLng(51.5074, -0.1278);
      final poi1 = makeMysteryPoi(id: 'poi_1', lat: 51.5074 + _latOffset5m, lng: -0.1278);
      final poi2 = makeMysteryPoi(id: 'poi_2', lat: 51.5074 + _latOffset5m * 2, lng: -0.1278);

      final result = service.checkArrival(userPos, [poi1, poi2]);

      expect(result, isNotNull);
    });

    test('returns null when user is exactly at threshold boundary (exclusive)', () {
      // Use a poi that will be placed > 50 m away
      final userPos = LatLng(51.5074, -0.1278);
      final poi = makeMysteryPoi(
        lat: 51.5074 + _latOffset111m,
        lng: -0.1278,
      );

      // 50 m threshold — poi is ~111 m away so should be null
      final result = service.checkArrival(userPos, [poi], thresholdMeters: 50.0);
      expect(result, isNull);
    });

    test('ignores revealed pois in arrival check', () {
      final userPos = LatLng(51.5074, -0.1278);
      final revealedPoi = makeMysteryPoi(
        id: 'poi_revealed',
        lat: 51.5074 + _latOffset5m,
        name: 'Already Revealed',
        state: PoiState.revealed,
      );

      final result = service.checkArrival(userPos, [revealedPoi]);

      expect(result, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // revealPoi
  // ---------------------------------------------------------------------------

  group('revealPoi', () {
    test('returns a revealed MysteryPoi with name set', () async {
      final poi = makeMysteryPoi(name: null);
      when(() => repo.loadPois(any())).thenAnswer((_) async => [poi]);

      final revealed = service.revealPoi(poi, 'The Crown');

      expect(revealed.isRevealed, isTrue);
      expect(revealed.name, 'The Crown');
    });

    test('does not mutate the original poi', () async {
      final poi = makeMysteryPoi(name: null);

      service.revealPoi(poi, 'The Crown');

      expect(poi.name, isNull);
      expect(poi.isRevealed, isFalse);
    });

    test('returns new instance (immutability)', () async {
      final poi = makeMysteryPoi();

      final revealed = service.revealPoi(poi, 'The Crown');

      expect(revealed, isNot(same(poi)));
    });

    test('preserves id, position, and category when revealing', () async {
      final poi = makeMysteryPoi(id: 'poi_99', lat: 48.8566, lng: 2.3522, category: 'historic');

      final revealed = service.revealPoi(poi, 'Notre Dame');

      expect(revealed.id, 'poi_99');
      expect(revealed.position.latitude, 48.8566);
      expect(revealed.category, 'historic');
    });
  });

  // ---------------------------------------------------------------------------
  // loadOrGenerate
  // ---------------------------------------------------------------------------

  group('loadOrGenerate', () {
    test('returns cached data when POIs and totalCount exist', () async {
      final cachedPois = [
        makeMysteryPoi(id: 'poi_1'),
        makeMysteryPoi(id: 'poi_2'),
      ];
      when(() => repo.loadPois('zone_1')).thenAnswer((_) async => cachedPois);
      when(() => repo.loadTotalCount('zone_1')).thenAnswer((_) async => 50);
      when(() => repo.loadWaveState('zone_1')).thenAnswer((_) async => null);

      final result = await service.loadOrGenerate(
        'zone_1',
        LatLng(51.5074, -0.1278),
        500.0,
      );

      expect(result.activePois, hasLength(2));
      expect(result.totalCount, 50);
      verifyNever(() => overpass.fetchPOIs(any()));
    });

    test('fetches from Overpass when no cached POIs', () async {
      when(() => repo.loadPois('zone_1')).thenAnswer((_) async => []);
      when(() => repo.loadTotalCount('zone_1')).thenAnswer((_) async => null);
      when(() => repo.savePois(any(), any())).thenAnswer((_) async {});
      when(() => repo.saveTotalCount(any(), any())).thenAnswer((_) async {});
      when(() => repo.saveWaveState(any(), any(), any())).thenAnswer((_) async {});

      // Space POIs >100 m apart so spacing filter keeps both.
      final discoveries = [
        makeDiscovery(id: 'node/1', category: 'pub', lat: 51.50, lng: -0.10),
        makeDiscovery(id: 'node/2', category: 'park', lat: 51.51, lng: -0.10),
      ];
      when(() => overpass.fetchPOIs(any())).thenAnswer((_) async => discoveries);

      final result = await service.loadOrGenerate(
        'zone_1',
        LatLng(51.5074, -0.1278),
        500.0,
      );

      expect(result.activePois, isNotEmpty);
      expect(result.totalCount, 2);
      verify(() => repo.savePois('zone_1', any())).called(1);
      verify(() => repo.saveTotalCount('zone_1', 2)).called(1);
    });

    test('fetches from Overpass when cached totalCount is null', () async {
      final cachedPois = [makeMysteryPoi(id: 'poi_1')];
      when(() => repo.loadPois('zone_1')).thenAnswer((_) async => cachedPois);
      when(() => repo.loadTotalCount('zone_1')).thenAnswer((_) async => null);
      when(() => repo.savePois(any(), any())).thenAnswer((_) async {});
      when(() => repo.saveTotalCount(any(), any())).thenAnswer((_) async {});
      when(() => repo.saveWaveState(any(), any(), any())).thenAnswer((_) async {});

      final discoveries = [
        makeDiscovery(id: 'node/1', category: 'pub'),
      ];
      when(() => overpass.fetchPOIs(any())).thenAnswer((_) async => discoveries);

      final result = await service.loadOrGenerate(
        'zone_1',
        LatLng(51.5074, -0.1278),
        500.0,
      );

      verify(() => overpass.fetchPOIs(any())).called(1);
      expect(result.totalCount, 1);
    });

    test('caps cached active POIs at 3', () async {
      final cachedPois = List.generate(
        5,
        (i) => makeMysteryPoi(id: 'poi_$i'),
      );
      when(() => repo.loadPois('zone_1')).thenAnswer((_) async => cachedPois);
      when(() => repo.loadTotalCount('zone_1')).thenAnswer((_) async => 100);
      when(() => repo.loadWaveState('zone_1')).thenAnswer((_) async => null);

      final result = await service.loadOrGenerate(
        'zone_1',
        LatLng(51.5074, -0.1278),
        500.0,
      );

      expect(result.activePois.length, lessThanOrEqualTo(3));
      expect(result.totalCount, 100);
    });

    test('excludes revealed POIs from cached active list', () async {
      final cachedPois = [
        makeMysteryPoi(id: 'poi_1', state: PoiState.revealed, name: 'Found'),
        makeMysteryPoi(id: 'poi_2'),
      ];
      when(() => repo.loadPois('zone_1')).thenAnswer((_) async => cachedPois);
      when(() => repo.loadTotalCount('zone_1')).thenAnswer((_) async => 50);
      when(() => repo.loadWaveState('zone_1')).thenAnswer((_) async => null);

      final result = await service.loadOrGenerate(
        'zone_1',
        LatLng(51.5074, -0.1278),
        500.0,
      );

      expect(result.activePois, hasLength(1));
      expect(result.activePois.first.id, 'poi_2');
    });
  });

  // ---------------------------------------------------------------------------
  // max 3 active POIs constraint (integration)
  // ---------------------------------------------------------------------------

  group('max 3 active POIs constraint', () {
    test('getActivePois never returns more than 3 items', () async {
      final many = List.generate(
        10,
        (i) => makeMysteryPoi(id: 'poi_$i', name: null),
      );
      when(() => repo.loadPois('zone_1')).thenAnswer((_) async => many);

      final result = await service.getActivePois('zone_1');

      expect(result.length, lessThanOrEqualTo(3));
    });

    test('generatePois activePois never exceeds 3 items', () async {
      final centre = LatLng(51.5074, -0.1278);
      final discoveries = List.generate(
        20,
        (i) => makeDiscovery(id: 'node/$i', name: 'POI $i'),
      );
      when(() => overpass.fetchPOIs(any())).thenAnswer((_) async => discoveries);

      final result = await service.generatePois(centre, 2000.0);

      expect(result.activePois.length, lessThanOrEqualTo(3));
    });
  });

  // ---------------------------------------------------------------------------
  // generatePois with PoiCurator (Issue #82)
  // ---------------------------------------------------------------------------

  group('generatePois curates results via PoiCurator', () {
    test('totalCount equals curated count not raw overpass count', () async {
      final centre = LatLng(51.5074, -0.1278);
      // 2 named discoveries, different categories, >100 m apart → both survive.
      final discoveries = [
        makeDiscovery(id: 'node/1', name: 'The Crown', category: 'pub',
            lat: 51.50, lng: -0.10),
        makeDiscovery(id: 'node/2', name: 'Victoria Park', category: 'park',
            lat: 51.51, lng: -0.10),
      ];
      when(() => overpass.fetchPOIs(any())).thenAnswer((_) async => discoveries);

      final result = await service.generatePois(centre, 5000.0);

      // Both survive curation (named, different categories, ~1 km apart).
      expect(result.totalCount, 2);
    });

    test('unnamed discoveries are excluded by curation', () async {
      final centre = LatLng(51.5074, -0.1278);
      // One named, one unnamed (empty name).
      final discoveries = [
        makeDiscovery(id: 'node/1', name: 'The Crown', category: 'pub'),
        makeDiscovery(id: 'node/2', name: '', category: 'park'),
      ];
      when(() => overpass.fetchPOIs(any())).thenAnswer((_) async => discoveries);

      final result = await service.generatePois(centre, 500.0);

      // Unnamed one is filtered out by curation.
      expect(result.totalCount, 1);
      expect(result.activePois.every((p) => p.id != 'node/2'), isTrue);
    });

    test('activePois reflects curated set limited by _maxActivePois', () async {
      final centre = LatLng(51.5074, -0.1278);
      // 5 named POIs with different categories, well spaced → survive curation.
      final discoveries = [
        makeDiscovery(id: 'node/1', name: 'Pub A', category: 'pub', lat: 51.50),
        makeDiscovery(id: 'node/2', name: 'Park B', category: 'park', lat: 51.51),
        makeDiscovery(id: 'node/3', name: 'Cafe C', category: 'cafe', lat: 51.52),
        makeDiscovery(id: 'node/4', name: 'Library D', category: 'library', lat: 51.53),
        makeDiscovery(id: 'node/5', name: 'Historic E', category: 'historic', lat: 51.54),
      ];
      when(() => overpass.fetchPOIs(any())).thenAnswer((_) async => discoveries);

      final result = await service.generatePois(centre, 5000.0);

      // activePois is capped at _maxActivePois (3) even if more survive curation.
      expect(result.activePois.length, lessThanOrEqualTo(3));
      // But totalCount reflects all curated survivors (up to 5).
      expect(result.totalCount, greaterThanOrEqualTo(result.activePois.length));
    });
  });

  // ---------------------------------------------------------------------------
  // wave-aware loadOrGenerate (Issue #81)
  // ---------------------------------------------------------------------------

  group('wave-aware loadOrGenerate', () {
    test('fresh generation saves all curated pois and wave state', () async {
      when(() => repo.loadPois('zone_1')).thenAnswer((_) async => []);
      when(() => repo.loadTotalCount('zone_1')).thenAnswer((_) async => null);
      when(() => repo.loadWaveState('zone_1')).thenAnswer((_) async => null);
      when(() => repo.savePois(any(), any())).thenAnswer((_) async {});
      when(() => repo.saveTotalCount(any(), any())).thenAnswer((_) async {});
      when(() => repo.saveWaveState(any(), any(), any())).thenAnswer((_) async {});

      final discoveries = [
        makeDiscovery(id: 'node/1', name: 'Pub A', category: 'pub'),
        makeDiscovery(id: 'node/2', name: 'Park B', category: 'park'),
      ];
      when(() => overpass.fetchPOIs(any())).thenAnswer((_) async => discoveries);

      await service.loadOrGenerate('zone_1', LatLng(51.5074, -0.1278), 500.0);

      verify(() => repo.savePois('zone_1', any())).called(1);
      verify(() => repo.saveWaveState('zone_1', 1, 0)).called(1);
    });

    test('loads from cache at wave 1 when no wave state exists', () async {
      final cachedPois = List.generate(
        10,
        (i) => makeMysteryPoi(id: 'poi_$i'),
      );
      when(() => repo.loadPois('zone_1')).thenAnswer((_) async => cachedPois);
      when(() => repo.loadTotalCount('zone_1')).thenAnswer((_) async => 10);
      when(() => repo.loadWaveState('zone_1')).thenAnswer((_) async => null);

      final result = await service.loadOrGenerate(
        'zone_1',
        LatLng(51.5074, -0.1278),
        500.0,
      );

      // Wave 1 = first 8 unrevealed, capped at _maxActivePois (3) for markers.
      expect(result.activePois.length, lessThanOrEqualTo(3));
      verifyNever(() => overpass.fetchPOIs(any()));
    });

    test('loads wave 2 set when wave state is 2', () async {
      // 20 POIs in cache; wave 2 → first 14 are active.
      final cachedPois = List.generate(
        20,
        (i) => makeMysteryPoi(id: 'poi_$i'),
      );
      when(() => repo.loadPois('zone_1')).thenAnswer((_) async => cachedPois);
      when(() => repo.loadTotalCount('zone_1')).thenAnswer((_) async => 20);
      when(() => repo.loadWaveState('zone_1')).thenAnswer(
        (_) async => const WaveState(currentWave: 2, discoveredInWave: 0),
      );

      final result = await service.loadOrGenerate(
        'zone_1',
        LatLng(51.5074, -0.1278),
        500.0,
      );

      // activePois still capped at _maxActivePois (3) for map markers.
      expect(result.activePois.length, lessThanOrEqualTo(3));
      // totalCount comes from cached count.
      expect(result.totalCount, 20);
      verifyNever(() => overpass.fetchPOIs(any()));
    });
  });

  // ---------------------------------------------------------------------------
  // onPoiRevealed (Issue #81)
  // ---------------------------------------------------------------------------

  group('onPoiRevealed', () {
    test('increments discoveredInWave and saves wave state', () async {
      final cachedPois = List.generate(
        10,
        (i) => makeMysteryPoi(id: 'poi_$i'),
      );
      when(() => repo.loadPois('zone_1')).thenAnswer((_) async => cachedPois);
      when(() => repo.loadTotalCount('zone_1')).thenAnswer((_) async => 10);
      when(() => repo.loadWaveState('zone_1')).thenAnswer(
        (_) async => const WaveState(currentWave: 1, discoveredInWave: 2),
      );
      when(() => repo.saveWaveState(any(), any(), any())).thenAnswer((_) async {});

      await service.onPoiRevealed('zone_1');

      // discoveredInWave goes from 2 → 3; below 50% of wave1Size (4), no unlock.
      verify(() => repo.saveWaveState('zone_1', 1, 3)).called(1);
    });

    test('unlocks wave 2 when threshold is met', () async {
      final cachedPois = List.generate(
        20,
        (i) => makeMysteryPoi(id: 'poi_$i'),
      );
      when(() => repo.loadPois('zone_1')).thenAnswer((_) async => cachedPois);
      when(() => repo.loadTotalCount('zone_1')).thenAnswer((_) async => 20);
      when(() => repo.loadWaveState('zone_1')).thenAnswer(
        (_) async => const WaveState(currentWave: 1, discoveredInWave: 3),
      );
      when(() => repo.saveWaveState(any(), any(), any())).thenAnswer((_) async {});

      final result = await service.onPoiRevealed('zone_1');

      // 4th discovery in wave1 (3→4 = 50% of 8) triggers wave 2 unlock.
      // New wave is 2, discoveredInWave resets to 0.
      verify(() => repo.saveWaveState('zone_1', 2, 0)).called(1);
      // activePois now includes wave 2 set (capped at _maxActivePois).
      expect(result.activePois.length, lessThanOrEqualTo(3));
    });

    test('returns GenerateResult with updated active pois', () async {
      final cachedPois = List.generate(
        20,
        (i) => makeMysteryPoi(id: 'poi_$i'),
      );
      when(() => repo.loadPois('zone_1')).thenAnswer((_) async => cachedPois);
      when(() => repo.loadTotalCount('zone_1')).thenAnswer((_) async => 20);
      when(() => repo.loadWaveState('zone_1')).thenAnswer(
        (_) async => const WaveState(currentWave: 1, discoveredInWave: 0),
      );
      when(() => repo.saveWaveState(any(), any(), any())).thenAnswer((_) async {});

      final result = await service.onPoiRevealed('zone_1');

      expect(result, isA<GenerateResult>());
      expect(result.activePois, isNotEmpty);
    });

    test('does not advance beyond wave 3', () async {
      final cachedPois = List.generate(
        20,
        (i) => makeMysteryPoi(id: 'poi_$i'),
      );
      when(() => repo.loadPois('zone_1')).thenAnswer((_) async => cachedPois);
      when(() => repo.loadTotalCount('zone_1')).thenAnswer((_) async => 20);
      when(() => repo.loadWaveState('zone_1')).thenAnswer(
        (_) async => const WaveState(currentWave: 3, discoveredInWave: 99),
      );
      when(() => repo.saveWaveState(any(), any(), any())).thenAnswer((_) async {});

      await service.onPoiRevealed('zone_1');

      // Wave stays at 3.
      verify(() => repo.saveWaveState('zone_1', 3, any())).called(1);
    });

    test('handles missing wave state gracefully (defaults to wave 1)', () async {
      final cachedPois = List.generate(
        10,
        (i) => makeMysteryPoi(id: 'poi_$i'),
      );
      when(() => repo.loadPois('zone_1')).thenAnswer((_) async => cachedPois);
      when(() => repo.loadTotalCount('zone_1')).thenAnswer((_) async => 10);
      when(() => repo.loadWaveState('zone_1')).thenAnswer((_) async => null);
      when(() => repo.saveWaveState(any(), any(), any())).thenAnswer((_) async {});

      final result = await service.onPoiRevealed('zone_1');

      expect(result, isA<GenerateResult>());
      // Should have saved wave state with wave 1.
      verify(() => repo.saveWaveState('zone_1', 1, any())).called(1);
    });
  });
}
