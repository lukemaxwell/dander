import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/features/map/presentation/widgets/exploration_badge.dart';

void main() {
  group('ExplorationBadge', () {
    testWidgets('renders with percentage', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ExplorationBadge(percentageExplored: 23)),
        ),
      );
      expect(find.text('23% explored'), findsOneWidget);
    });

    testWidgets('renders 0% correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ExplorationBadge(percentageExplored: 0)),
        ),
      );
      expect(find.text('0% explored'), findsOneWidget);
    });

    testWidgets('renders 100% correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ExplorationBadge(percentageExplored: 100)),
        ),
      );
      expect(find.text('100% explored'), findsOneWidget);
    });

    testWidgets('is wrapped in a Container or Card', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ExplorationBadge(percentageExplored: 42)),
        ),
      );
      // Should be styled with some container
      expect(
        find.byWidgetPredicate((w) => w is Container || w is Card),
        findsWidgets,
      );
    });
  });
}
