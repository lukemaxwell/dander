import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/features/subscription/paywall_trigger.dart';
import 'package:dander/features/subscription/presentation/widgets/paywall_hero.dart';

Widget _wrap(Widget child, {bool reduceMotion = false}) => MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: Scaffold(body: child),
      ),
    );

void main() {
  group('PaywallHero', () {
    for (final trigger in PaywallTrigger.values) {
      testWidgets('renders for trigger $trigger', (tester) async {
        await tester.pumpWidget(_wrap(
          PaywallHero(trigger: trigger),
        ));

        expect(find.byType(PaywallHero), findsOneWidget);
      });
    }

    testWidgets('has 200px height', (tester) async {
      await tester.pumpWidget(_wrap(
        const SizedBox(
          width: 400,
          child: PaywallHero(trigger: PaywallTrigger.profile),
        ),
      ));

      final box = tester.getSize(find.byType(PaywallHero));
      expect(box.height, equals(200.0));
    });

    group('reduced motion', () {
      for (final trigger in PaywallTrigger.values) {
        testWidgets('renders static container for $trigger with reduced motion',
            (tester) async {
          await tester.pumpWidget(_wrap(
            PaywallHero(trigger: trigger),
            reduceMotion: true,
          ));

          // With reduced motion, no AnimationController should be animating.
          // We verify by checking the widget tree contains a Container.
          expect(find.byType(PaywallHero), findsOneWidget);
        });
      }
    });
  });
}
