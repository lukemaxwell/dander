import 'dart:convert';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/discoveries/discovery_repository.dart';

class MockBox extends Mock implements Box<dynamic> {}

// Builds a list of test Discoveries.
List<Discovery> _buildDiscoveries() {
  return [
    const Discovery(
      id: 'node/1',
      name: 'Corner Café',
      category: 'cafe',
      rarity: RarityTier.common,
      position: LatLng(51.51, -0.12),
      osmTags: {'amenity': 'cafe'},
      discoveredAt: null,
    ),
    const Discovery(
      id: 'node/2',
      name: 'Primrose Hill',
      category: 'viewpoint',
      rarity: RarityTier.rare,
      position: LatLng(51.54, -0.16),
      osmTags: {'tourism': 'viewpoint'},
      discoveredAt: null,
    ),
  ];
}

// Bounds used as cache key
final _bounds = LatLngBounds(
  const LatLng(51.50, -0.13),
  const LatLng(51.55, -0.10),
);

// A second, non-overlapping bounds area.
final _boundsB = LatLngBounds(
  const LatLng(52.00, -0.20),
  const LatLng(52.10, -0.10),
);

void main() {
  late MockBox mockBox;
  late HiveDiscoveryRepository repository;

  setUp(() {
    mockBox = MockBox();
    repository = HiveDiscoveryRepository.withBox(mockBox);
  });

  group('HiveDiscoveryRepository', () {
    // -------------------------------------------------------------------------
    // bounds key isolation
    // -------------------------------------------------------------------------
    group('bounds key isolation', () {
      test('two different bounds produce different cache keys', () async {
        final storedKeys = <String>[];
        when(() => mockBox.put(any(), any())).thenAnswer((inv) async {
          storedKeys.add(inv.positionalArguments[0] as String);
        });

        await repository.savePOIs(_buildDiscoveries(), _bounds);
        await repository.savePOIs(
          [
            const Discovery(
              id: 'node/99',
              name: 'Remote Pub',
              category: 'pub',
              rarity: RarityTier.common,
              position: LatLng(52.05, -0.15),
              osmTags: {'amenity': 'pub'},
              discoveredAt: null,
            ),
          ],
          _boundsB,
        );

        expect(storedKeys, hasLength(2));
        expect(storedKeys[0], isNot(equals(storedKeys[1])));
        expect(storedKeys[0], startsWith('pois_'));
        expect(storedKeys[1], startsWith('pois_'));
      });

      test('savePOIs for bounds A does not affect getPOIs for bounds B',
          () async {
        final storage = <String, String>{};
        when(() => mockBox.put(any(), any())).thenAnswer((inv) async {
          storage[inv.positionalArguments[0] as String] =
              inv.positionalArguments[1] as String;
        });
        when(() => mockBox.get(any())).thenAnswer(
          (inv) => storage[inv.positionalArguments[0] as String],
        );

        // Save discoveries only under _bounds (area A).
        await repository.savePOIs(_buildDiscoveries(), _bounds);

        // getPOIs for _boundsB should return empty — nothing was saved there.
        final result = await repository.getPOIs(_boundsB);
        expect(result, isEmpty);
      });
    });

    // -------------------------------------------------------------------------
    // savePOIs
    // -------------------------------------------------------------------------
    group('savePOIs', () {
      test('stores JSON-encoded list under a bounds-derived key', () async {
        when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

        await repository.savePOIs(_buildDiscoveries(), _bounds);

        verify(() => mockBox.put(any(), any())).called(greaterThanOrEqualTo(1));
      });

      test('stores each discovery so it can be recovered', () async {
        final discoveries = _buildDiscoveries();
        String? stored;
        when(() => mockBox.put(any(), any())).thenAnswer((inv) async {
          stored = inv.positionalArguments[1] as String;
        });

        await repository.savePOIs(discoveries, _bounds);
        expect(stored, isNotNull);

        // Verify it's valid JSON containing our IDs.
        final decoded = jsonDecode(stored!) as List<dynamic>;
        final ids = decoded
            .cast<Map<String, dynamic>>()
            .map((m) => m['id'] as String)
            .toList();
        expect(ids, containsAll(['node/1', 'node/2']));
      });
    });

    // -------------------------------------------------------------------------
    // getPOIs
    // -------------------------------------------------------------------------
    group('getPOIs', () {
      test('returns empty list when no data cached', () async {
        when(() => mockBox.get(any())).thenReturn(null);

        final result = await repository.getPOIs(_bounds);
        expect(result, isEmpty);
      });

      test('returns persisted discoveries after save/load round-trip',
          () async {
        final discoveries = _buildDiscoveries();
        String? stored;
        when(() => mockBox.put(any(), any())).thenAnswer((inv) async {
          stored = inv.positionalArguments[1] as String;
        });
        await repository.savePOIs(discoveries, _bounds);

        // Now stub get to return what was stored.
        when(() => mockBox.get(any())).thenReturn(stored);

        final result = await repository.getPOIs(_bounds);
        expect(result, hasLength(2));
        expect(result.map((d) => d.id), containsAll(['node/1', 'node/2']));
      });

      test('preserves rarity tier after round-trip', () async {
        final discoveries = _buildDiscoveries();
        String? stored;
        when(() => mockBox.put(any(), any())).thenAnswer((inv) async {
          stored = inv.positionalArguments[1] as String;
        });
        await repository.savePOIs(discoveries, _bounds);
        when(() => mockBox.get(any())).thenReturn(stored);

        final result = await repository.getPOIs(_bounds);
        final rare = result.firstWhere((d) => d.id == 'node/2');
        expect(rare.rarity, equals(RarityTier.rare));
      });

      test('preserves discoveredAt after round-trip', () async {
        final timestamp = DateTime(2024, 6, 1, 12, 0);
        final discoveries = [
          Discovery(
            id: 'node/1',
            name: 'Test',
            category: 'cafe',
            rarity: RarityTier.common,
            position: const LatLng(51.51, -0.12),
            osmTags: const {'amenity': 'cafe'},
            discoveredAt: timestamp,
          ),
        ];
        String? stored;
        when(() => mockBox.put(any(), any())).thenAnswer((inv) async {
          stored = inv.positionalArguments[1] as String;
        });
        await repository.savePOIs(discoveries, _bounds);
        when(() => mockBox.get(any())).thenReturn(stored);

        final result = await repository.getPOIs(_bounds);
        expect(result.first.discoveredAt, equals(timestamp));
      });
    });

    // -------------------------------------------------------------------------
    // markDiscovered
    // -------------------------------------------------------------------------
    group('markDiscovered', () {
      test('adds id to the __discovered__ key', () async {
        final storedData = <String, String>{};
        when(() => mockBox.put(any(), any())).thenAnswer((inv) async {
          storedData[inv.positionalArguments[0] as String] =
              inv.positionalArguments[1] as String;
        });
        when(() => mockBox.get(any())).thenAnswer(
          (inv) => storedData[inv.positionalArguments[0] as String],
        );

        await repository.markDiscovered('node/1', DateTime(2024, 6, 1));

        expect(storedData.containsKey('__discovered__'), isTrue);
        final ids =
            (jsonDecode(storedData['__discovered__']!) as List<dynamic>)
                .cast<String>();
        expect(ids, contains('node/1'));
      });

      test('does not add duplicate ids to the discovered list', () async {
        final storedData = <String, String>{};
        when(() => mockBox.put(any(), any())).thenAnswer((inv) async {
          storedData[inv.positionalArguments[0] as String] =
              inv.positionalArguments[1] as String;
        });
        when(() => mockBox.get(any())).thenAnswer(
          (inv) => storedData[inv.positionalArguments[0] as String],
        );

        await repository.markDiscovered('node/1', DateTime(2024, 6, 1));
        await repository.markDiscovered('node/1', DateTime(2024, 6, 2));

        final ids =
            (jsonDecode(storedData['__discovered__']!) as List<dynamic>)
                .cast<String>();
        expect(ids.where((id) => id == 'node/1'), hasLength(1));
      });

      test('is a no-op when id does not exist — does not throw', () async {
        when(() => mockBox.get(any())).thenReturn(null);
        when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

        await expectLater(
          () => repository.markDiscovered('nonexistent', DateTime.now()),
          returnsNormally,
        );
      });
    });

    // -------------------------------------------------------------------------
    // getDiscovered
    // -------------------------------------------------------------------------
    group('getDiscovered', () {
      test('returns only discoveries with ids in the __discovered__ list',
          () async {
        final storage = <String, dynamic>{};
        when(() => mockBox.put(any(), any())).thenAnswer((inv) async {
          storage[inv.positionalArguments[0] as String] =
              inv.positionalArguments[1];
        });
        when(() => mockBox.get(any())).thenAnswer(
          (inv) => storage[inv.positionalArguments[0] as String],
        );
        when(() => mockBox.keys).thenAnswer((_) => storage.keys.toList());

        // Save two POIs under _bounds.
        await repository.savePOIs(_buildDiscoveries(), _bounds);
        // Mark only node/1 as discovered.
        await repository.markDiscovered('node/1', DateTime(2024, 6, 1));

        final result = await repository.getDiscovered();
        expect(result, hasLength(1));
        expect(result.first.id, equals('node/1'));
      });

      test(
          'returns discoveries across multiple bounds areas when both '
          'have discovered POIs', () async {
        final storage = <String, dynamic>{};
        when(() => mockBox.put(any(), any())).thenAnswer((inv) async {
          storage[inv.positionalArguments[0] as String] =
              inv.positionalArguments[1];
        });
        when(() => mockBox.get(any())).thenAnswer(
          (inv) => storage[inv.positionalArguments[0] as String],
        );
        when(() => mockBox.keys).thenAnswer((_) => storage.keys.toList());

        // Save POIs in two separate areas.
        await repository.savePOIs(_buildDiscoveries(), _bounds);
        await repository.savePOIs(
          [
            const Discovery(
              id: 'node/99',
              name: 'Remote Pub',
              category: 'pub',
              rarity: RarityTier.common,
              position: LatLng(52.05, -0.15),
              osmTags: {'amenity': 'pub'},
              discoveredAt: null,
            ),
          ],
          _boundsB,
        );

        // Mark one POI from each area.
        await repository.markDiscovered('node/1', DateTime(2024, 6, 1));
        await repository.markDiscovered('node/99', DateTime(2024, 6, 2));

        final result = await repository.getDiscovered();
        expect(result.map((d) => d.id), containsAll(['node/1', 'node/99']));
      });

      test('returns empty list when no discoveries found', () async {
        when(() => mockBox.get(any())).thenReturn(null);
        when(() => mockBox.keys).thenReturn([]);

        final result = await repository.getDiscovered();
        expect(result, isEmpty);
      });
    });

    // -------------------------------------------------------------------------
    // hasCache
    // -------------------------------------------------------------------------
    group('hasCache', () {
      test('returns false when no cache exists', () async {
        when(() => mockBox.get(any())).thenReturn(null);

        final result = await repository.hasCache(_bounds);
        expect(result, isFalse);
      });

      test('returns true when cache data exists', () async {
        when(() => mockBox.get(any())).thenReturn('[]');

        final result = await repository.hasCache(_bounds);
        expect(result, isTrue);
      });
    });

    group('getAllCached', () {
      test('returns empty list when no pois_ keys exist', () async {
        when(() => mockBox.keys).thenReturn([]);
        final result = await repository.getAllCached();
        expect(result, isEmpty);
      });

      test('returns all POIs from all pois_ keys regardless of discovery state',
          () async {
        final discoveries = _buildDiscoveries();
        final encoded = jsonEncode(discoveries.map((d) => d.toJson()).toList());

        when(() => mockBox.keys).thenReturn(['pois_51.510_-0.120_51.540_-0.160']);
        when(() => mockBox.get('pois_51.510_-0.120_51.540_-0.160'))
            .thenReturn(encoded);

        final result = await repository.getAllCached();
        expect(result, hasLength(discoveries.length));
        expect(result.map((d) => d.id).toSet(),
            equals(discoveries.map((d) => d.id).toSet()));
      });

      test('skips non-pois_ keys', () async {
        final discoveries = _buildDiscoveries();
        final encoded = jsonEncode(discoveries.map((d) => d.toJson()).toList());

        when(() => mockBox.keys)
            .thenReturn(['__discovered__', 'pois_51.510_-0.120_51.540_-0.160']);
        when(() => mockBox.get('__discovered__')).thenReturn(null);
        when(() => mockBox.get('pois_51.510_-0.120_51.540_-0.160'))
            .thenReturn(encoded);

        final result = await repository.getAllCached();
        expect(result, hasLength(discoveries.length));
      });
    });
  });
}
