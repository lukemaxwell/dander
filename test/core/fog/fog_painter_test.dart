import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' show LatLngBounds;
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:dander/core/fog/fog_grid.dart';
import 'package:dander/core/fog/fog_painter.dart';

void main() {
  const origin = LatLng(51.5, -0.05);

  group('FogPainter', () {
    group('construction', () {
      test('creates painter with fog grid and viewport', () {
        final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
        final viewport = FogViewport(
          bounds: LatLngBounds(
            const LatLng(51.495, -0.06),
            const LatLng(51.505, -0.04),
          ),
          canvasSize: const Size(400, 600),
        );
        expect(
          () => FogPainter(fogGrid: grid, viewport: viewport),
          returnsNormally,
        );
      });
    });

    group('shouldRepaint', () {
      test('returns true when fog grid changes', () {
        final grid1 = FogGrid(origin: origin, cellSizeMeters: 10.0);
        final grid2 = FogGrid(origin: origin, cellSizeMeters: 10.0);
        grid2.markExplored(origin, 50.0);

        final viewport = FogViewport(
          bounds: LatLngBounds(
            const LatLng(51.495, -0.06),
            const LatLng(51.505, -0.04),
          ),
          canvasSize: const Size(400, 600),
        );
        final painter1 = FogPainter(fogGrid: grid1, viewport: viewport);
        final painter2 = FogPainter(fogGrid: grid2, viewport: viewport);
        expect(painter1.shouldRepaint(painter2), isTrue);
      });

      test('returns false when both grids are identical', () {
        final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
        grid.markExplored(origin, 50.0);

        final viewport = FogViewport(
          bounds: LatLngBounds(
            const LatLng(51.495, -0.06),
            const LatLng(51.505, -0.04),
          ),
          canvasSize: const Size(400, 600),
        );
        final painter1 = FogPainter(fogGrid: grid, viewport: viewport);
        final painter2 = FogPainter(fogGrid: grid, viewport: viewport);
        expect(painter1.shouldRepaint(painter2), isFalse);
      });

      test('returns true when viewport changes', () {
        final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
        final viewport1 = FogViewport(
          bounds: LatLngBounds(
            const LatLng(51.495, -0.06),
            const LatLng(51.505, -0.04),
          ),
          canvasSize: const Size(400, 600),
        );
        final viewport2 = FogViewport(
          bounds: LatLngBounds(
            const LatLng(51.490, -0.07),
            const LatLng(51.510, -0.03),
          ),
          canvasSize: const Size(400, 600),
        );
        final painter1 = FogPainter(fogGrid: grid, viewport: viewport1);
        final painter2 = FogPainter(fogGrid: grid, viewport: viewport2);
        expect(painter1.shouldRepaint(painter2), isTrue);
      });
    });

    group('FogPainter widget rendering', () {
      testWidgets('renders a CustomPaint widget', (tester) async {
        final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
        final viewport = FogViewport(
          bounds: LatLngBounds(
            const LatLng(51.495, -0.06),
            const LatLng(51.505, -0.04),
          ),
          canvasSize: const Size(400, 600),
        );
        final painter = FogPainter(fogGrid: grid, viewport: viewport);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 600,
                child: CustomPaint(painter: painter),
              ),
            ),
          ),
        );

        expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
      });

      testWidgets('renders without error with explored cells', (tester) async {
        final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
        grid.markExplored(origin, 50.0);

        final viewport = FogViewport(
          bounds: LatLngBounds(
            const LatLng(51.495, -0.06),
            const LatLng(51.505, -0.04),
          ),
          canvasSize: const Size(400, 600),
        );
        final painter = FogPainter(fogGrid: grid, viewport: viewport);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 600,
                child: CustomPaint(painter: painter),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('renders without error with large explored area',
          (tester) async {
        final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
        grid.markExplored(origin, 600.0);
        // Ensure 10k+ cells

        final viewport = FogViewport(
          bounds: LatLngBounds(
            const LatLng(51.490, -0.07),
            const LatLng(51.510, -0.03),
          ),
          canvasSize: const Size(400, 600),
        );
        final painter = FogPainter(fogGrid: grid, viewport: viewport);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 600,
                child: CustomPaint(painter: painter),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });
    });

  });

  group('FogViewport', () {
    test('creates viewport with bounds and canvas size', () {
      final viewport = FogViewport(
        bounds: LatLngBounds(
          const LatLng(51.495, -0.06),
          const LatLng(51.505, -0.04),
        ),
        canvasSize: const Size(400, 600),
      );
      expect(viewport.canvasSize, equals(const Size(400, 600)));
    });

    test('lngToX converts longitude to canvas x coordinate', () {
      final viewport = FogViewport(
        bounds: LatLngBounds(
          const LatLng(51.495, -0.06),
          const LatLng(51.505, -0.04),
        ),
        canvasSize: const Size(400, 600),
      );
      // Left edge longitude maps to 0
      expect(viewport.lngToX(-0.06), closeTo(0.0, 1.0));
      // Right edge longitude maps to 400
      expect(viewport.lngToX(-0.04), closeTo(400.0, 1.0));
    });

    test('latToY converts latitude to canvas y coordinate', () {
      final viewport = FogViewport(
        bounds: LatLngBounds(
          const LatLng(51.495, -0.06),
          const LatLng(51.505, -0.04),
        ),
        canvasSize: const Size(400, 600),
      );
      // Top latitude (north = higher lat) maps to 0
      expect(viewport.latToY(51.505), closeTo(0.0, 1.0));
      // Bottom latitude maps to 600
      expect(viewport.latToY(51.495), closeTo(600.0, 1.0));
    });
  });
}
