import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/features/map/presentation/widgets/exploration_badge.dart';

void main() {
  group('ExplorationBadge', () {
    testWidgets('renders percentage label', (tester) async {
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

    testWidgets('renders a LinearProgressIndicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ExplorationBadge(percentageExplored: 42)),
        ),
      );
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('progress bar value matches percentage', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ExplorationBadge(percentageExplored: 50)),
        ),
      );
      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(indicator.value, closeTo(0.5, 0.001));
    });
  });
}
