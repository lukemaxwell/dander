import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/zone/mystery_poi.dart';
import 'package:dander/features/map/presentation/widgets/mystery_poi_marker_layer.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Wraps [child] inside a FlutterMap so that [MapCamera] is available via
/// [BuildContext].  The map is set to a fixed 400x600 viewport for testing.
Widget _withMap({
  required Widget child,
  LatLng center = const LatLng(51.5074, -0.1278),
  double zoom = 15.0,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 400,
        height: 600,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: zoom,
          ),
          children: [
            Builder(
              builder: (context) {
                final camera = MapCamera.of(context);
                return child is MysteryPoiMarkerLayer
                    ? MysteryPoiMarkerLayer(
                        pois: (child as MysteryPoiMarkerLayer).pois,
                        camera: camera,
                      )
                    : child;
              },
            ),
          ],
        ),
      ),
    ),
  );
}

/// Returns a [MysteryPoiMarkerLayer] inside a minimal [FlutterMap].
///
/// The [MapCamera] is captured from the Builder context and passed through,
/// matching the pattern used in [MapScreen._buildMap].
Widget _layerWidget({
  required List<MysteryPoi> pois,
  LatLng center = const LatLng(51.5074, -0.1278),
  double zoom = 15.0,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 400,
        height: 600,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: zoom,
          ),
          children: [
            Builder(
              builder: (context) {
                final camera = MapCamera.of(context);
                return MysteryPoiMarkerLayer(pois: pois, camera: camera);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

const _center = LatLng(51.5074, -0.1278);

MysteryPoi _unrevealed({String id = 'p1'}) => MysteryPoi(
      id: id,
      position: _center,
      category: 'pub',
    );

MysteryPoi _revealed({String id = 'p1'}) => MysteryPoi(
      id: id,
      position: _center,
      category: 'pub',
      name: 'The Red Lion',
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('MysteryPoiMarkerLayer', () {
    testWidgets('renders without error with empty poi list', (tester) async {
      await tester.pumpWidget(_layerWidget(pois: const []));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(MysteryPoiMarkerLayer), findsOneWidget);
    });

    testWidgets('renders a marker for each unrevealed POI', (tester) async {
      final pois = [
        _unrevealed(id: 'p1'),
        _unrevealed(id: 'p2'),
        _unrevealed(id: 'p3'),
      ];

      await tester.pumpWidget(_layerWidget(pois: pois));
      await tester.pump();

      expect(tester.takeException(), isNull);
      // Three unrevealed POIs should produce three '?' text widgets.
      expect(find.text('?'), findsNWidgets(3));
    });

    testWidgets('renders trophy icon for revealed POI', (tester) async {
      final pois = [_revealed()];

      await tester.pumpWidget(_layerWidget(pois: pois));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
    });

    testWidgets('renders mix of revealed and unrevealed POIs', (tester) async {
      final pois = [
        _unrevealed(id: 'p1'),
        _revealed(id: 'p2'),
        _unrevealed(id: 'p3'),
      ];

      await tester.pumpWidget(_layerWidget(pois: pois));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('?'), findsNWidgets(2));
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
    });

    testWidgets('does not render trophy for unrevealed POI', (tester) async {
      final pois = [_unrevealed()];

      await tester.pumpWidget(_layerWidget(pois: pois));
      await tester.pump();

      expect(find.byIcon(Icons.emoji_events), findsNothing);
    });

    testWidgets('does not render ? marker for revealed POI', (tester) async {
      final pois = [_revealed()];

      await tester.pumpWidget(_layerWidget(pois: pois));
      await tester.pump();

      expect(find.text('?'), findsNothing);
    });
  });

  group('MysteryPoiMarkerPainter.shouldRepaint', () {
    test('returns true when pois list changes', () {
      const poi1 = MysteryPoi(id: 'a', position: _center, category: 'pub');
      final oldPainter = MysteryPoiMarkerPainter(
        pois: const [poi1],
        pulseProgress: 0.0,
      );
      final newPainter = MysteryPoiMarkerPainter(
        pois: const [],
        pulseProgress: 0.0,
      );

      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });

    test('returns true when pulseProgress changes', () {
      const poi1 = MysteryPoi(id: 'a', position: _center, category: 'pub');
      final oldPainter = MysteryPoiMarkerPainter(
        pois: const [poi1],
        pulseProgress: 0.0,
      );
      final newPainter = MysteryPoiMarkerPainter(
        pois: const [poi1],
        pulseProgress: 0.5,
      );

      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });

    test('returns false when pois and pulseProgress are identical', () {
      const poi1 = MysteryPoi(id: 'a', position: _center, category: 'pub');
      final pois = [poi1];
      final oldPainter = MysteryPoiMarkerPainter(
        pois: pois,
        pulseProgress: 0.3,
      );
      final newPainter = MysteryPoiMarkerPainter(
        pois: pois,
        pulseProgress: 0.3,
      );

      expect(newPainter.shouldRepaint(oldPainter), isFalse);
    });
  });
}
