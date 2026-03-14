import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dander/core/location/walk_session.dart';
import 'package:dander/features/map/presentation/widgets/walk_control.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: Scaffold(body: Stack(children: [child])),
    );

WalkSession _activeSession({DateTime? start}) {
  final session = WalkSession.start(
    id: 'test-session',
    startTime: start ?? DateTime(2024, 6, 1, 9, 0, 0),
  );
  return session;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('WalkControl', () {
    group('idle state', () {
      testWidgets('shows Start Walk button when no session active',
          (tester) async {
        await tester.pumpWidget(
          _wrap(
            WalkControl(
              session: null,
              onStart: () {},
              onStop: (_) {},
            ),
          ),
        );
        expect(find.textContaining('Start Walk'), findsOneWidget);
      });

      testWidgets('does not show End Walk button in idle state',
          (tester) async {
        await tester.pumpWidget(
          _wrap(
            WalkControl(
              session: null,
              onStart: () {},
              onStop: (_) {},
            ),
          ),
        );
        expect(find.textContaining('End Walk'), findsNothing);
      });

      testWidgets('does not show distance/duration stats in idle state',
          (tester) async {
        await tester.pumpWidget(
          _wrap(
            WalkControl(
              session: null,
              onStart: () {},
              onStop: (_) {},
            ),
          ),
        );
        // No live stats labels visible when idle
        expect(find.textContaining('Distance'), findsNothing);
        expect(find.textContaining('Duration'), findsNothing);
      });

      testWidgets('onStart callback fires when Start Walk tapped',
          (tester) async {
        var started = false;
        await tester.pumpWidget(
          _wrap(
            WalkControl(
              session: null,
              onStart: () => started = true,
              onStop: (_) {},
            ),
          ),
        );
        await tester.tap(find.textContaining('Start Walk'));
        await tester.pump();
        expect(started, isTrue);
      });
    });

    group('active state', () {
      testWidgets('shows End Walk button when session is active',
          (tester) async {
        final session = _activeSession();
        await tester.pumpWidget(
          _wrap(
            WalkControl(
              session: session,
              onStart: () {},
              onStop: (_) {},
            ),
          ),
        );
        expect(find.textContaining('End Walk'), findsOneWidget);
      });

      testWidgets('does not show Start Walk in active state', (tester) async {
        final session = _activeSession();
        await tester.pumpWidget(
          _wrap(
            WalkControl(
              session: session,
              onStart: () {},
              onStop: (_) {},
            ),
          ),
        );
        expect(find.textContaining('Start Walk'), findsNothing);
      });

      testWidgets('shows Duration stat label in active state', (tester) async {
        final session = _activeSession();
        await tester.pumpWidget(
          _wrap(
            WalkControl(
              session: session,
              onStart: () {},
              onStop: (_) {},
            ),
          ),
        );
        expect(find.textContaining('Duration'), findsOneWidget);
      });

      testWidgets('shows Distance stat label in active state', (tester) async {
        final session = _activeSession();
        await tester.pumpWidget(
          _wrap(
            WalkControl(
              session: session,
              onStart: () {},
              onStop: (_) {},
            ),
          ),
        );
        expect(find.textContaining('Distance'), findsOneWidget);
      });

      testWidgets('shows Discoveries stat label in active state',
          (tester) async {
        final session = _activeSession();
        await tester.pumpWidget(
          _wrap(
            WalkControl(
              session: session,
              onStart: () {},
              onStop: (_) {},
              discoveriesThisWalk: 3,
            ),
          ),
        );
        expect(find.textContaining('Discoveries'), findsOneWidget);
      });

      testWidgets('shows discovery count when discoveries > 0', (tester) async {
        final session = _activeSession();
        await tester.pumpWidget(
          _wrap(
            WalkControl(
              session: session,
              onStart: () {},
              onStop: (_) {},
              discoveriesThisWalk: 5,
            ),
          ),
        );
        expect(find.textContaining('5'), findsWidgets);
      });

      testWidgets('onStop callback fires when End Walk tapped', (tester) async {
        WalkSession? stopped;
        final session = _activeSession();
        await tester.pumpWidget(
          _wrap(
            WalkControl(
              session: session,
              onStart: () {},
              onStop: (s) => stopped = s,
            ),
          ),
        );
        await tester.tap(find.textContaining('End Walk'));
        await tester.pump();
        expect(stopped, isNotNull);
      });

      testWidgets('displays formatted distance from session', (tester) async {
        // A session with no points has 0 m distance
        final session = _activeSession();
        await tester.pumpWidget(
          _wrap(
            WalkControl(
              session: session,
              onStart: () {},
              onStop: (_) {},
            ),
          ),
        );
        // Should show "0 m" as the distance value
        expect(find.textContaining('0 m'), findsWidgets);
      });
    });

    group('discoveriesThisWalk default', () {
      testWidgets('defaults to 0 discoveries', (tester) async {
        final session = _activeSession();
        await tester.pumpWidget(
          _wrap(
            WalkControl(
              session: session,
              onStart: () {},
              onStop: (_) {},
            ),
          ),
        );
        // Should render without error when discoveriesThisWalk omitted
        expect(tester.takeException(), isNull);
      });
    });

    group('session XP', () {
      testWidgets('shows XP stat label in active state', (tester) async {
        final session = _activeSession();
        await tester.pumpWidget(
          _wrap(
            WalkControl(
              session: session,
              onStart: () {},
              onStop: (_) {},
              sessionXp: 30,
            ),
          ),
        );
        expect(find.text('XP'), findsOneWidget);
        expect(find.text('30'), findsOneWidget);
      });

      testWidgets('defaults to 0 XP', (tester) async {
        final session = _activeSession();
        await tester.pumpWidget(
          _wrap(
            WalkControl(
              session: session,
              onStart: () {},
              onStop: (_) {},
            ),
          ),
        );
        expect(find.text('XP'), findsOneWidget);
      });
    });
  });
}
