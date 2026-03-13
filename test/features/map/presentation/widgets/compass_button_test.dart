import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/features/map/presentation/widgets/compass_button.dart';

void main() {
  group('CompassButton', () {
    testWidgets('renders compass icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompassButton(charges: 1, onPressed: null),
          ),
        ),
      );
      expect(find.byIcon(Icons.explore), findsOneWidget);
    });

    testWidgets('shows charge count "2" when charges = 2', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompassButton(charges: 2, onPressed: null),
          ),
        ),
      );
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('shows charge count "0" when charges = 0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompassButton(charges: 0, onPressed: null),
          ),
        ),
      );
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('renders without error with charges = 3', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompassButton(charges: 3, onPressed: () {}),
          ),
        ),
      );
      expect(find.byType(CompassButton), findsOneWidget);
    });

    testWidgets('tap fires onPressed when charges > 0', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompassButton(
              charges: 2,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CompassButton));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('does not fire onPressed when charges = 0', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompassButton(
              charges: 0,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CompassButton));
      await tester.pump();

      expect(tapped, isFalse);
    });

    testWidgets(
        'icon uses DanderColors.onSurfaceDisabled color when charges = 0',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompassButton(charges: 0, onPressed: null),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.explore));
      // Disabled state: color should be onSurfaceDisabled (low opacity).
      // The exact value is Color(0x3DE8EAF6) — alpha 0x3D ≈ 24%.
      expect(icon.color?.alpha, lessThan(100));
    });

    testWidgets(
        'icon uses DanderColors.accent color when charges > 0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompassButton(charges: 1, onPressed: () {}),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.explore));
      // Accent: Color(0xFF4FC3F7) — fully opaque blue.
      expect(icon.color?.alpha, equals(255));
    });
  });
}
