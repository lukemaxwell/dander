import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/shared/widgets/floating_xp_text.dart';

Widget _buildReduced({
  int amount = 10,
  VoidCallback? onComplete,
}) {
  return MaterialApp(
    home: Scaffold(
      body: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Stack(
          children: [
            FloatingXpText(
              amount: amount,
              onComplete: onComplete ?? () {},
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  group('FloatingXpText', () {
    Widget buildSubject({
      int amount = 10,
      VoidCallback? onComplete,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              FloatingXpText(
                amount: amount,
                onComplete: onComplete ?? () {},
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('displays the XP amount with + prefix', (tester) async {
      await tester.pumpWidget(buildSubject(amount: 10));
      expect(find.text('+10 XP'), findsOneWidget);
    });

    testWidgets('displays larger amounts correctly', (tester) async {
      await tester.pumpWidget(buildSubject(amount: 50));
      expect(find.text('+50 XP'), findsOneWidget);
    });

    testWidgets('starts animation on build', (tester) async {
      await tester.pumpWidget(buildSubject());
      // Widget should be visible at start
      expect(find.byType(FloatingXpText), findsOneWidget);

      // Advance partially — still visible
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('+10 XP'), findsOneWidget);
    });

    testWidgets('calls onComplete after animation finishes', (tester) async {
      var completed = false;
      await tester.pumpWidget(
        buildSubject(onComplete: () => completed = true),
      );

      expect(completed, isFalse);

      // Advance past total duration (1500ms)
      await tester.pump(const Duration(milliseconds: 1600));
      expect(completed, isTrue);
    });

    testWidgets('text has correct styling', (tester) async {
      await tester.pumpWidget(buildSubject(amount: 7));
      final textWidget = tester.widget<Text>(find.text('+7 XP'));
      final style = textWidget.style!;
      expect(style.fontWeight, FontWeight.bold);
      expect(style.fontSize, greaterThanOrEqualTo(16));
    });
  });

  group('FloatingXpText — reduced motion', () {
    testWidgets('calls onComplete without waiting for animation',
        (tester) async {
      var completed = false;
      await tester.pumpWidget(_buildReduced(onComplete: () => completed = true));
      // A single frame pump — should fire onComplete almost immediately
      await tester.pump();
      await tester.pump();
      expect(completed, isTrue,
          reason: 'onComplete should be called immediately with reduced motion');
    });
  });

  group('FloatingXpTextOverlay', () {
    testWidgets('manages multiple floating texts via controller', (
      tester,
    ) async {
      final controller = FloatingXpController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                FloatingXpTextOverlay(controller: controller),
              ],
            ),
          ),
        ),
      );

      // No XP texts initially
      expect(find.byType(FloatingXpText), findsNothing);

      // Add an XP event
      controller.show(10);
      await tester.pump();
      expect(find.text('+10 XP'), findsOneWidget);

      // Add another while first is still animating
      controller.show(50);
      await tester.pump();
      expect(find.text('+10 XP'), findsOneWidget);
      expect(find.text('+50 XP'), findsOneWidget);
    });

    testWidgets('removes text after animation completes', (tester) async {
      final controller = FloatingXpController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                FloatingXpTextOverlay(controller: controller),
              ],
            ),
          ),
        ),
      );

      controller.show(10);
      await tester.pump();
      expect(find.text('+10 XP'), findsOneWidget);

      // Wait for animation to complete
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pump(); // Rebuild after removal
      expect(find.text('+10 XP'), findsNothing);
    });
  });
}
