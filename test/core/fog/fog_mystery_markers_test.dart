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

  FogViewport makeViewport({LatLngBounds? bounds, Size? size}) => FogViewport(
        bounds: bounds ?? defaultBounds,
        canvasSize: size ?? defaultCanvasSize,
      );

  group('FogPainter — mystery POI markers', () {
    test('accepts mysteryPois and pulseValue params', () {
      final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
      final viewport = makeViewport();
      expect(
        () => FogPainter(
          fogGrid: grid,
          viewport: viewport,
          mysteryPois: const [LatLng(51.501, -0.051)],
          pulseValue: 0.5,
        ),
        returnsNormally,
      );
    });

    testWidgets('renders without error with mystery pois in fog', (tester) async {
      final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
      // Don't explore — pois remain in fog.
      final viewport = makeViewport();
      final painter = FogPainter(
        fogGrid: grid,
        viewport: viewport,
        mysteryPois: const [LatLng(51.501, -0.051), LatLng(51.499, -0.048)],
        pulseValue: 0.7,
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

    testWidgets('renders without error when pois are explored (cleared)', (tester) async {
      final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
      // Explore the area containing the poi — marker should not render.
      grid.markExplored(const LatLng(51.501, -0.051), 100.0);
      final viewport = makeViewport();
      final painter = FogPainter(
        fogGrid: grid,
        viewport: viewport,
        mysteryPois: const [LatLng(51.501, -0.051)],
        pulseValue: 0.5,
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

    test('shouldRepaint returns true when mysteryPois changes', () {
      final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
      final viewport = makeViewport();
      final painter1 = FogPainter(
        fogGrid: grid,
        viewport: viewport,
        mysteryPois: const [],
        pulseValue: 0.0,
      );
      final painter2 = FogPainter(
        fogGrid: grid,
        viewport: viewport,
        mysteryPois: const [LatLng(51.501, -0.051)],
        pulseValue: 0.0,
      );
      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('shouldRepaint returns true when pulseValue changes', () {
      final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
      final viewport = makeViewport();
      final painter1 = FogPainter(
        fogGrid: grid,
        viewport: viewport,
        mysteryPois: const [],
        pulseValue: 0.0,
      );
      final painter2 = FogPainter(
        fogGrid: grid,
        viewport: viewport,
        mysteryPois: const [],
        pulseValue: 0.5,
      );
      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('shouldRepaint returns false when nothing changes', () {
      final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
      final viewport = makeViewport();
      const pois = [LatLng(51.501, -0.051)];
      final painter1 = FogPainter(
        fogGrid: grid,
        viewport: viewport,
        mysteryPois: pois,
        pulseValue: 0.5,
      );
      final painter2 = FogPainter(
        fogGrid: grid,
        viewport: viewport,
        mysteryPois: pois,
        pulseValue: 0.5,
      );
      expect(painter1.shouldRepaint(painter2), isFalse);
    });
  });

  group('FogLayer — mystery POI markers', () {
    testWidgets('accepts mysteryPois param and renders', (tester) async {
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
                mysteryPois: const [LatLng(51.501, -0.051)],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(FogLayer), findsOneWidget);

      fogGridNotifier.dispose();
    });

    testWidgets('renders with empty mysteryPois by default', (tester) async {
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

      expect(tester.takeException(), isNull);
      fogGridNotifier.dispose();
    });

    testWidgets('renders with reduced motion — no animation tickers active',
        (tester) async {
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
                  mysteryPois: const [LatLng(51.501, -0.051)],
                ),
              ),
            ),
          ),
        ),
      );

      // Should render without error in reduced-motion mode.
      expect(tester.takeException(), isNull);
      fogGridNotifier.dispose();
    });
  });
}
