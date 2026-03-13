import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:dander/features/walks/presentation/widgets/walk_mini_map.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: Scaffold(
        body: SizedBox(
          width: 300,
          height: 200,
          child: child,
        ),
      ),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('WalkMiniMap', () {
    testWidgets('renders without error with an empty points list',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const WalkMiniMap(points: [])),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows placeholder text when points list is empty',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const WalkMiniMap(points: [])),
      );
      expect(find.textContaining('No route'), findsOneWidget);
    });

    testWidgets('renders without error with a single point', (tester) async {
      await tester.pumpWidget(
        _wrap(const WalkMiniMap(points: [LatLng(51.5, -0.1)])),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without error with multiple points', (tester) async {
      const points = [
        LatLng(51.500, -0.100),
        LatLng(51.501, -0.101),
        LatLng(51.502, -0.102),
        LatLng(51.503, -0.103),
      ];
      await tester.pumpWidget(
        _wrap(const WalkMiniMap(points: points)),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('is non-interactive — drag gesture does not throw',
        (tester) async {
      const points = [
        LatLng(51.500, -0.100),
        LatLng(51.501, -0.101),
      ];
      await tester.pumpWidget(
        _wrap(const WalkMiniMap(points: points)),
      );
      // Attempt a pan gesture; IgnorePointer should swallow it without error.
      await tester.drag(find.byType(WalkMiniMap), const Offset(50, 50));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits inside its given size constraints', (tester) async {
      const points = [
        LatLng(51.500, -0.100),
        LatLng(51.502, -0.102),
      ];
      await tester.pumpWidget(
        _wrap(const WalkMiniMap(points: points)),
      );
      // No overflow errors expected in a 300x200 box.
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders with points far apart (large route)', (tester) async {
      const points = [
        LatLng(51.0, -0.1),
        LatLng(52.0, -1.0), // ~150 km apart
      ];
      await tester.pumpWidget(
        _wrap(const WalkMiniMap(points: points)),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders WalkMiniMap widget type', (tester) async {
      await tester.pumpWidget(
        _wrap(const WalkMiniMap(points: [LatLng(51.5, -0.1)])),
      );
      expect(find.byType(WalkMiniMap), findsOneWidget);
    });
  });
}
