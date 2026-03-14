import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/features/quiz/presentation/widgets/quiz_streak_badge.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('QuizStreakBadge', () {
    testWidgets('shows nothing when streak is 0', (tester) async {
      await tester.pumpWidget(_wrap(const QuizStreakBadge(streak: 0)));
      expect(find.byType(QuizStreakBadge), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department), findsNothing);
    });

    testWidgets('shows fire icon and count when streak > 0', (tester) async {
      await tester.pumpWidget(_wrap(const QuizStreakBadge(streak: 2)));
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('does not show Bonus when streak <= 3', (tester) async {
      await tester.pumpWidget(_wrap(const QuizStreakBadge(streak: 3)));
      expect(find.text('Bonus!'), findsNothing);
    });

    testWidgets('shows Bonus when streak > 3', (tester) async {
      await tester.pumpWidget(_wrap(const QuizStreakBadge(streak: 4)));
      expect(find.text('Bonus!'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });
  });
}
