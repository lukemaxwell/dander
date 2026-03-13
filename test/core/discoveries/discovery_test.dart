import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:dander/core/discoveries/discovery.dart';

void main() {
  const position = LatLng(51.5074, -0.1278);
  const osmTags = {'amenity': 'cafe', 'name': 'The Corner Café'};

  Discovery buildDiscovery({
    String id = 'node/123',
    String name = 'The Corner Café',
    String category = 'cafe',
    RarityTier rarity = RarityTier.common,
    DateTime? discoveredAt,
  }) {
    return Discovery(
      id: id,
      name: name,
      category: category,
      rarity: rarity,
      position: position,
      osmTags: osmTags,
      discoveredAt: discoveredAt,
    );
  }

  group('Discovery', () {
    group('isDiscovered', () {
      test('returns false when discoveredAt is null', () {
        final d = buildDiscovery();
        expect(d.isDiscovered, isFalse);
      });

      test('returns true when discoveredAt is set', () {
        final d = buildDiscovery(discoveredAt: DateTime(2024, 6, 1));
        expect(d.isDiscovered, isTrue);
      });
    });

    group('markDiscovered', () {
      test('returns a new Discovery with discoveredAt set', () {
        final original = buildDiscovery();
        final timestamp = DateTime(2024, 6, 1, 12, 0, 0);
        final discovered = original.markDiscovered(timestamp);

        expect(discovered.discoveredAt, equals(timestamp));
        expect(discovered.isDiscovered, isTrue);
      });

      test('does not mutate the original Discovery', () {
        final original = buildDiscovery();
        final timestamp = DateTime(2024, 6, 1, 12, 0, 0);
        original.markDiscovered(timestamp);

        expect(original.discoveredAt, isNull);
        expect(original.isDiscovered, isFalse);
      });

      test('preserves all other fields in the returned copy', () {
        final original = buildDiscovery(
          id: 'node/999',
          name: 'Test POI',
          category: 'viewpoint',
          rarity: RarityTier.rare,
        );
        final timestamp = DateTime(2024, 6, 1);
        final discovered = original.markDiscovered(timestamp);

        expect(discovered.id, equals('node/999'));
        expect(discovered.name, equals('Test POI'));
        expect(discovered.category, equals('viewpoint'));
        expect(discovered.rarity, equals(RarityTier.rare));
        expect(discovered.position, equals(position));
        expect(discovered.osmTags, equals(osmTags));
      });

      test('calling markDiscovered twice returns independent copies', () {
        final original = buildDiscovery();
        final t1 = DateTime(2024, 6, 1);
        final t2 = DateTime(2024, 6, 2);

        final d1 = original.markDiscovered(t1);
        final d2 = original.markDiscovered(t2);

        expect(d1.discoveredAt, equals(t1));
        expect(d2.discoveredAt, equals(t2));
        expect(original.discoveredAt, isNull);
      });
    });

    group('RarityTier values', () {
      test('has three tiers: common, uncommon, rare', () {
        expect(RarityTier.values.length, equals(3));
        expect(
            RarityTier.values,
            containsAll([
              RarityTier.common,
              RarityTier.uncommon,
              RarityTier.rare,
            ]));
      });
    });

    group('equality and identity', () {
      test(
          'two discoveries with same id but different discoveredAt are different objects',
          () {
        final t = DateTime(2024);
        final d1 = buildDiscovery(id: 'node/1');
        final d2 = buildDiscovery(id: 'node/1', discoveredAt: t);

        expect(identical(d1, d2), isFalse);
        expect(d1.id, equals(d2.id));
        expect(d1.discoveredAt, isNull);
        expect(d2.discoveredAt, equals(t));
      });
    });

    group('osmTags immutability', () {
      test('osmTags map is not the same mutable reference', () {
        final mutableTags = <String, String>{'amenity': 'cafe'};
        final d = Discovery(
          id: 'node/1',
          name: 'Cafe',
          category: 'cafe',
          rarity: RarityTier.common,
          position: position,
          osmTags: Map.unmodifiable(mutableTags),
          discoveredAt: null,
        );
        mutableTags['amenity'] = 'restaurant';
        expect(d.osmTags['amenity'], equals('cafe'));
      });
    });
  });
}
