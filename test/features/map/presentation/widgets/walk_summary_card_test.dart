import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dander/core/location/walk_session.dart';
import 'package:dander/features/map/presentation/widgets/walk_summary_card.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

WalkSession _completedSession({
  String id = 'session-1',
  DateTime? start,
  DateTime? end,
}) {
  final session = WalkSession.start(
    id: id,
    startTime: start ?? DateTime(2024, 6, 1, 9, 0, 0),
  );
  return session.completeAt(end ?? DateTime(2024, 6, 1, 9, 30, 0));
}

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: Scaffold(body: child),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('WalkSummaryCard', () {
    group('stat display', () {
      testWidgets('shows walk duration', (tester) async {
        final session = _completedSession(
          start: DateTime(2024, 6, 1, 9, 0, 0),
          end: DateTime(2024, 6, 1, 9, 30, 0),
        );
        await tester.pumpWidget(
          _wrap(
            WalkSummaryCard(
              session: session,
              fogClearedPercent: 5.2,
              discoveriesFound: 3,
              onDone: () {},
              onShare: () {},
            ),
          ),
        );
        // 30 minutes → "30m 0s"
        expect(find.textContaining('30m'), findsWidgets);
      });

      testWidgets('shows distance stat', (tester) async {
        // Two points ~1 km apart would give ~1 km distance.
        // For simplicity use a session with no points → "0 m".
        final session = _completedSession();
        await tester.pumpWidget(
          _wrap(
            WalkSummaryCard(
              session: session,
              fogClearedPercent: 0,
              discoveriesFound: 0,
              onDone: () {},
              onShare: () {},
            ),
          ),
        );
        expect(find.textContaining('Distance'), findsOneWidget);
      });

      testWidgets('shows fog cleared percentage', (tester) async {
        final session = _completedSession();
        await tester.pumpWidget(
          _wrap(
            WalkSummaryCard(
              session: session,
              fogClearedPercent: 12.3,
              discoveriesFound: 0,
              onDone: () {},
              onShare: () {},
            ),
          ),
        );
        expect(find.textContaining('12.3%'), findsWidgets);
      });

      testWidgets('shows discoveries found count', (tester) async {
        final session = _completedSession();
        await tester.pumpWidget(
          _wrap(
            WalkSummaryCard(
              session: session,
              fogClearedPercent: 0,
              discoveriesFound: 7,
              onDone: () {},
              onShare: () {},
            ),
          ),
        );
        expect(find.textContaining('7'), findsWidgets);
      });

      testWidgets('shows Discoveries label', (tester) async {
        final session = _completedSession();
        await tester.pumpWidget(
          _wrap(
            WalkSummaryCard(
              session: session,
              fogClearedPercent: 0,
              discoveriesFound: 0,
              onDone: () {},
              onShare: () {},
            ),
          ),
        );
        expect(find.textContaining('Discoveries'), findsOneWidget);
      });

      testWidgets('shows Fog Cleared label', (tester) async {
        final session = _completedSession();
        await tester.pumpWidget(
          _wrap(
            WalkSummaryCard(
              session: session,
              fogClearedPercent: 0,
              discoveriesFound: 0,
              onDone: () {},
              onShare: () {},
            ),
          ),
        );
        expect(find.textContaining('Fog'), findsWidgets);
      });
    });

    group('buttons', () {
      testWidgets('Done button fires onDone callback', (tester) async {
        var done = false;
        final session = _completedSession();
        await tester.pumpWidget(
          _wrap(
            WalkSummaryCard(
              session: session,
              fogClearedPercent: 0,
              discoveriesFound: 0,
              onDone: () => done = true,
              onShare: () {},
            ),
          ),
        );
        await tester.tap(find.textContaining('Done'));
        await tester.pump();
        expect(done, isTrue);
      });

      testWidgets('Share button fires onShare callback', (tester) async {
        var shared = false;
        final session = _completedSession();
        await tester.pumpWidget(
          _wrap(
            WalkSummaryCard(
              session: session,
              fogClearedPercent: 0,
              discoveriesFound: 0,
              onDone: () {},
              onShare: () => shared = true,
            ),
          ),
        );
        await tester.tap(find.textContaining('Share'));
        await tester.pump();
        expect(shared, isTrue);
      });

      testWidgets('renders both Done and Share buttons', (tester) async {
        final session = _completedSession();
        await tester.pumpWidget(
          _wrap(
            WalkSummaryCard(
              session: session,
              fogClearedPercent: 0,
              discoveriesFound: 0,
              onDone: () {},
              onShare: () {},
            ),
          ),
        );
        expect(find.textContaining('Done'), findsOneWidget);
        expect(find.textContaining('Share'), findsOneWidget);
      });
    });

    group('edge cases', () {
      testWidgets('renders without error when fog cleared is 0%',
          (tester) async {
        final session = _completedSession();
        await tester.pumpWidget(
          _wrap(
            WalkSummaryCard(
              session: session,
              fogClearedPercent: 0,
              discoveriesFound: 0,
              onDone: () {},
              onShare: () {},
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('renders without error when fog cleared is 100%',
          (tester) async {
        final session = _completedSession();
        await tester.pumpWidget(
          _wrap(
            WalkSummaryCard(
              session: session,
              fogClearedPercent: 100,
              discoveriesFound: 99,
              onDone: () {},
              onShare: () {},
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('renders a title/heading text', (tester) async {
        final session = _completedSession();
        await tester.pumpWidget(
          _wrap(
            WalkSummaryCard(
              session: session,
              fogClearedPercent: 5,
              discoveriesFound: 2,
              onDone: () {},
              onShare: () {},
            ),
          ),
        );
        // Should have some kind of heading
        expect(find.byType(Text), findsWidgets);
      });
    });
  });
}
