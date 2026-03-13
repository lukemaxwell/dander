import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:dander/core/quiz/quiz_session.dart';
import 'package:dander/core/quiz/quiz_result.dart';
import 'package:dander/core/quiz/street_memory_record.dart';
import 'package:dander/core/streets/street.dart';
import 'package:dander/features/quiz/presentation/screens/quiz_question_screen.dart';
import 'package:dander/features/quiz/presentation/widgets/choice_button.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Street _street(String id, String name) => Street(
      id: id,
      name: name,
      nodes: const [LatLng(51.5, -0.1)],
      walkedAt: DateTime(2024, 1, 1),
    );

List<Street> _buildStreets() => [
      _street('way/1', 'Baker Street'),
      _street('way/2', 'Oxford Street'),
      _street('way/3', 'Bond Street'),
      _street('way/4', 'Fleet Street'),
    ];

QuizSession _buildSession() =>
    QuizSession.create(_buildStreets(), <StreetMemoryRecord>[]);

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: child,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('QuizQuestionScreen', () {
    group('unanswered state', () {
      testWidgets('shows question prompt text', (tester) async {
        final session = _buildSession();
        await tester.pumpWidget(
          _wrap(QuizQuestionScreen(session: session, onComplete: (_) {})),
        );
        expect(find.textContaining('street'), findsAtLeast(1));
      });

      testWidgets('shows 4 ChoiceButton widgets', (tester) async {
        final session = _buildSession();
        await tester.pumpWidget(
          _wrap(QuizQuestionScreen(session: session, onComplete: (_) {})),
        );
        expect(find.byType(ChoiceButton), findsNWidgets(4));
      });

      testWidgets('Next button is not visible before answering', (tester) async {
        final session = _buildSession();
        await tester.pumpWidget(
          _wrap(QuizQuestionScreen(session: session, onComplete: (_) {})),
        );
        expect(find.text('Next'), findsNothing);
      });

      testWidgets('all buttons are in unanswered state initially',
          (tester) async {
        final session = _buildSession();
        await tester.pumpWidget(
          _wrap(QuizQuestionScreen(session: session, onComplete: (_) {})),
        );
        final buttons = tester.widgetList<ChoiceButton>(find.byType(ChoiceButton));
        for (final btn in buttons) {
          expect(btn.state, equals(ChoiceButtonState.unanswered));
        }
      });
    });

    group('answered state', () {
      testWidgets('Next button appears after tapping a choice', (tester) async {
        final session = _buildSession();
        await tester.pumpWidget(
          _wrap(QuizQuestionScreen(session: session, onComplete: (_) {})),
        );

        await tester.tap(find.byType(ChoiceButton).first);
        await tester.pump();

        expect(find.text('Next'), findsOneWidget);
      });

      testWidgets('correct choice button shows correct state', (tester) async {
        final session = _buildSession();
        final correctIndex = session.currentQuestion.correctIndex;

        await tester.pumpWidget(
          _wrap(QuizQuestionScreen(session: session, onComplete: (_) {})),
        );

        final correctFinder = find.byType(ChoiceButton).at(correctIndex);
        await tester.tap(correctFinder);
        await tester.pump();

        final button = tester.widget<ChoiceButton>(correctFinder);
        expect(button.state, equals(ChoiceButtonState.correct));
      });

      testWidgets('incorrect choice shows incorrect state on selected button',
          (tester) async {
        final session = _buildSession();
        final correctIndex = session.currentQuestion.correctIndex;
        // Find wrong index
        final wrongIndex = correctIndex == 0 ? 1 : 0;

        await tester.pumpWidget(
          _wrap(QuizQuestionScreen(session: session, onComplete: (_) {})),
        );

        final wrongFinder = find.byType(ChoiceButton).at(wrongIndex);
        await tester.tap(wrongFinder);
        await tester.pump();

        final button = tester.widget<ChoiceButton>(wrongFinder);
        expect(button.state, equals(ChoiceButtonState.incorrect));
      });

      testWidgets('all non-selected buttons become disabled after answering',
          (tester) async {
        final session = _buildSession();

        await tester.pumpWidget(
          _wrap(QuizQuestionScreen(session: session, onComplete: (_) {})),
        );

        await tester.tap(find.byType(ChoiceButton).first);
        await tester.pump();

        final buttons = tester.widgetList<ChoiceButton>(find.byType(ChoiceButton));
        // All buttons should either be correct, incorrect, or disabled (not unanswered)
        for (final btn in buttons) {
          expect(btn.state, isNot(equals(ChoiceButtonState.unanswered)));
        }
      });

      testWidgets('tapping a button twice does not change state', (tester) async {
        final session = _buildSession();
        await tester.pumpWidget(
          _wrap(QuizQuestionScreen(session: session, onComplete: (_) {})),
        );

        await tester.tap(find.byType(ChoiceButton).first);
        await tester.pump();
        final stateAfterFirst = tester
            .widget<ChoiceButton>(find.byType(ChoiceButton).first)
            .state;

        await tester.tap(find.byType(ChoiceButton).last);
        await tester.pump();
        final stateAfterSecond = tester
            .widget<ChoiceButton>(find.byType(ChoiceButton).first)
            .state;

        expect(stateAfterFirst, equals(stateAfterSecond));
      });
    });

    group('Next button', () {
      testWidgets('onComplete is called with completed session when last question answered',
          (tester) async {
        // Single-question session
        final streets = [
          _street('way/1', 'Baker Street'),
          _street('way/2', 'Oxford Street'),
          _street('way/3', 'Bond Street'),
          _street('way/4', 'Fleet Street'),
        ];
        final session = QuizSession.create(streets, <StreetMemoryRecord>[]);

        // Answer all questions until complete
        QuizSession? completedSession;
        late QuizSession currentSession;
        currentSession = session;

        // We'll use a wrapper that rebuilds with new session on Next
        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return MaterialApp(
                theme: ThemeData(splashFactory: NoSplash.splashFactory),
                home: QuizQuestionScreen(
                  session: currentSession,
                  onComplete: (s) {
                    completedSession = s;
                  },
                ),
              );
            },
          ),
        );

        // Answer all questions
        for (var i = 0; i < session.questions.length; i++) {
          // Tap first choice
          await tester.tap(find.byType(ChoiceButton).first);
          await tester.pump();
          // Scroll to make Next visible
          await tester.ensureVisible(find.text('Next'));
          await tester.pump();
          // Tap Next
          await tester.tap(find.text('Next'));
          await tester.pump();
        }

        expect(completedSession, isNotNull);
        expect(completedSession!.isComplete, isTrue);
      });
    });
  });
}
