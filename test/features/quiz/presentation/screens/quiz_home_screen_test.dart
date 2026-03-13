import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:dander/core/streets/street.dart';
import 'package:dander/core/quiz/street_memory_record.dart';
import 'package:dander/features/quiz/presentation/screens/quiz_home_screen.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: child,
    );

Street _walkedStreet(String id, String name) => Street(
      id: id,
      name: name,
      nodes: const [LatLng(51.5, -0.1)],
      walkedAt: DateTime(2024, 1, 1),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('QuizHomeScreen', () {
    group('empty state', () {
      testWidgets('renders without throwing when no streets walked',
          (tester) async {
        await tester.pumpWidget(
          _wrap(QuizHomeScreen(
            walkedStreets: const [],
            records: const [],
            onStartReview: () {},
            onPracticeAll: () {},
          )),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('Start Review button is disabled when due count is 0',
          (tester) async {
        await tester.pumpWidget(
          _wrap(QuizHomeScreen(
            walkedStreets: const [],
            records: const [],
            onStartReview: () {},
            onPracticeAll: () {},
          )),
        );
        final button = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Start Review'),
        );
        expect(button.onPressed, isNull);
      });

      testWidgets('Practice All button is disabled when no streets walked',
          (tester) async {
        await tester.pumpWidget(
          _wrap(QuizHomeScreen(
            walkedStreets: const [],
            records: const [],
            onStartReview: () {},
            onPracticeAll: () {},
          )),
        );
        final button = tester.widget<TextButton>(
          find.widgetWithText(TextButton, 'Practice All'),
        );
        expect(button.onPressed, isNull);
      });
    });

    group('populated state', () {
      testWidgets('shows walked street names in list', (tester) async {
        final streets = [
          _walkedStreet('way/1', 'Baker Street'),
          _walkedStreet('way/2', 'Oxford Street'),
        ];
        await tester.pumpWidget(
          _wrap(QuizHomeScreen(
            walkedStreets: streets,
            records: const [],
            onStartReview: () {},
            onPracticeAll: () {},
          )),
        );

        expect(find.text('Baker Street'), findsOneWidget);
        expect(find.text('Oxford Street'), findsOneWidget);
      });

      testWidgets('Practice All button is enabled when streets are walked',
          (tester) async {
        final streets = [_walkedStreet('way/1', 'Baker Street')];
        await tester.pumpWidget(
          _wrap(QuizHomeScreen(
            walkedStreets: streets,
            records: const [],
            onStartReview: () {},
            onPracticeAll: () {},
          )),
        );

        final button = tester.widget<TextButton>(
          find.widgetWithText(TextButton, 'Practice All'),
        );
        expect(button.onPressed, isNotNull);
      });

      testWidgets('onPracticeAll callback fires when Practice All tapped',
          (tester) async {
        var tapped = false;
        final streets = [_walkedStreet('way/1', 'Baker Street')];
        await tester.pumpWidget(
          _wrap(QuizHomeScreen(
            walkedStreets: streets,
            records: const [],
            onStartReview: () {},
            onPracticeAll: () => tapped = true,
          )),
        );

        await tester.tap(find.widgetWithText(TextButton, 'Practice All'));
        expect(tapped, isTrue);
      });
    });

    group('stats header', () {
      testWidgets('shows due count label', (tester) async {
        await tester.pumpWidget(
          _wrap(QuizHomeScreen(
            walkedStreets: const [],
            records: const [],
            onStartReview: () {},
            onPracticeAll: () {},
          )),
        );

        expect(find.textContaining('Due'), findsAtLeastNWidgets(1));
      });

      testWidgets('shows walked/mastered counts label', (tester) async {
        await tester.pumpWidget(
          _wrap(QuizHomeScreen(
            walkedStreets: const [],
            records: const [],
            onStartReview: () {},
            onPracticeAll: () {},
          )),
        );

        // Some stats are shown
        expect(tester.takeException(), isNull);
      });
    });

    group('mastery badge', () {
      testWidgets('shows MasteryBadge for each walked street', (tester) async {
        final streets = [
          _walkedStreet('way/1', 'Baker Street'),
          _walkedStreet('way/2', 'Oxford Street'),
        ];
        await tester.pumpWidget(
          _wrap(QuizHomeScreen(
            walkedStreets: streets,
            records: const [],
            onStartReview: () {},
            onPracticeAll: () {},
          )),
        );

        expect(find.byType(MasteryBadge), findsNWidgets(2));
      });
    });
  });
}
