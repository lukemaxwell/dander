import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/debug/fog_seeder.dart';
import 'package:dander/core/fog/fog_grid.dart';

void main() {
  group('FogSeeder', () {
    const origin = LatLng(51.4769, -0.0005);

    test('returns empty grid when no paths provided', () {
      final grid = FogSeeder.seed(origin: origin, walkedPaths: []);
      expect(grid.exploredCount, equals(0));
      expect(grid.origin, equals(origin));
    });

    test('marks cells along a single path', () {
      final path = [
        const LatLng(51.4769, -0.0005),
        const LatLng(51.4770, -0.0004),
        const LatLng(51.4771, -0.0003),
      ];

      final grid = FogSeeder.seed(
        origin: origin,
        walkedPaths: [path],
      );

      expect(grid.exploredCount, greaterThan(0));
    });

    test('marks cells along multiple paths', () {
      final path1 = [
        const LatLng(51.4769, -0.0005),
        const LatLng(51.4770, -0.0004),
      ];
      final path2 = [
        const LatLng(51.4775, 0.0010),
        const LatLng(51.4776, 0.0011),
      ];

      final singlePathGrid = FogSeeder.seed(
        origin: origin,
        walkedPaths: [path1],
      );
      final multiPathGrid = FogSeeder.seed(
        origin: origin,
        walkedPaths: [path1, path2],
      );

      expect(
        multiPathGrid.exploredCount,
        greaterThan(singlePathGrid.exploredCount),
      );
    });

    test('uses configured explore radius', () {
      final path = [const LatLng(51.4769, -0.0005)];

      final smallRadius = FogSeeder.seed(
        origin: origin,
        walkedPaths: [path],
        exploreRadiusMeters: 20.0,
      );
      final largeRadius = FogSeeder.seed(
        origin: origin,
        walkedPaths: [path],
        exploreRadiusMeters: 100.0,
      );

      expect(
        largeRadius.exploredCount,
        greaterThan(smallRadius.exploredCount),
      );
    });

    test('uses configured cell size', () {
      final path = [const LatLng(51.4769, -0.0005)];

      final smallCells = FogSeeder.seed(
        origin: origin,
        walkedPaths: [path],
        cellSizeMeters: 5.0,
      );
      final largeCells = FogSeeder.seed(
        origin: origin,
        walkedPaths: [path],
        cellSizeMeters: 20.0,
      );

      // Smaller cells → more cells explored for the same radius
      expect(
        smallCells.exploredCount,
        greaterThan(largeCells.exploredCount),
      );
    });

    test('generated grid has correct origin', () {
      final grid = FogSeeder.seed(
        origin: origin,
        walkedPaths: [[const LatLng(51.4769, -0.0005)]],
      );
      expect(grid.origin, equals(origin));
    });
  });
}
