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
    Discovery(
      id: 'node/1',
      name: 'Corner Café',
      category: 'cafe',
      rarity: RarityTier.common,
      position: const LatLng(51.51, -0.12),
      osmTags: const {'amenity': 'cafe'},
      discoveredAt: null,
    ),
    Discovery(
      id: 'node/2',
      name: 'Primrose Hill',
      category: 'viewpoint',
      rarity: RarityTier.rare,
      position: const LatLng(51.54, -0.16),
      osmTags: const {'tourism': 'viewpoint'},
      discoveredAt: null,
    ),
  ];
}

// Bounds used as cache key
final _bounds = LatLngBounds(
  const LatLng(51.50, -0.13),
  const LatLng(51.55, -0.10),
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
    // savePOIs
    // -------------------------------------------------------------------------
    group('savePOIs', () {
      test('stores JSON-encoded list under a bounds-derived key', () async {
        when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

        await repository.savePOIs(_buildDiscoveries());

        verify(() => mockBox.put(any(), any())).called(greaterThanOrEqualTo(1));
      });

      test('stores each discovery so it can be recovered', () async {
        final discoveries = _buildDiscoveries();
        String? stored;
        when(() => mockBox.put(any(), any())).thenAnswer((inv) async {
          stored = inv.positionalArguments[1] as String;
        });

        await repository.savePOIs(discoveries);
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
        await repository.savePOIs(discoveries);

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
        await repository.savePOIs(discoveries);
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
        await repository.savePOIs(discoveries);
        when(() => mockBox.get(any())).thenReturn(stored);

        final result = await repository.getPOIs(_bounds);
        expect(result.first.discoveredAt, equals(timestamp));
      });
    });

    // -------------------------------------------------------------------------
    // markDiscovered
    // -------------------------------------------------------------------------
    group('markDiscovered', () {
      test('updates the discovery with the given id and sets discoveredAt',
          () async {
        final discoveries = _buildDiscoveries();
        final storedData = <String, String>{};
        when(() => mockBox.put(any(), any())).thenAnswer((inv) async {
          storedData[inv.positionalArguments[0] as String] =
              inv.positionalArguments[1] as String;
        });
        await repository.savePOIs(discoveries);

        // Stub get to return what was stored under any key.
        when(() => mockBox.get(any())).thenAnswer(
          (inv) => storedData[inv.positionalArguments[0] as String],
        );

        final discoveredAt = DateTime(2024, 6, 1);
        await repository.markDiscovered('node/1', discoveredAt);

        // Retrieve and check that node/1 is now marked.
        final stored = storedData.values.first;
        final decoded =
            (jsonDecode(stored) as List<dynamic>).cast<Map<String, dynamic>>();
        final node1 = decoded.firstWhere((m) => m['id'] == 'node/1');
        expect(node1['discoveredAt'], isNotNull);
      });

      test('does not affect other discoveries in the same cache', () async {
        final discoveries = _buildDiscoveries();
        final storedData = <String, String>{};
        when(() => mockBox.put(any(), any())).thenAnswer((inv) async {
          storedData[inv.positionalArguments[0] as String] =
              inv.positionalArguments[1] as String;
        });
        await repository.savePOIs(discoveries);

        when(() => mockBox.get(any())).thenAnswer(
          (inv) => storedData[inv.positionalArguments[0] as String],
        );

        await repository.markDiscovered('node/1', DateTime(2024, 6, 1));

        final stored = storedData.values.first;
        final decoded =
            (jsonDecode(stored) as List<dynamic>).cast<Map<String, dynamic>>();
        final node2 = decoded.firstWhere((m) => m['id'] == 'node/2');
        expect(node2['discoveredAt'], isNull);
      });

      test('is a no-op when id does not exist', () async {
        when(() => mockBox.get(any())).thenReturn(null);
        when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

        // Should not throw.
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
      test('returns only discoveries with non-null discoveredAt', () async {
        final timestamp = DateTime(2024, 6, 1);
        final discoveries = [
          Discovery(
            id: 'node/1',
            name: 'Discovered',
            category: 'cafe',
            rarity: RarityTier.common,
            position: const LatLng(51.51, -0.12),
            osmTags: const {'amenity': 'cafe'},
            discoveredAt: timestamp,
          ),
          Discovery(
            id: 'node/2',
            name: 'Not Discovered',
            category: 'viewpoint',
            rarity: RarityTier.rare,
            position: const LatLng(51.54, -0.16),
            osmTags: const {'tourism': 'viewpoint'},
            discoveredAt: null,
          ),
        ];
        String? stored;
        when(() => mockBox.put(any(), any())).thenAnswer((inv) async {
          stored = inv.positionalArguments[1] as String;
        });
        await repository.savePOIs(discoveries);
        when(() => mockBox.get(any())).thenReturn(stored);

        final result = await repository.getDiscovered();
        expect(result, hasLength(1));
        expect(result.first.id, equals('node/1'));
      });

      test('returns empty list when no discoveries found', () async {
        when(() => mockBox.get(any())).thenReturn(null);

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
  });
}
