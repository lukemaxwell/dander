import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' show LatLngBounds;
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:dander/core/fog/fog_grid.dart';
import 'package:dander/features/map/presentation/widgets/fog_layer.dart';

void main() {
  const origin = LatLng(51.5, -0.05);
  final bounds = LatLngBounds(
    const LatLng(51.495, -0.06),
    const LatLng(51.505, -0.04),
  );

  group('FogLayer', () {
    testWidgets('renders CustomPaint over the map area', (tester) async {
      final fogNotifier = ValueNotifier<FogGrid>(
        FogGrid(origin: origin, cellSizeMeters: 10.0),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: FogLayer(
                fogGridNotifier: fogNotifier,
                bounds: bounds,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FogLayer), findsOneWidget);
      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
    });

    testWidgets('renders without error with unexplored grid', (tester) async {
      final fogNotifier = ValueNotifier<FogGrid>(
        FogGrid(origin: origin, cellSizeMeters: 10.0),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: FogLayer(
                fogGridNotifier: fogNotifier,
                bounds: bounds,
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('repaints when fog grid notifier updates', (tester) async {
      final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
      final fogNotifier = ValueNotifier<FogGrid>(grid);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: FogLayer(
                fogGridNotifier: fogNotifier,
                bounds: bounds,
              ),
            ),
          ),
        ),
      );

      // Update the grid
      final newGrid = FogGrid(origin: origin, cellSizeMeters: 10.0);
      newGrid.markExplored(origin, 50.0);
      fogNotifier.value = newGrid;

      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('disposes notifier listener on widget removal', (tester) async {
      final fogNotifier = ValueNotifier<FogGrid>(
        FogGrid(origin: origin, cellSizeMeters: 10.0),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: FogLayer(
                fogGridNotifier: fogNotifier,
                bounds: bounds,
              ),
            ),
          ),
        ),
      );

      // Remove the widget
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );

      // After removal, updating notifier should not throw
      expect(
        () => fogNotifier.value = FogGrid(origin: origin, cellSizeMeters: 10.0),
        returnsNormally,
      );
    });

    testWidgets('handles stream of location updates', (tester) async {
      final controller = StreamController<LatLng>();
      final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
      final fogNotifier = ValueNotifier<FogGrid>(grid);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: FogLayer(
                fogGridNotifier: fogNotifier,
                bounds: bounds,
                locationStream: controller.stream,
                exploreRadius: 50.0,
              ),
            ),
          ),
        ),
      );

      // Emit a location update
      controller.add(origin);
      await tester.pump();

      // The fog grid should now have explored cells
      expect(fogNotifier.value.exploredCount, greaterThan(0));

      await controller.close();
    });

    testWidgets('explores cells along multiple location updates',
        (tester) async {
      final controller = StreamController<LatLng>();
      final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
      final fogNotifier = ValueNotifier<FogGrid>(grid);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: FogLayer(
                fogGridNotifier: fogNotifier,
                bounds: bounds,
                locationStream: controller.stream,
                exploreRadius: 50.0,
              ),
            ),
          ),
        ),
      );

      controller.add(origin);
      await tester.pump();
      final countAfterFirst = fogNotifier.value.exploredCount;

      controller.add(const LatLng(51.502, -0.048));
      await tester.pump();

      expect(fogNotifier.value.exploredCount, greaterThan(countAfterFirst));

      await controller.close();
    });
  });
}
