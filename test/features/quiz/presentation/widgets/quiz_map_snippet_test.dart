import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:dander/core/streets/street.dart';
import 'package:dander/features/quiz/presentation/widgets/quiz_map_snippet.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 400,
          child: child,
        ),
      ),
    );

Street _streetWith(List<LatLng> nodes) => Street(
      id: 'way/1',
      name: 'Baker Street',
      nodes: nodes,
      walkedAt: null,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('QuizMapSnippet', () {
    testWidgets('renders with IgnorePointer — non-interactive', (tester) async {
      final street = _streetWith(const [
        LatLng(51.520, -0.156),
        LatLng(51.521, -0.157),
      ]);

      await tester.pumpWidget(_wrap(QuizMapSnippet(street: street)));

      expect(find.byType(IgnorePointer), findsAtLeast(1));
    });

    testWidgets('contains a PolylineLayer for the street', (tester) async {
      final street = _streetWith(const [
        LatLng(51.520, -0.156),
        LatLng(51.521, -0.157),
      ]);

      await tester.pumpWidget(_wrap(QuizMapSnippet(street: street)));

      expect(find.byType(PolylineLayer), findsOneWidget);
    });

    testWidgets('has fixed height of 280.0', (tester) async {
      final street = _streetWith(const [
        LatLng(51.520, -0.156),
        LatLng(51.521, -0.157),
      ]);

      await tester.pumpWidget(_wrap(QuizMapSnippet(street: street)));

      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(QuizMapSnippet),
          matching: find.byWidgetPredicate(
            (w) => w is SizedBox && w.height == 280.0,
          ),
        ),
      );
      expect(sizedBox.height, equals(280.0));
    });

    testWidgets('handles single-node street without throwing', (tester) async {
      final street = _streetWith(const [LatLng(51.520, -0.156)]);

      await tester.pumpWidget(_wrap(QuizMapSnippet(street: street)));

      expect(tester.takeException(), isNull);
    });

    testWidgets('handles empty nodes gracefully without throwing',
        (tester) async {
      final street = _streetWith(const []);

      await tester.pumpWidget(_wrap(QuizMapSnippet(street: street)));

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders FlutterMap widget', (tester) async {
      final street = _streetWith(const [
        LatLng(51.520, -0.156),
        LatLng(51.521, -0.157),
      ]);

      await tester.pumpWidget(_wrap(QuizMapSnippet(street: street)));

      expect(find.byType(FlutterMap), findsOneWidget);
    });

    testWidgets('gold polyline uses correct color', (tester) async {
      final street = _streetWith(const [
        LatLng(51.520, -0.156),
        LatLng(51.521, -0.157),
      ]);

      await tester.pumpWidget(_wrap(QuizMapSnippet(street: street)));

      final polylineLayer =
          tester.widget<PolylineLayer>(find.byType(PolylineLayer));
      expect(polylineLayer.polylines, isNotEmpty);
      expect(polylineLayer.polylines.first.color, equals(const Color(0xFFFFD700)));
    });
  });
}
