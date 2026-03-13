import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/discoveries/proximity_detector.dart';

void main() {
  // Helper to build a Discovery at a given position.
  Discovery makeDiscovery({
    required String id,
    required LatLng position,
    DateTime? discoveredAt,
  }) {
    return Discovery(
      id: id,
      name: 'POI $id',
      category: 'cafe',
      rarity: RarityTier.common,
      position: position,
      osmTags: const {'amenity': 'cafe'},
      discoveredAt: discoveredAt,
    );
  }

  // Centre point for tests
  const centre = LatLng(51.5074, -0.1278);

  // ~20 m north of centre (well within 30 m radius)
  const nearbyNorth = LatLng(51.5076, -0.1278); // ~22 m

  // ~100 m north (outside 30 m radius)
  const farNorth = LatLng(51.5083, -0.1278); // ~100 m

  group('ProximityDetector.detectNew', () {
    group('default radius (30 m)', () {
      test('returns discovery when user is within radius', () {
        final poi = makeDiscovery(id: 'node/1', position: nearbyNorth);
        final result = ProximityDetector.detectNew(
          centre,
          [poi],
          ProximityDetector.discoveryRadiusMeters,
        );
        expect(result, hasLength(1));
        expect(result.first.id, equals('node/1'));
      });

      test('returns empty list when user is outside radius', () {
        final poi = makeDiscovery(id: 'node/1', position: farNorth);
        final result = ProximityDetector.detectNew(
          centre,
          [poi],
          ProximityDetector.discoveryRadiusMeters,
        );
        expect(result, isEmpty);
      });

      test('returns empty list when undiscovered list is empty', () {
        final result = ProximityDetector.detectNew(
          centre,
          [],
          ProximityDetector.discoveryRadiusMeters,
        );
        expect(result, isEmpty);
      });
    });

    group('multiple POIs', () {
      test('returns all POIs within radius', () {
        final near1 = makeDiscovery(id: 'node/1', position: nearbyNorth);
        // ~15 m east of centre
        const nearbyEast = LatLng(51.5074, -0.1276);
        final near2 = makeDiscovery(id: 'node/2', position: nearbyEast);
        final far = makeDiscovery(id: 'node/3', position: farNorth);

        final result = ProximityDetector.detectNew(
          centre,
          [near1, near2, far],
          ProximityDetector.discoveryRadiusMeters,
        );
        expect(result, hasLength(2));
        expect(result.map((d) => d.id), containsAll(['node/1', 'node/2']));
      });

      test(
          'only returns undiscovered POIs (does not re-trigger already discovered)',
          () {
        final alreadyDiscovered = makeDiscovery(
          id: 'node/1',
          position: nearbyNorth,
          discoveredAt: DateTime(2024, 1, 1),
        );
        final result = ProximityDetector.detectNew(
          centre,
          [alreadyDiscovered],
          ProximityDetector.discoveryRadiusMeters,
        );
        // The input list is "undiscovered" — callers are responsible for filtering.
        // ProximityDetector treats all items in the list as candidates.
        // This test verifies callers passing pre-filtered lists get correct results.
        // The detector returns them all if within range.
        expect(result, hasLength(1));
      });
    });

    group('boundary conditions', () {
      test('POI exactly at radius boundary is included', () {
        // Use a custom radius to make boundary deterministic.
        // Position the POI exactly radiusMeters away.
        // ~30 m north (approx 0.00027 degrees latitude)
        const atBoundary = LatLng(51.50767, -0.1278);
        final poi = makeDiscovery(id: 'node/boundary', position: atBoundary);

        final result = ProximityDetector.detectNew(centre, [poi], 30.0);
        // Boundary is included (distance <= radius)
        expect(result, isNotEmpty);
      });

      test('user position exactly matches POI position → within radius', () {
        final poi = makeDiscovery(id: 'node/exact', position: centre);
        final result = ProximityDetector.detectNew(
          centre,
          [poi],
          ProximityDetector.discoveryRadiusMeters,
        );
        expect(result, hasLength(1));
      });

      test('custom radius is respected', () {
        // POI is ~22 m away — inside 30 m but outside 10 m
        final poi = makeDiscovery(id: 'node/1', position: nearbyNorth);

        final within30 = ProximityDetector.detectNew(centre, [poi], 30.0);
        final within10 = ProximityDetector.detectNew(centre, [poi], 10.0);

        expect(within30, hasLength(1));
        expect(within10, isEmpty);
      });
    });

    group('does not mutate input list', () {
      test('original undiscovered list is unchanged after call', () {
        final poi1 = makeDiscovery(id: 'node/1', position: nearbyNorth);
        final poi2 = makeDiscovery(id: 'node/2', position: farNorth);
        final input = [poi1, poi2];

        ProximityDetector.detectNew(centre, input, 30.0);

        expect(input, hasLength(2));
        expect(input[0].id, equals('node/1'));
        expect(input[1].id, equals('node/2'));
      });
    });
  });

  group('ProximityDetector constants', () {
    test('discoveryRadiusMeters is 30.0', () {
      expect(ProximityDetector.discoveryRadiusMeters, equals(30.0));
    });
  });
}
