import 'dart:convert';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dander/core/streets/street.dart';
import 'package:dander/core/streets/street_repository.dart';

class MockBox extends Mock implements Box<dynamic> {}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

List<Street> _buildStreets() {
  return [
    const Street(
      id: 'way/1',
      name: 'Baker Street',
      nodes: [LatLng(51.523, -0.157), LatLng(51.524, -0.158)],
      walkedAt: null,
    ),
    const Street(
      id: 'way/2',
      name: 'Oxford Street',
      nodes: [LatLng(51.514, -0.141), LatLng(51.515, -0.140)],
      walkedAt: null,
    ),
  ];
}

final _bounds = LatLngBounds(
  const LatLng(51.50, -0.13),
  const LatLng(51.55, -0.10),
);

final _boundsB = LatLngBounds(
  const LatLng(52.00, -0.20),
  const LatLng(52.10, -0.10),
);

void main() {
  late MockBox mockBox;
  late HiveStreetRepository repository;

  setUp(() {
    mockBox = MockBox();
    repository = HiveStreetRepository.withBox(mockBox);
  });

  // ---------------------------------------------------------------------------
  // Bounds key isolation
  // ---------------------------------------------------------------------------
  group('bounds key isolation', () {
    test('two different bounds produce different cache keys', () async {
      final storedKeys = <String>[];
      when(() => mockBox.put(any(), any())).thenAnswer((inv) async {
        storedKeys.add(inv.positionalArguments[0] as String);
      });

      await repository.saveStreets(_buildStreets(), _bounds);
      await repository.saveStreets(
        const [
          Street(
            id: 'way/99',
            name: 'Remote Lane',
            nodes: [LatLng(52.05, -0.15)],
            walkedAt: null,
          ),
        ],
        _boundsB,
      );

      expect(storedKeys, hasLength(2));
      expect(storedKeys[0], isNot(equals(storedKeys[1])));
      expect(storedKeys[0], startsWith('streets_'));
      expect(storedKeys[1], startsWith('streets_'));
    });

    test('saveStreets for bounds A does not affect getStreets for bounds B',
        () async {
      final storage = <String, String>{};
      when(() => mockBox.put(any(), any())).thenAnswer((inv) async {
        storage[inv.positionalArguments[0] as String] =
            inv.positionalArguments[1] as String;
      });
      when(() => mockBox.get(any())).thenAnswer(
        (inv) => storage[inv.positionalArguments[0] as String],
      );

      await repository.saveStreets(_buildStreets(), _bounds);

      final result = await repository.getStreets(_boundsB);
      expect(result, isEmpty);
    });

    test('cache key uses 3 decimal places for coordinates', () async {
      String? storedKey;
      when(() => mockBox.put(any(), any())).thenAnswer((inv) async {
        storedKey = inv.positionalArguments[0] as String;
      });

      await repository.saveStreets(_buildStreets(), _bounds);

      // 51.50 → 51.500, -0.13 → -0.130, etc.
      expect(storedKey, contains('51.500'));
      expect(storedKey, contains('-0.130'));
    });
  });

  // ---------------------------------------------------------------------------
  // saveStreets
  // ---------------------------------------------------------------------------
  group('saveStreets', () {
    test('stores JSON-encoded list under a bounds-derived key', () async {
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

      await repository.saveStreets(_buildStreets(), _bounds);

      verify(() => mockBox.put(any(), any())).called(greaterThanOrEqualTo(1));
    });

    test('stores streets so they can be recovered by id', () async {
      final streets = _buildStreets();
      String? stored;
      when(() => mockBox.put(any(), any())).thenAnswer((inv) async {
        stored = inv.positionalArguments[1] as String;
      });

      await repository.saveStreets(streets, _bounds);
      expect(stored, isNotNull);

      final decoded = jsonDecode(stored!) as List<dynamic>;
      final ids = decoded
          .cast<Map<String, dynamic>>()
          .map((m) => m['id'] as String)
          .toList();
      expect(ids, containsAll(['way/1', 'way/2']));
    });
  });

  // ---------------------------------------------------------------------------
  // getStreets
  // ---------------------------------------------------------------------------
  group('getStreets', () {
    test('returns empty list when no data cached', () async {
      when(() => mockBox.get(any())).thenReturn(null);

      final result = await repository.getStreets(_bounds);
      expect(result, isEmpty);
    });

    test('returns persisted streets after save/load round-trip', () async {
      final streets = _buildStreets();
      String? stored;
      when(() => mockBox.put(any(), any())).thenAnswer((inv) async {
        stored = inv.positionalArguments[1] as String;
      });
      await repository.saveStreets(streets, _bounds);

      when(() => mockBox.get(any())).thenReturn(stored);

      final result = await repository.getStreets(_bounds);
      expect(result, hasLength(2));
      expect(result.map((s) => s.id), containsAll(['way/1', 'way/2']));
    });

    test('preserves street name after round-trip', () async {
      final streets = _buildStreets();
      String? stored;
      when(() => mockBox.put(any(), any())).thenAnswer((inv) async {
        stored = inv.positionalArguments[1] as String;
      });
      await repository.saveStreets(streets, _bounds);
      when(() => mockBox.get(any())).thenReturn(stored);

      final result = await repository.getStreets(_bounds);
      expect(result.first.name, equals('Baker Street'));
    });

    test('preserves node geometry after round-trip', () async {
      final streets = _buildStreets();
      String? stored;
      when(() => mockBox.put(any(), any())).thenAnswer((inv) async {
        stored = inv.positionalArguments[1] as String;
      });
      await repository.saveStreets(streets, _bounds);
      when(() => mockBox.get(any())).thenReturn(stored);

      final result = await repository.getStreets(_bounds);
      final street = result.firstWhere((s) => s.id == 'way/1');
      expect(street.nodes, hasLength(2));
      expect(street.nodes.first.latitude, closeTo(51.523, 0.0001));
    });

    test('returns empty list on corrupted JSON', () async {
      when(() => mockBox.get(any())).thenReturn('not valid json {{{{');

      final result = await repository.getStreets(_bounds);
      expect(result, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // markWalked
  // ---------------------------------------------------------------------------
  group('markWalked', () {
    test('stores walked entry under __walked__ key as map of id→ISO date',
        () async {
      final storage = <String, dynamic>{};
      when(() => mockBox.put(any(), any())).thenAnswer((inv) async {
        storage[inv.positionalArguments[0] as String] =
            inv.positionalArguments[1];
      });
      when(() => mockBox.get(any())).thenAnswer(
        (inv) => storage[inv.positionalArguments[0] as String],
      );

      final ts = DateTime.utc(2024, 6, 1, 10, 0);
      await repository.markWalked('way/1', ts);

      expect(storage.containsKey('__walked__'), isTrue);
      final walked =
          jsonDecode(storage['__walked__'] as String) as Map<String, dynamic>;
      expect(walked.containsKey('way/1'), isTrue);
      expect(walked['way/1'], equals(ts.toIso8601String()));
    });

    test('overwrites existing timestamp for the same street id', () async {
      final storage = <String, dynamic>{};
      when(() => mockBox.put(any(), any())).thenAnswer((inv) async {
        storage[inv.positionalArguments[0] as String] =
            inv.positionalArguments[1];
      });
      when(() => mockBox.get(any())).thenAnswer(
        (inv) => storage[inv.positionalArguments[0] as String],
      );

      final ts1 = DateTime.utc(2024, 6, 1);
      final ts2 = DateTime.utc(2024, 6, 2);
      await repository.markWalked('way/1', ts1);
      await repository.markWalked('way/1', ts2);

      final walked =
          jsonDecode(storage['__walked__'] as String) as Map<String, dynamic>;
      expect(walked['way/1'], equals(ts2.toIso8601String()));
    });

    test('persists multiple street ids independently', () async {
      final storage = <String, dynamic>{};
      when(() => mockBox.put(any(), any())).thenAnswer((inv) async {
        storage[inv.positionalArguments[0] as String] =
            inv.positionalArguments[1];
      });
      when(() => mockBox.get(any())).thenAnswer(
        (inv) => storage[inv.positionalArguments[0] as String],
      );

      await repository.markWalked('way/1', DateTime.utc(2024, 6, 1));
      await repository.markWalked('way/2', DateTime.utc(2024, 6, 2));

      final walked =
          jsonDecode(storage['__walked__'] as String) as Map<String, dynamic>;
      expect(walked.containsKey('way/1'), isTrue);
      expect(walked.containsKey('way/2'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // getWalkedStreets
  // ---------------------------------------------------------------------------
  group('getWalkedStreets', () {
    test('returns empty list when no streets walked', () async {
      final storage = <String, dynamic>{};
      when(() => mockBox.get(any())).thenAnswer(
        (inv) => storage[inv.positionalArguments[0] as String],
      );
      when(() => mockBox.keys).thenReturn([]);

      final result = await repository.getWalkedStreets();
      expect(result, isEmpty);
    });

    test('returns only walked streets with walkedAt populated', () async {
      final storage = <String, dynamic>{};
      when(() => mockBox.put(any(), any())).thenAnswer((inv) async {
        storage[inv.positionalArguments[0] as String] =
            inv.positionalArguments[1];
      });
      when(() => mockBox.get(any())).thenAnswer(
        (inv) => storage[inv.positionalArguments[0] as String],
      );
      when(() => mockBox.keys).thenAnswer((_) => storage.keys.toList());

      // Save both streets
      await repository.saveStreets(_buildStreets(), _bounds);
      // Mark only way/1 as walked
      final ts = DateTime.utc(2024, 6, 1, 9, 0);
      await repository.markWalked('way/1', ts);

      final result = await repository.getWalkedStreets();
      expect(result, hasLength(1));
      expect(result.first.id, equals('way/1'));
      expect(result.first.walkedAt, equals(ts));
    });

    test('returns streets walked across multiple bounds areas', () async {
      final storage = <String, dynamic>{};
      when(() => mockBox.put(any(), any())).thenAnswer((inv) async {
        storage[inv.positionalArguments[0] as String] =
            inv.positionalArguments[1];
      });
      when(() => mockBox.get(any())).thenAnswer(
        (inv) => storage[inv.positionalArguments[0] as String],
      );
      when(() => mockBox.keys).thenAnswer((_) => storage.keys.toList());

      await repository.saveStreets(_buildStreets(), _bounds);
      await repository.saveStreets(
        const [
          Street(
            id: 'way/99',
            name: 'Remote Lane',
            nodes: [LatLng(52.05, -0.15)],
            walkedAt: null,
          ),
        ],
        _boundsB,
      );
      await repository.markWalked('way/1', DateTime.utc(2024, 6, 1));
      await repository.markWalked('way/99', DateTime.utc(2024, 6, 2));

      final result = await repository.getWalkedStreets();
      expect(result.map((s) => s.id), containsAll(['way/1', 'way/99']));
    });
  });

  // ---------------------------------------------------------------------------
  // hasCache
  // ---------------------------------------------------------------------------
  group('hasCache', () {
    test('returns false when no cache exists for bounds', () async {
      when(() => mockBox.get(any())).thenReturn(null);

      final result = await repository.hasCache(_bounds);
      expect(result, isFalse);
    });

    test('returns true when cache data exists for bounds', () async {
      when(() => mockBox.get(any())).thenReturn('[]');

      final result = await repository.hasCache(_bounds);
      expect(result, isTrue);
    });

    test('returns false for bounds B when only bounds A has cache', () async {
      final storage = <String, dynamic>{};
      when(() => mockBox.put(any(), any())).thenAnswer((inv) async {
        storage[inv.positionalArguments[0] as String] =
            inv.positionalArguments[1];
      });
      when(() => mockBox.get(any())).thenAnswer(
        (inv) => storage[inv.positionalArguments[0] as String],
      );

      await repository.saveStreets(_buildStreets(), _bounds);

      final result = await repository.hasCache(_boundsB);
      expect(result, isFalse);
    });
  });
}
