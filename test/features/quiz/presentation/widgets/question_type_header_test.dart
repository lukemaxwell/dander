import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/core/quiz/question_type.dart';
import 'package:dander/features/quiz/presentation/widgets/question_type_header.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('QuestionTypeHeader', () {
    for (final type in QuestionType.values) {
      testWidgets('renders without error for $type', (tester) async {
        await tester.pumpWidget(
          _wrap(QuestionTypeHeader(type: type)),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('shows an icon for $type', (tester) async {
        await tester.pumpWidget(
          _wrap(QuestionTypeHeader(type: type)),
        );
        expect(find.byType(Icon), findsOneWidget);
      });

      testWidgets('shows a label for $type', (tester) async {
        await tester.pumpWidget(
          _wrap(QuestionTypeHeader(type: type)),
        );
        // Should show some text label
        expect(find.byType(Text), findsOneWidget);
      });
    }

    testWidgets('direction type shows compass icon', (tester) async {
      await tester.pumpWidget(
        _wrap(const QuestionTypeHeader(type: QuestionType.direction)),
      );
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.explore_outlined);
    });

    testWidgets('category type shows category icon', (tester) async {
      await tester.pumpWidget(
        _wrap(const QuestionTypeHeader(type: QuestionType.category)),
      );
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.category_outlined);
    });

    testWidgets('proximity type shows near-me icon', (tester) async {
      await tester.pumpWidget(
        _wrap(const QuestionTypeHeader(type: QuestionType.proximity)),
      );
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.near_me_outlined);
    });

    testWidgets('route type shows route icon', (tester) async {
      await tester.pumpWidget(
        _wrap(const QuestionTypeHeader(type: QuestionType.route)),
      );
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.route_outlined);
    });

    testWidgets('streetName type shows map icon', (tester) async {
      await tester.pumpWidget(
        _wrap(const QuestionTypeHeader(type: QuestionType.streetName)),
      );
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.map_outlined);
    });
  });
}
