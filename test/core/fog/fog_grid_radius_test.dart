import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/fog/fog_grid.dart';

void main() {
  group('FogGrid — micro-reveal radius', () {
    final origin = LatLng(51.5074, -0.1278);

    test('100m radius clears more cells than 50m radius', () {
      final grid50 = FogGrid(origin: origin);
      grid50.markExplored(origin, 50.0);

      final grid100 = FogGrid(origin: origin);
      grid100.markExplored(origin, 100.0);

      expect(grid100.exploredCount, greaterThan(grid50.exploredCount));
    });

    test('100m radius clears roughly 4x the cells of 50m (area scales r^2)', () {
      final grid50 = FogGrid(origin: origin);
      grid50.markExplored(origin, 50.0);

      final grid100 = FogGrid(origin: origin);
      grid100.markExplored(origin, 100.0);

      // Area ratio should be ~4x (pi*100^2 / pi*50^2 = 4)
      // Allow 3x–5x to account for grid cell discretisation
      final ratio = grid100.exploredCount / grid50.exploredCount;
      expect(ratio, greaterThan(3.0));
      expect(ratio, lessThan(5.0));
    });

    test('50m radius clears a reasonable number of 10m cells', () {
      final grid = FogGrid(origin: origin);
      grid.markExplored(origin, 50.0);

      // Area of 50m circle ≈ 7854 m^2, each cell = 100 m^2 → ~78 cells
      expect(grid.exploredCount, greaterThan(60));
      expect(grid.exploredCount, lessThan(100));
    });

    test('100m radius clears a reasonable number of 10m cells', () {
      final grid = FogGrid(origin: origin);
      grid.markExplored(origin, 100.0);

      // Area of 100m circle ≈ 31416 m^2, each cell = 100 m^2 → ~314 cells
      expect(grid.exploredCount, greaterThan(250));
      expect(grid.exploredCount, lessThan(400));
    });
  });
}
