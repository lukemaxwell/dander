import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/features/subscription/presentation/widgets/benefit_row.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: Scaffold(body: child),
    );

void main() {
  group('BenefitRow', () {
    testWidgets('renders icon', (tester) async {
      await tester.pumpWidget(_wrap(
        const BenefitRow(
          icon: Icons.map_outlined,
          title: 'Unlimited zones',
          description: 'Map every neighbourhood',
        ),
      ));

      expect(find.byIcon(Icons.map_outlined), findsOneWidget);
    });

    testWidgets('renders title text', (tester) async {
      await tester.pumpWidget(_wrap(
        const BenefitRow(
          icon: Icons.map_outlined,
          title: 'Unlimited zones',
          description: 'Map every neighbourhood',
        ),
      ));

      expect(find.text('Unlimited zones'), findsOneWidget);
    });

    testWidgets('renders description text', (tester) async {
      await tester.pumpWidget(_wrap(
        const BenefitRow(
          icon: Icons.map_outlined,
          title: 'Unlimited zones',
          description: 'Map every neighbourhood',
        ),
      ));

      expect(find.text('Map every neighbourhood'), findsOneWidget);
    });

    testWidgets('has semantics label combining title and description',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const BenefitRow(
          icon: Icons.map_outlined,
          title: 'Unlimited zones',
          description: 'Map every neighbourhood',
        ),
      ));

      final semantics = tester.getSemantics(find.byType(BenefitRow));
      expect(semantics.label, contains('Unlimited zones'));
    });

    testWidgets('renders different icon and text combination', (tester) async {
      await tester.pumpWidget(_wrap(
        const BenefitRow(
          icon: Icons.quiz_outlined,
          title: 'Full quiz access',
          description: 'All question types, no cap',
        ),
      ));

      expect(find.byIcon(Icons.quiz_outlined), findsOneWidget);
      expect(find.text('Full quiz access'), findsOneWidget);
      expect(find.text('All question types, no cap'), findsOneWidget);
    });
  });
}
