import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/features/map/presentation/widgets/exploration_chip.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('ExplorationChip', () {
    testWidgets('renders percentage text', (tester) async {
      await tester.pumpWidget(wrap(
        const ExplorationChip(percentageExplored: 0.2),
      ));

      expect(find.textContaining('0.2%'), findsOneWidget);
    });

    testWidgets('renders "of your neighbourhood" label', (tester) async {
      await tester.pumpWidget(wrap(
        const ExplorationChip(percentageExplored: 0.2),
      ));

      expect(find.textContaining('neighbourhood'), findsOneWidget);
    });

    testWidgets('displays zero percentage correctly', (tester) async {
      await tester.pumpWidget(wrap(
        const ExplorationChip(percentageExplored: 0.0),
      ));

      expect(find.textContaining('0.0%'), findsOneWidget);
    });

    testWidgets('displays higher percentage correctly', (tester) async {
      await tester.pumpWidget(wrap(
        const ExplorationChip(percentageExplored: 15.3),
      ));

      expect(find.textContaining('15.3%'), findsOneWidget);
    });

    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(wrap(
        const ExplorationChip(percentageExplored: 0.5),
      ));

      expect(find.byType(ExplorationChip), findsOneWidget);
    });
  });
}
