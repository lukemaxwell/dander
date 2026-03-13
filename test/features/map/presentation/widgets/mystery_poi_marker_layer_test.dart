import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/zone/mystery_poi.dart';
import 'package:dander/features/map/presentation/widgets/mystery_poi_marker_layer.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

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

MysteryPoi _unrevealed({String id = 'p1', String category = 'pub'}) =>
    MysteryPoi(
      id: id,
      position: _center,
      category: category,
    );

MysteryPoi _hinted({String id = 'p1', String category = 'pub'}) => MysteryPoi(
      id: id,
      position: _center,
      category: category,
      state: PoiState.hinted,
    );

MysteryPoi _revealed({
  String id = 'p1',
  String category = 'pub',
  String name = 'The Red Lion',
}) =>
    MysteryPoi(
      id: id,
      position: _center,
      category: category,
      name: name,
      state: PoiState.revealed,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('MysteryPoiMarkerLayer', () {
    // -----------------------------------------------------------------------
    // Empty list
    // -----------------------------------------------------------------------

    testWidgets('renders without error with empty poi list', (tester) async {
      await tester.pumpWidget(_layerWidget(pois: const []));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(MysteryPoiMarkerLayer), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Unrevealed state — no markers
    // -----------------------------------------------------------------------

    testWidgets('unrevealed POIs produce zero markers', (tester) async {
      final pois = [
        _unrevealed(id: 'p1'),
        _unrevealed(id: 'p2'),
        _unrevealed(id: 'p3'),
      ];

      await tester.pumpWidget(_layerWidget(pois: pois));
      await tester.pump();

      expect(tester.takeException(), isNull);
      // Unrevealed POIs must NOT render any visible marker.
      expect(find.text('?'), findsNothing);
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('single unrevealed POI renders nothing', (tester) async {
      await tester.pumpWidget(_layerWidget(pois: [_unrevealed()]));
      await tester.pump();

      expect(find.text('?'), findsNothing);
      expect(find.byType(Icon), findsNothing);
    });

    // -----------------------------------------------------------------------
    // Hinted state — amber pulsing "?" circle
    // -----------------------------------------------------------------------

    testWidgets('hinted POI shows ? text', (tester) async {
      await tester.pumpWidget(_layerWidget(pois: [_hinted()]));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('multiple hinted POIs each show a ? text', (tester) async {
      final pois = [_hinted(id: 'p1'), _hinted(id: 'p2'), _hinted(id: 'p3')];

      await tester.pumpWidget(_layerWidget(pois: pois));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('?'), findsNWidgets(3));
    });

    testWidgets('hinted POI does not show a category icon', (tester) async {
      await tester.pumpWidget(_layerWidget(pois: [_hinted(category: 'cafe')]));
      await tester.pump();

      expect(find.byIcon(Icons.coffee), findsNothing);
    });

    // -----------------------------------------------------------------------
    // Revealed state — category pin
    // -----------------------------------------------------------------------

    testWidgets('revealed pub POI shows sports_bar icon', (tester) async {
      await tester.pumpWidget(
        _layerWidget(pois: [_revealed(category: 'pub')]),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.sports_bar), findsOneWidget);
    });

    testWidgets('revealed cafe POI shows coffee icon', (tester) async {
      await tester.pumpWidget(
        _layerWidget(pois: [_revealed(category: 'cafe')]),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.coffee), findsOneWidget);
    });

    testWidgets('revealed park POI shows park icon', (tester) async {
      await tester.pumpWidget(
        _layerWidget(pois: [_revealed(category: 'park')]),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.park), findsOneWidget);
    });

    testWidgets('revealed POI with unknown category shows place icon',
        (tester) async {
      await tester.pumpWidget(
        _layerWidget(pois: [_revealed(category: 'unknown_xyz')]),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.place), findsOneWidget);
    });

    testWidgets('revealed POI does not show ? text', (tester) async {
      await tester.pumpWidget(
        _layerWidget(pois: [_revealed(category: 'pub')]),
      );
      await tester.pump();

      expect(find.text('?'), findsNothing);
    });

    // -----------------------------------------------------------------------
    // Mixed state list
    // -----------------------------------------------------------------------

    testWidgets('mixed state list renders correctly', (tester) async {
      final pois = [
        _unrevealed(id: 'p1', category: 'pub'),
        _hinted(id: 'p2', category: 'cafe'),
        _revealed(id: 'p3', category: 'park'),
      ];

      await tester.pumpWidget(_layerWidget(pois: pois));
      await tester.pump();

      expect(tester.takeException(), isNull);
      // Unrevealed: nothing. Hinted: one '?'. Revealed: park icon.
      expect(find.text('?'), findsOneWidget);
      expect(find.byIcon(Icons.park), findsOneWidget);
      // No icon for the unrevealed pub or the hinted cafe.
      expect(find.byIcon(Icons.sports_bar), findsNothing);
      expect(find.byIcon(Icons.coffee), findsNothing);
    });

    testWidgets('two hinted and one revealed renders 2 question marks and 1 icon',
        (tester) async {
      final pois = [
        _hinted(id: 'p1'),
        _hinted(id: 'p2'),
        _revealed(id: 'p3', category: 'cafe'),
      ];

      await tester.pumpWidget(_layerWidget(pois: pois));
      await tester.pump();

      expect(find.text('?'), findsNWidgets(2));
      expect(find.byIcon(Icons.coffee), findsOneWidget);
    });

    testWidgets('all three states together: 0 unrevealed markers, 1 hinted, 1 revealed',
        (tester) async {
      final pois = [
        _unrevealed(id: 'p1'),
        _unrevealed(id: 'p2'),
        _hinted(id: 'p3'),
        _revealed(id: 'p4', category: 'historic'),
      ];

      await tester.pumpWidget(_layerWidget(pois: pois));
      await tester.pump();

      expect(find.text('?'), findsOneWidget);
      expect(find.byIcon(Icons.account_balance), findsOneWidget);
      expect(find.byIcon(Icons.sports_bar), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  // Painter unit tests
  // -------------------------------------------------------------------------

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
