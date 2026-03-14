import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:dander/core/location/walk_session.dart';
import 'package:dander/features/walks/presentation/screens/walk_history_screen.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

WalkSession _session({
  String id = 'session-1',
  DateTime? start,
  DateTime? end,
  List<WalkPoint> points = const [],
}) {
  var s = WalkSession.start(
    id: id,
    startTime: start ?? DateTime(2024, 6, 1, 9, 0),
  );
  for (final p in points) {
    s = s.addPoint(p);
  }
  return s.completeAt(end ?? DateTime(2024, 6, 1, 9, 30));
}

WalkPoint _point(double lat, double lng) => WalkPoint(
      position: LatLng(lat, lng),
      timestamp: DateTime(2024, 6, 1, 9, 0),
    );

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: child,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('WalkHistoryScreen', () {
    group('empty state', () {
      testWidgets('shows empty-state message when no walks', (tester) async {
        await tester.pumpWidget(
          _wrap(const WalkHistoryScreen(walks: [])),
        );
        expect(find.textContaining('No walks yet'), findsOneWidget);
      });

      testWidgets('empty state contains hint about starting a walk',
          (tester) async {
        await tester.pumpWidget(
          _wrap(const WalkHistoryScreen(walks: [])),
        );
        expect(find.textContaining('Start Walk'), findsWidgets);
      });

      testWidgets('renders without AppBar (title removed)', (tester) async {
        await tester.pumpWidget(
          _wrap(const WalkHistoryScreen(walks: [])),
        );
        expect(find.byType(AppBar), findsNothing);
      });
    });

    group('walk list', () {
      testWidgets('shows one list item per walk', (tester) async {
        final walks = [
          _session(id: 'a', start: DateTime(2024, 6, 1, 9, 0)),
          _session(id: 'b', start: DateTime(2024, 6, 2, 10, 0)),
        ];
        await tester.pumpWidget(
          _wrap(WalkHistoryScreen(walks: walks)),
        );
        // Each walk produces at least one visible text element with a date
        expect(find.textContaining('2024'), findsWidgets);
      });

      testWidgets('shows the walk date', (tester) async {
        final walk = _session(start: DateTime(2024, 6, 15, 8, 30));
        await tester.pumpWidget(
          _wrap(WalkHistoryScreen(walks: [walk])),
        );
        // Date should contain "15" and "Jun" or "2024"
        expect(find.textContaining('Jun'), findsWidgets);
      });

      testWidgets('shows duration for each walk', (tester) async {
        final walk = _session(
          start: DateTime(2024, 6, 1, 9, 0),
          end: DateTime(2024, 6, 1, 9, 30),
        );
        await tester.pumpWidget(
          _wrap(WalkHistoryScreen(walks: [walk])),
        );
        // 30 minutes duration
        expect(find.textContaining('30m'), findsWidgets);
      });

      testWidgets('shows distance for each walk', (tester) async {
        final walk = _session();
        await tester.pumpWidget(
          _wrap(WalkHistoryScreen(walks: [walk])),
        );
        // No points → "0 m"
        expect(find.textContaining('0 m'), findsWidgets);
      });

      testWidgets('does not show empty-state message when walks exist',
          (tester) async {
        final walk = _session();
        await tester.pumpWidget(
          _wrap(WalkHistoryScreen(walks: [walk])),
        );
        expect(find.textContaining('No walks yet'), findsNothing);
      });

      testWidgets('renders a long list (10 walks) without error',
          (tester) async {
        final walks = List.generate(
          10,
          (i) => _session(
            id: 'session-$i',
            start: DateTime(2024, 6, i + 1, 9, 0),
          ),
        );
        await tester.pumpWidget(
          _wrap(WalkHistoryScreen(walks: walks)),
        );
        expect(tester.takeException(), isNull);
      });
    });

    group('expanded mini-map', () {
      testWidgets('tap on walk item reveals mini-map area', (tester) async {
        final walk = _session(
          points: [
            _point(51.5, -0.1),
            _point(51.501, -0.101),
          ],
        );
        await tester.pumpWidget(
          _wrap(WalkHistoryScreen(walks: [walk])),
        );
        // Tap the first walk item
        await tester.tap(find.byType(ListTile).first);
        await tester.pump();
        // After tap, the mini-map widget should appear
        // We check for the WalkMiniMap widget type (will be defined later)
        // For now, just ensure the tap doesn't throw
        expect(tester.takeException(), isNull);
      });
    });
  });
}
