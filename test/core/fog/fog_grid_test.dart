import 'package:flutter_map/flutter_map.dart' show LatLngBounds;
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:dander/core/fog/fog_cell.dart';
import 'package:dander/core/fog/fog_grid.dart';

void main() {
  // Origin point used for most tests: London, Hackney area
  const origin = LatLng(51.5, -0.05);

  group('FogGrid', () {
    group('construction', () {
      test('creates empty grid with given origin and cell size', () {
        final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
        expect(grid.exploredCount, equals(0));
      });

      test('default cell size is 10 meters', () {
        final grid = FogGrid(origin: origin);
        expect(grid.cellSizeMeters, equals(10.0));
      });
    });

    group('markExplored', () {
      test('marks cells within radius as explored', () {
        final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
        grid.markExplored(origin, 50.0);
        // A 50m radius around origin should mark cells
        expect(grid.exploredCount, greaterThan(0));
      });

      test('marks the origin cell as explored', () {
        final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
        grid.markExplored(origin, 50.0);
        expect(grid.isCellExplored(0, 0), isTrue);
      });

      test('does not mark cells outside the radius', () {
        final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
        grid.markExplored(origin, 50.0);
        // Cell 100 steps away should not be explored
        expect(grid.isCellExplored(100, 100), isFalse);
      });

      test('marks cells in circular pattern (corner cells outside 50m)', () {
        final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
        grid.markExplored(origin, 50.0);
        // Cell at exactly 6 steps (60m) diagonally should NOT be explored
        // sqrt((60)^2 + (60)^2) ≈ 84.8m > 50m
        expect(grid.isCellExplored(6, 6), isFalse);
      });

      test('marking same area twice does not double-count', () {
        final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
        grid.markExplored(origin, 50.0);
        final countAfterFirst = grid.exploredCount;
        grid.markExplored(origin, 50.0);
        expect(grid.exploredCount, equals(countAfterFirst));
      });

      test('marks cells around a different position', () {
        final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
        // Position 500m north of origin
        const northPos = LatLng(51.5045, -0.05);
        grid.markExplored(northPos, 50.0);
        // The origin cell should not be explored
        expect(grid.isCellExplored(0, 0), isFalse);
        // But cells around northPos should be
        expect(grid.exploredCount, greaterThan(0));
      });

      test('accumulates cells from multiple positions', () {
        final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
        grid.markExplored(origin, 50.0);
        final countAfterFirst = grid.exploredCount;
        // Far away position
        const farPos = LatLng(51.502, -0.05);
        grid.markExplored(farPos, 50.0);
        expect(grid.exploredCount, greaterThan(countAfterFirst));
      });
    });

    group('isCellExplored', () {
      test('returns false for unexplored cell', () {
        final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
        expect(grid.isCellExplored(0, 0), isFalse);
      });

      test('returns true after cell is explored', () {
        final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
        grid.markExplored(origin, 50.0);
        expect(grid.isCellExplored(0, 0), isTrue);
      });

      test('returns false for large negative coordinates', () {
        final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
        expect(grid.isCellExplored(-1000, -1000), isFalse);
      });
    });

    group('exploredCells', () {
      test('returns empty set when no cells explored', () {
        final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
        expect(grid.exploredCells, isEmpty);
      });

      test('returns all explored cells', () {
        final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
        grid.markExplored(origin, 50.0);
        expect(grid.exploredCells, isNotEmpty);
        expect(grid.exploredCells, isA<Set<FogCell>>());
      });

      test('explored cells are immutable (copy)', () {
        final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
        grid.markExplored(origin, 50.0);
        final cells = grid.exploredCells;
        // Modifying the returned set should not affect the grid
        cells.clear();
        expect(grid.exploredCount, greaterThan(0));
      });
    });

    group('latLngToCell', () {
      test('converts origin position to cell (0,0)', () {
        final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
        final cell = grid.latLngToCell(origin);
        expect(cell.x, equals(0));
        expect(cell.y, equals(0));
      });

      test('converts position north of origin to positive y cell', () {
        final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
        // ~15m north = at least 1 cell north (cell size = ~10m)
        const northPos =
            LatLng(51.500135, -0.05); // 0.000135 deg * 111111 ≈ 15m
        final cell = grid.latLngToCell(northPos);
        expect(cell.y, greaterThan(0));
      });

      test('converts position east of origin to positive x cell', () {
        final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
        // ~10m east
        const eastPos = LatLng(51.5, -0.0486);
        final cell = grid.latLngToCell(eastPos);
        expect(cell.x, greaterThan(0));
      });
    });

    group('explorationPercentage', () {
      test('returns 0.0 for unexplored grid', () {
        final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
        final bounds = LatLngBounds(
          const LatLng(51.495, -0.06),
          const LatLng(51.505, -0.04),
        );
        expect(grid.explorationPercentage(bounds), equals(0.0));
      });

      test('returns 1.0 when all cells in bounds are explored', () {
        final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
        // Mark a large area as explored
        grid.markExplored(origin, 2000.0);
        final bounds = LatLngBounds(
          const LatLng(51.4995, -0.0505),
          const LatLng(51.5005, -0.0495),
        );
        expect(grid.explorationPercentage(bounds), equals(1.0));
      });

      test('returns value between 0 and 1 for partially explored', () {
        final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
        grid.markExplored(origin, 50.0);
        final bounds = LatLngBounds(
          const LatLng(51.496, -0.06),
          const LatLng(51.504, -0.04),
        );
        final pct = grid.explorationPercentage(bounds);
        expect(pct, greaterThan(0.0));
        expect(pct, lessThan(1.0));
      });

      test('clamps result between 0.0 and 1.0', () {
        final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
        final bounds = LatLngBounds(
          const LatLng(51.495, -0.06),
          const LatLng(51.505, -0.04),
        );
        final pct = grid.explorationPercentage(bounds);
        expect(pct, greaterThanOrEqualTo(0.0));
        expect(pct, lessThanOrEqualTo(1.0));
      });
    });

    group('serialisation', () {
      test('toBytes produces non-empty bytes for explored grid', () {
        final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
        grid.markExplored(origin, 50.0);
        final bytes = grid.toBytes();
        expect(bytes, isNotEmpty);
      });

      test('fromBytes restores explored cells', () {
        final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
        grid.markExplored(origin, 50.0);
        final originalCount = grid.exploredCount;

        final bytes = grid.toBytes();
        final restored =
            FogGrid.fromBytes(bytes, origin: origin, cellSizeMeters: 10.0);

        expect(restored.exploredCount, equals(originalCount));
      });

      test('fromBytes restores specific explored cells', () {
        final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
        grid.markExplored(origin, 50.0);

        final bytes = grid.toBytes();
        final restored =
            FogGrid.fromBytes(bytes, origin: origin, cellSizeMeters: 10.0);

        expect(restored.isCellExplored(0, 0), isTrue);
      });

      test('fromBytes for empty grid returns empty grid', () {
        final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
        final bytes = grid.toBytes();
        final restored =
            FogGrid.fromBytes(bytes, origin: origin, cellSizeMeters: 10.0);
        expect(restored.exploredCount, equals(0));
      });

      test('round-trip preserves all explored cells', () {
        final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
        grid.markExplored(origin, 100.0);
        const pos2 = LatLng(51.501, -0.048);
        grid.markExplored(pos2, 50.0);
        final original = grid.exploredCells;

        final bytes = grid.toBytes();
        final restored =
            FogGrid.fromBytes(bytes, origin: origin, cellSizeMeters: 10.0);

        expect(restored.exploredCells, equals(original));
      });
    });

    group('performance', () {
      test('handles 10000+ explored cells without throwing', () {
        final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
        // Mark a large area to get 10k+ cells
        grid.markExplored(origin, 600.0);
        expect(grid.exploredCount, greaterThan(10000));
      });

      test('isCellExplored is O(1) with large grid', () {
        final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
        grid.markExplored(origin, 600.0);
        final stopwatch = Stopwatch()..start();
        for (var i = 0; i < 10000; i++) {
          grid.isCellExplored(i % 100, i % 100);
        }
        stopwatch.stop();
        // Should complete 10k lookups in under 100ms
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test('serialisation handles large grids', () {
        final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
        grid.markExplored(origin, 600.0);
        expect(
          () {
            final bytes = grid.toBytes();
            FogGrid.fromBytes(bytes, origin: origin, cellSizeMeters: 10.0);
          },
          returnsNormally,
        );
      });
    });
  });
}
