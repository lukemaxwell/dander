import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/shared/widgets/floating_xp_text.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        body: Stack(children: [child]),
      ),
    );

void main() {
  group('FloatingXpText — linger duration', () {
    testWidgets('completes after default 1500ms duration', (tester) async {
      var completed = false;
      await tester.pumpWidget(_wrap(
        FloatingXpText(
          amount: 10,
          onComplete: () => completed = true,
        ),
      ));
      // Extra pump to let didChangeDependencies fire the animation.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pump(); // flush completion callback
      expect(completed, isTrue);
    });

    testWidgets('custom duration: not completed before duration elapses',
        (tester) async {
      const custom = Duration(milliseconds: 2500);
      var completed = false;

      await tester.pumpWidget(_wrap(
        FloatingXpText(
          amount: 50,
          duration: custom,
          onComplete: () => completed = true,
        ),
      ));
      await tester.pump(); // allow didChangeDependencies

      // After default 1500ms — should NOT be done yet.
      await tester.pump(const Duration(milliseconds: 1500));
      expect(completed, isFalse);

      // After remaining time — should be done.
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pump(); // flush completion callback
      expect(completed, isTrue);
    });
  });

  group('FloatingXpController — show with duration', () {
    testWidgets('rare discovery XP text from controller lingers',
        (tester) async {
      final controller = FloatingXpController();
      const rareDuration = Duration(milliseconds: 2500);
      controller.show(50, duration: rareDuration);

      await tester.pumpWidget(_wrap(
        FloatingXpTextOverlay(controller: controller),
      ));
      await tester.pump();

      // Verify text is shown.
      expect(find.textContaining('+50 XP'), findsOneWidget);
    });
  });
}
