import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/core/quiz/generated_question.dart';
import 'package:dander/core/quiz/question_type.dart';
import 'package:dander/features/quiz/presentation/screens/mixed_quiz_question_screen.dart';
import 'package:dander/features/quiz/presentation/widgets/question_type_header.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

GeneratedQuestion _question({
  QuestionType type = QuestionType.direction,
  String prompt = 'Which direction is Pub B from Cafe A?',
  List<String> choices = const ['North', 'South', 'East', 'West'],
  int correctIndex = 0,
}) =>
    GeneratedQuestion(
      questionId: '${type.name}:test',
      type: type,
      prompt: prompt,
      choices: choices,
      correctIndex: correctIndex,
    );

void main() {
  group('MixedQuizQuestionScreen', () {
    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(
        _wrap(MixedQuizQuestionScreen(
          questions: [_question()],
          onComplete: (_) {},
        )),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows QuestionTypeHeader', (tester) async {
      await tester.pumpWidget(
        _wrap(MixedQuizQuestionScreen(
          questions: [_question()],
          onComplete: (_) {},
        )),
      );
      expect(find.byType(QuestionTypeHeader), findsOneWidget);
    });

    testWidgets('shows question prompt', (tester) async {
      await tester.pumpWidget(
        _wrap(MixedQuizQuestionScreen(
          questions: [_question(prompt: 'Where is the cafe?')],
          onComplete: (_) {},
        )),
      );
      expect(find.text('Where is the cafe?'), findsOneWidget);
    });

    testWidgets('shows all 4 choices', (tester) async {
      await tester.pumpWidget(
        _wrap(MixedQuizQuestionScreen(
          questions: [
            _question(choices: ['North', 'South', 'East', 'West']),
          ],
          onComplete: (_) {},
        )),
      );
      expect(find.text('North'), findsOneWidget);
      expect(find.text('South'), findsOneWidget);
      expect(find.text('East'), findsOneWidget);
      expect(find.text('West'), findsOneWidget);
    });

    testWidgets('shows Next button after selecting an answer', (tester) async {
      await tester.pumpWidget(
        _wrap(MixedQuizQuestionScreen(
          questions: [_question()],
          onComplete: (_) {},
        )),
      );

      // No Next button initially
      expect(find.text('Next'), findsNothing);

      // Tap the first choice
      await tester.tap(find.text('North'));
      await tester.pump();

      // Next button appears
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('advances to next question on Next tap', (tester) async {
      await tester.pumpWidget(
        _wrap(MixedQuizQuestionScreen(
          questions: [
            _question(prompt: 'Question 1'),
            _question(
              prompt: 'Question 2',
              type: QuestionType.category,
              choices: ['cafe', 'pub', 'park', 'shop'],
            ),
          ],
          onComplete: (_) {},
        )),
      );

      expect(find.text('Question 1'), findsOneWidget);

      // Answer and advance
      await tester.tap(find.text('North'));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pump();

      expect(find.text('Question 2'), findsOneWidget);
    });

    testWidgets('calls onComplete when all questions answered', (tester) async {
      var completed = false;
      int? correctCount;

      await tester.pumpWidget(
        _wrap(MixedQuizQuestionScreen(
          questions: [_question(correctIndex: 0)],
          onComplete: (count) {
            completed = true;
            correctCount = count;
          },
        )),
      );

      // Tap correct answer
      await tester.tap(find.text('North'));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pump();

      expect(completed, isTrue);
      expect(correctCount, 1);
    });

    testWidgets('shows progress indicator', (tester) async {
      await tester.pumpWidget(
        _wrap(MixedQuizQuestionScreen(
          questions: [_question(), _question(prompt: 'Q2')],
          onComplete: (_) {},
        )),
      );

      // Should show "1 / 2" or similar progress
      expect(find.textContaining('1'), findsWidgets);
    });
  });
}
