import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' show LatLngBounds;
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/fog/fog_grid.dart';
import 'package:dander/core/fog/fog_painter.dart';
import 'package:dander/features/map/presentation/widgets/fog_layer.dart';

void main() {
  const origin = LatLng(51.5, -0.05);

  final defaultBounds = LatLngBounds(
    const LatLng(51.495, -0.06),
    const LatLng(51.505, -0.04),
  );

  const defaultCanvasSize = Size(400, 600);

  FogViewport makeViewport() => FogViewport(
        bounds: defaultBounds,
        canvasSize: defaultCanvasSize,
      );

  group('FogPainter — boundary shimmer', () {
    test('accepts shimmerValue and reducedMotion params', () {
      final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
      expect(
        () => FogPainter(
          fogGrid: grid,
          viewport: makeViewport(),
          shimmerValue: 0.5,
          reducedMotion: false,
        ),
        returnsNormally,
      );
    });

    for (final shimmer in [0.0, 0.25, 0.5, 0.75, 1.0]) {
      testWidgets('renders without error at shimmerValue=$shimmer', (tester) async {
        final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
        grid.markExplored(origin, 30.0);

        final painter = FogPainter(
          fogGrid: grid,
          viewport: makeViewport(),
          shimmerValue: shimmer,
          reducedMotion: false,
        );

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
    }

    testWidgets('renders without error with reducedMotion=true', (tester) async {
      final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
      grid.markExplored(origin, 30.0);

      final painter = FogPainter(
        fogGrid: grid,
        viewport: makeViewport(),
        shimmerValue: 0.5,
        reducedMotion: true,
      );

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

    test('shouldRepaint returns true when shimmerValue changes', () {
      final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
      final viewport = makeViewport();
      final p1 = FogPainter(fogGrid: grid, viewport: viewport, shimmerValue: 0.0);
      final p2 = FogPainter(fogGrid: grid, viewport: viewport, shimmerValue: 0.5);
      expect(p1.shouldRepaint(p2), isTrue);
    });

    test('shouldRepaint returns false when shimmerValue unchanged', () {
      final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
      final viewport = makeViewport();
      final p1 = FogPainter(fogGrid: grid, viewport: viewport, shimmerValue: 0.5);
      final p2 = FogPainter(fogGrid: grid, viewport: viewport, shimmerValue: 0.5);
      expect(p1.shouldRepaint(p2), isFalse);
    });
  });

  group('FogLayer — boundary animation', () {
    testWidgets('animates shimmer when motion is not reduced', (tester) async {
      final fogGridNotifier =
          ValueNotifier<FogGrid>(FogGrid(origin: origin, cellSizeMeters: 10.0));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: FogLayer(
                fogGridNotifier: fogGridNotifier,
                bounds: defaultBounds,
              ),
            ),
          ),
        ),
      );

      // Pump some time — should not throw during animation.
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);

      fogGridNotifier.dispose();
    });

    testWidgets('no crash with reduced motion enabled', (tester) async {
      final fogGridNotifier =
          ValueNotifier<FogGrid>(FogGrid(origin: origin, cellSizeMeters: 10.0));

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 600,
                child: FogLayer(
                  fogGridNotifier: fogGridNotifier,
                  bounds: defaultBounds,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);

      fogGridNotifier.dispose();
    });
  });
}
