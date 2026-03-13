import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:dander/core/quiz/quiz_result.dart';
import 'package:dander/core/quiz/quiz_session.dart';
import 'package:dander/core/quiz/quiz_streak_tracker.dart';
import 'package:dander/core/quiz/street_memory_record.dart';
import 'package:dander/core/streets/street.dart';
import 'package:dander/features/quiz/presentation/screens/quiz_summary_screen.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Street _street(String id, String name) => Street(
      id: id,
      name: name,
      nodes: const [LatLng(51.5, -0.1)],
      walkedAt: DateTime(2024, 1, 1),
    );

List<Street> _streets(int count) => List.generate(
      count,
      (i) => _street('way/$i', 'Street $i'),
    );

QuizSession _completedSession(int total, int correct) {
  final streets = _streets(total);
  var session = QuizSession.create(streets, <StreetMemoryRecord>[]);
  for (var i = 0; i < total; i++) {
    final result = i < correct ? QuizResult.correct : QuizResult.incorrect;
    session = session.answerCurrent(result);
  }
  return session;
}

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: child,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('QuizSummaryScreen', () {
    group('stats displayed', () {
      testWidgets('shows correct count', (tester) async {
        final session = _completedSession(4, 3);
        await tester.pumpWidget(
          _wrap(QuizSummaryScreen(
            session: session,
            streak: QuizStreakTracker.empty(),
            masteredThisSession: 1,
            onStartAnother: () {},
            onGoExplore: () {},
          )),
        );
        expect(find.textContaining('3'), findsAtLeastNWidgets(1));
      });

      testWidgets('shows total count', (tester) async {
        final session = _completedSession(4, 3);
        await tester.pumpWidget(
          _wrap(QuizSummaryScreen(
            session: session,
            streak: QuizStreakTracker.empty(),
            masteredThisSession: 1,
            onStartAnother: () {},
            onGoExplore: () {},
          )),
        );
        expect(find.textContaining('4'), findsAtLeastNWidgets(1));
      });

      testWidgets('shows accuracy percentage', (tester) async {
        // 3/4 = 75%
        final session = _completedSession(4, 3);
        await tester.pumpWidget(
          _wrap(QuizSummaryScreen(
            session: session,
            streak: QuizStreakTracker.empty(),
            masteredThisSession: 0,
            onStartAnother: () {},
            onGoExplore: () {},
          )),
        );
        expect(find.textContaining('75'), findsAtLeastNWidgets(1));
      });

      testWidgets('shows mastered this session count', (tester) async {
        final session = _completedSession(4, 4);
        await tester.pumpWidget(
          _wrap(QuizSummaryScreen(
            session: session,
            streak: QuizStreakTracker.empty(),
            masteredThisSession: 2,
            onStartAnother: () {},
            onGoExplore: () {},
          )),
        );
        expect(find.textContaining('2'), findsAtLeastNWidgets(1));
      });

      testWidgets('shows streak count', (tester) async {
        final tracker = QuizStreakTracker(
          currentStreak: 5,
          lastSessionDate: DateTime.now(),
        );
        final session = _completedSession(4, 2);
        await tester.pumpWidget(
          _wrap(QuizSummaryScreen(
            session: session,
            streak: tracker,
            masteredThisSession: 0,
            onStartAnother: () {},
            onGoExplore: () {},
          )),
        );
        expect(find.textContaining('5'), findsAtLeastNWidgets(1));
      });

      testWidgets('renders without throwing', (tester) async {
        final session = _completedSession(4, 2);
        await tester.pumpWidget(
          _wrap(QuizSummaryScreen(
            session: session,
            streak: QuizStreakTracker.empty(),
            masteredThisSession: 0,
            onStartAnother: () {},
            onGoExplore: () {},
          )),
        );
        expect(tester.takeException(), isNull);
      });
    });

    group('buttons', () {
      testWidgets('Start Another button is present', (tester) async {
        final session = _completedSession(4, 2);
        await tester.pumpWidget(
          _wrap(QuizSummaryScreen(
            session: session,
            streak: QuizStreakTracker.empty(),
            masteredThisSession: 0,
            onStartAnother: () {},
            onGoExplore: () {},
          )),
        );
        expect(find.textContaining('Start Another'), findsOneWidget);
      });

      testWidgets('Go Explore button is present', (tester) async {
        final session = _completedSession(4, 2);
        await tester.pumpWidget(
          _wrap(QuizSummaryScreen(
            session: session,
            streak: QuizStreakTracker.empty(),
            masteredThisSession: 0,
            onStartAnother: () {},
            onGoExplore: () {},
          )),
        );
        expect(find.textContaining('Explore'), findsAtLeastNWidgets(1));
      });

      testWidgets('onStartAnother fires when tapped', (tester) async {
        var tapped = false;
        final session = _completedSession(4, 2);
        await tester.pumpWidget(
          _wrap(QuizSummaryScreen(
            session: session,
            streak: QuizStreakTracker.empty(),
            masteredThisSession: 0,
            onStartAnother: () => tapped = true,
            onGoExplore: () {},
          )),
        );
        await tester.tap(find.textContaining('Start Another'));
        expect(tapped, isTrue);
      });

      testWidgets('onGoExplore fires when Go Explore tapped', (tester) async {
        var tapped = false;
        final session = _completedSession(4, 2);
        await tester.pumpWidget(
          _wrap(QuizSummaryScreen(
            session: session,
            streak: QuizStreakTracker.empty(),
            masteredThisSession: 0,
            onStartAnother: () {},
            onGoExplore: () => tapped = true,
          )),
        );
        await tester.tap(find.textContaining('Go Explore'));
        expect(tapped, isTrue);
      });
    });
  });
}
