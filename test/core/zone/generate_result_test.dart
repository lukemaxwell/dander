import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/zone/generate_result.dart';
import 'package:dander/core/zone/mystery_poi.dart';

void main() {
  // ---------------------------------------------------------------------------
  // GenerateResult model
  // ---------------------------------------------------------------------------

  group('GenerateResult', () {
    test('holds activePois and totalCount', () {
      final poi = MysteryPoi(
        id: 'poi_1',
        position: LatLng(51.5074, -0.1278),
        category: 'pub',
      );
      final result = GenerateResult(activePois: [poi], totalCount: 5);

      expect(result.activePois, hasLength(1));
      expect(result.activePois.first.id, 'poi_1');
      expect(result.totalCount, 5);
    });

    test('supports empty activePois with zero totalCount', () {
      const result = GenerateResult(activePois: [], totalCount: 0);

      expect(result.activePois, isEmpty);
      expect(result.totalCount, 0);
    });

    test('is const-constructable', () {
      // Compile-time constant — verifies const constructor exists.
      const result = GenerateResult(activePois: [], totalCount: 0);
      expect(result, isA<GenerateResult>());
    });

    test('totalCount may exceed activePois length (filtered > cap)', () {
      final pois = List.generate(
        3,
        (i) => MysteryPoi(
          id: 'poi_$i',
          position: LatLng(51.5074, -0.1278),
          category: 'pub',
        ),
      );
      final result = GenerateResult(activePois: pois, totalCount: 10);

      expect(result.activePois, hasLength(3));
      expect(result.totalCount, 10);
    });
  });
}
