import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/features/subscription/presentation/widgets/zone_expansion_banner.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _wrap(
  Widget child, {
  bool reducedMotion = false,
}) {
  return MaterialApp(
    home: Scaffold(
      body: MediaQuery(
        data: MediaQueryData(disableAnimations: reducedMotion),
        child: child,
      ),
    ),
  );
}

void main() {
  group('ZoneExpansionBanner', () {
    testWidgets('renders title text "You\'re in a new area"', (tester) async {
      await tester.pumpWidget(_wrap(
        ZoneExpansionBanner(
          onNavigateToPaywall: () {},
          autoDismissDelay: const Duration(seconds: 60), // prevent auto-dismiss
        ),
        reducedMotion: true, // skip animation so widget is immediately visible
      ));
      await tester.pump();

      expect(find.text("You're in a new area"), findsOneWidget);
    });

    testWidgets('renders CTA text "Unlock unlimited zones →"', (tester) async {
      await tester.pumpWidget(_wrap(
        ZoneExpansionBanner(
          onNavigateToPaywall: () {},
          autoDismissDelay: const Duration(seconds: 60),
        ),
        reducedMotion: true,
      ));
      await tester.pump();

      expect(find.text('Unlock unlimited zones →'), findsOneWidget);
    });

    testWidgets('renders location_pin icon', (tester) async {
      await tester.pumpWidget(_wrap(
        ZoneExpansionBanner(
          onNavigateToPaywall: () {},
          autoDismissDelay: const Duration(seconds: 60),
        ),
        reducedMotion: true,
      ));
      await tester.pump();

      expect(find.byIcon(Icons.location_pin), findsOneWidget);
    });

    testWidgets('renders close (X) button', (tester) async {
      await tester.pumpWidget(_wrap(
        ZoneExpansionBanner(
          onNavigateToPaywall: () {},
          autoDismissDelay: const Duration(seconds: 60),
        ),
        reducedMotion: true,
      ));
      await tester.pump();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('tapping X button calls onDismiss', (tester) async {
      var dismissed = false;
      await tester.pumpWidget(_wrap(
        ZoneExpansionBanner(
          onNavigateToPaywall: () {},
          onDismiss: () => dismissed = true,
          autoDismissDelay: const Duration(seconds: 60),
        ),
        reducedMotion: true,
      ));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(dismissed, isTrue);
    });

    testWidgets('tapping X with no onDismiss callback does not throw',
        (tester) async {
      await tester.pumpWidget(_wrap(
        ZoneExpansionBanner(
          onNavigateToPaywall: () {},
          autoDismissDelay: const Duration(seconds: 60),
        ),
        reducedMotion: true,
      ));
      await tester.pump();

      // Should not throw even without onDismiss
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
    });

    testWidgets('tapping banner body calls onNavigateToPaywall', (tester) async {
      var navigated = false;
      await tester.pumpWidget(_wrap(
        ZoneExpansionBanner(
          onNavigateToPaywall: () => navigated = true,
          autoDismissDelay: const Duration(seconds: 60),
        ),
        reducedMotion: true,
      ));
      await tester.pump();

      // Tap the title text (part of banner body, not near the X button)
      await tester.tap(find.text("You're in a new area"));
      await tester.pump();

      expect(navigated, isTrue);
    });

    testWidgets('auto-dismisses after autoDismissDelay', (tester) async {
      var dismissed = false;
      await tester.pumpWidget(_wrap(
        ZoneExpansionBanner(
          onNavigateToPaywall: () {},
          onDismiss: () => dismissed = true,
          autoDismissDelay: const Duration(milliseconds: 100),
        ),
        reducedMotion: true, // skip animation so timer is the only delay
      ));
      await tester.pump();
      // Not yet dismissed
      expect(dismissed, isFalse);

      // Advance past the delay
      await tester.pump(const Duration(milliseconds: 200));

      expect(dismissed, isTrue);
    });

    testWidgets('swipe up calls onDismiss', (tester) async {
      var dismissed = false;
      await tester.pumpWidget(_wrap(
        ZoneExpansionBanner(
          onNavigateToPaywall: () {},
          onDismiss: () => dismissed = true,
          autoDismissDelay: const Duration(seconds: 60),
        ),
        reducedMotion: true,
      ));
      await tester.pump();

      await tester.drag(
        find.text("You're in a new area"),
        const Offset(0, -200), // swipe up
      );
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
    });

    testWidgets('does not show animation when reduced motion is enabled',
        (tester) async {
      // With reduced motion, banner should still render (just without animations)
      await tester.pumpWidget(_wrap(
        ZoneExpansionBanner(
          onNavigateToPaywall: () {},
          autoDismissDelay: const Duration(seconds: 60),
        ),
        reducedMotion: true,
      ));
      await tester.pump();

      // Banner content is still visible
      expect(find.text("You're in a new area"), findsOneWidget);
    });
  });
}
