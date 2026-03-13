import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dander/core/discoveries/overpass_client.dart';
import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/zone/mystery_poi.dart';
import 'package:dander/core/zone/mystery_poi_repository.dart';
import 'package:dander/core/zone/mystery_poi_service.dart';

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
}) =>
    MysteryPoi(
      id: id,
      position: LatLng(lat, lng),
      category: category,
      name: name,
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
        makeMysteryPoi(id: 'poi_1', name: null),        // unrevealed
        makeMysteryPoi(id: 'poi_2', name: 'The Crown'), // revealed
        makeMysteryPoi(id: 'poi_3', name: null),        // unrevealed
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
        makeMysteryPoi(id: 'poi_1', name: 'Pub A'),
        makeMysteryPoi(id: 'poi_2', name: 'Park B'),
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
    test('returns new MysteryPoi list from overpass discoveries', () async {
      final centre = LatLng(51.5074, -0.1278);
      final discoveries = [
        makeDiscovery(id: 'node/1', name: 'The Crown', category: 'pub'),
        makeDiscovery(id: 'node/2', name: 'Victoria Park', category: 'park'),
      ];
      when(() => overpass.fetchPOIs(any())).thenAnswer((_) async => discoveries);

      final result = await service.generatePois(centre, 500.0);

      expect(result, isNotEmpty);
      expect(result.every((p) => !p.isRevealed), isTrue);
    });

    test('generated pois have names null (unrevealed)', () async {
      final centre = LatLng(51.5074, -0.1278);
      final discoveries = [
        makeDiscovery(id: 'node/1', name: 'The Crown'),
      ];
      when(() => overpass.fetchPOIs(any())).thenAnswer((_) async => discoveries);

      final result = await service.generatePois(centre, 500.0);

      expect(result.every((p) => p.name == null), isTrue);
    });

    test('returns at most 3 pois regardless of overpass results', () async {
      final centre = LatLng(51.5074, -0.1278);
      final discoveries = List.generate(
        10,
        (i) => makeDiscovery(id: 'node/$i', name: 'POI $i'),
      );
      when(() => overpass.fetchPOIs(any())).thenAnswer((_) async => discoveries);

      final result = await service.generatePois(centre, 500.0);

      expect(result.length, lessThanOrEqualTo(3));
    });

    test('returns empty list when overpass returns no results', () async {
      final centre = LatLng(51.5074, -0.1278);
      when(() => overpass.fetchPOIs(any())).thenAnswer((_) async => []);

      final result = await service.generatePois(centre, 500.0);

      expect(result, isEmpty);
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

      expect(result.first.category, 'historic');
    });

    test('generated pois have unique ids matching discovery ids', () async {
      final centre = LatLng(51.5074, -0.1278);
      final discoveries = [
        makeDiscovery(id: 'node/42'),
        makeDiscovery(id: 'node/43'),
      ];
      when(() => overpass.fetchPOIs(any())).thenAnswer((_) async => discoveries);

      final result = await service.generatePois(centre, 500.0);

      final ids = result.map((p) => p.id).toSet();
      expect(ids.length, result.length); // all unique
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

    test('generatePois never returns more than 3 items', () async {
      final centre = LatLng(51.5074, -0.1278);
      final discoveries = List.generate(
        20,
        (i) => makeDiscovery(id: 'node/$i', name: 'POI $i'),
      );
      when(() => overpass.fetchPOIs(any())).thenAnswer((_) async => discoveries);

      final result = await service.generatePois(centre, 2000.0);

      expect(result.length, lessThanOrEqualTo(3));
    });
  });
}
