import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/zone/mystery_poi.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  MysteryPoi makePoi({
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

  // ---------------------------------------------------------------------------
  // Construction
  // ---------------------------------------------------------------------------

  group('MysteryPoi construction', () {
    test('creates with required fields and null name by default', () {
      final poi = makePoi();
      expect(poi.id, 'poi_1');
      expect(poi.position.latitude, 51.5074);
      expect(poi.position.longitude, -0.1278);
      expect(poi.category, 'pub');
      expect(poi.name, isNull);
    });

    test('creates with explicit name when provided', () {
      final poi = makePoi(name: 'The Crown');
      expect(poi.name, 'The Crown');
    });

    test('accepts all valid categories', () {
      const validCategories = [
        'pub',
        'park',
        'historic',
        'street_art',
        'viewpoint',
        'cafe',
        'library',
      ];
      for (final cat in validCategories) {
        expect(() => makePoi(category: cat), returnsNormally);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // isRevealed getter
  // ---------------------------------------------------------------------------

  group('isRevealed', () {
    test('returns false when name is null', () {
      final poi = makePoi(name: null);
      expect(poi.isRevealed, isFalse);
    });

    test('returns true when name is set', () {
      final poi = makePoi(name: 'The Crown');
      expect(poi.isRevealed, isTrue);
    });

    test('empty string name is treated as revealed', () {
      final poi = makePoi(name: '');
      expect(poi.isRevealed, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // reveal()
  // ---------------------------------------------------------------------------

  group('reveal()', () {
    test('returns new MysteryPoi with name set', () {
      final original = makePoi(name: null);
      final revealed = original.reveal('The Crown');

      expect(revealed.name, 'The Crown');
      expect(revealed.isRevealed, isTrue);
    });

    test('preserves all other fields', () {
      final original = makePoi(id: 'poi_42', lat: 48.8566, lng: 2.3522, category: 'park');
      final revealed = original.reveal('Luxembourg Gardens');

      expect(revealed.id, 'poi_42');
      expect(revealed.position.latitude, 48.8566);
      expect(revealed.position.longitude, 2.3522);
      expect(revealed.category, 'park');
    });

    test('does not mutate the original (immutability)', () {
      final original = makePoi(name: null);
      original.reveal('The Crown');

      expect(original.name, isNull);
      expect(original.isRevealed, isFalse);
    });

    test('can reveal an already-revealed poi with a new name', () {
      final first = makePoi(name: 'Old Name');
      final second = first.reveal('New Name');

      expect(second.name, 'New Name');
      expect(first.name, 'Old Name'); // original unchanged
    });

    test('returns a different object instance', () {
      final original = makePoi();
      final revealed = original.reveal('Name');

      expect(revealed, isNot(same(original)));
    });
  });

  // ---------------------------------------------------------------------------
  // JSON round-trip
  // ---------------------------------------------------------------------------

  group('toJson / fromJson', () {
    test('round-trips an unrevealed poi', () {
      final poi = makePoi(id: 'poi_7', lat: 51.5, lng: -0.1, category: 'cafe');
      final json = poi.toJson();
      final restored = MysteryPoi.fromJson(json);

      expect(restored.id, poi.id);
      expect(restored.position.latitude, poi.position.latitude);
      expect(restored.position.longitude, poi.position.longitude);
      expect(restored.category, poi.category);
      expect(restored.name, isNull);
      expect(restored.isRevealed, isFalse);
    });

    test('round-trips a revealed poi', () {
      final poi = makePoi(name: 'The Red Lion');
      final json = poi.toJson();
      final restored = MysteryPoi.fromJson(json);

      expect(restored.name, 'The Red Lion');
      expect(restored.isRevealed, isTrue);
    });

    test('toJson omits name key when null', () {
      final poi = makePoi(name: null);
      final json = poi.toJson();

      expect(json.containsKey('name'), isFalse);
    });

    test('toJson includes name key when set', () {
      final poi = makePoi(name: 'Hyde Park');
      final json = poi.toJson();

      expect(json['name'], 'Hyde Park');
    });

    test('fromJson handles missing name key gracefully', () {
      final map = {
        'id': 'poi_1',
        'lat': 51.5,
        'lng': -0.1,
        'category': 'park',
      };
      final poi = MysteryPoi.fromJson(map);

      expect(poi.name, isNull);
      expect(poi.isRevealed, isFalse);
    });

    test('toJson produces correct field names', () {
      final poi = makePoi(id: 'poi_99', lat: 40.0, lng: -3.0, category: 'historic');
      final json = poi.toJson();

      expect(json['id'], 'poi_99');
      expect(json['lat'], 40.0);
      expect(json['lng'], -3.0);
      expect(json['category'], 'historic');
    });

    test('restores position accurately', () {
      final poi = makePoi(lat: 48.8566, lng: 2.3522);
      final restored = MysteryPoi.fromJson(poi.toJson());

      expect(restored.position.latitude, closeTo(48.8566, 0.00001));
      expect(restored.position.longitude, closeTo(2.3522, 0.00001));
    });
  });

  // ---------------------------------------------------------------------------
  // Edge cases
  // ---------------------------------------------------------------------------

  group('edge cases', () {
    test('id with special characters is preserved', () {
      final poi = makePoi(id: 'node/12345');
      final restored = MysteryPoi.fromJson(poi.toJson());
      expect(restored.id, 'node/12345');
    });

    test('name with unicode characters is preserved', () {
      final poi = makePoi(name: 'Café du Monde');
      final restored = MysteryPoi.fromJson(poi.toJson());
      expect(restored.name, 'Café du Monde');
    });

    test('extreme lat/lng values are preserved', () {
      final poi = MysteryPoi(
        id: 'polar',
        position: LatLng(89.9, 179.9),
        category: 'viewpoint',
      );
      final restored = MysteryPoi.fromJson(poi.toJson());
      expect(restored.position.latitude, closeTo(89.9, 0.00001));
      expect(restored.position.longitude, closeTo(179.9, 0.00001));
    });
  });
}
