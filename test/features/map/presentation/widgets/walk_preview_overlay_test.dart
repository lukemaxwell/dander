import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/core/motion/dander_motion.dart';
import 'package:dander/features/map/presentation/widgets/walk_preview_overlay.dart';

void main() {
  Widget wrap(Widget child, {bool reducedMotion = false}) {
    return MediaQuery(
      data: MediaQueryData(disableAnimations: reducedMotion),
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('WalkPreviewOverlay', () {
    testWidgets('renders on first launch', (tester) async {
      await tester.pumpWidget(wrap(
        WalkPreviewOverlay(
          isFirstLaunch: true,
          onComplete: () {},
        ),
      ));

      expect(find.byType(WalkPreviewOverlay), findsOneWidget);
    });

    testWidgets('does not render when not first launch', (tester) async {
      var completed = false;
      await tester.pumpWidget(wrap(
        WalkPreviewOverlay(
          isFirstLaunch: false,
          onComplete: () => completed = true,
        ),
      ));

      // Should immediately call onComplete and render nothing visible
      expect(completed, isTrue);
    });

    testWidgets('shows tagline text', (tester) async {
      await tester.pumpWidget(wrap(
        WalkPreviewOverlay(
          isFirstLaunch: true,
          onComplete: () {},
        ),
      ));

      // Advance past any initial delay
      await tester.pump(const Duration(seconds: 3));

      expect(
        find.textContaining('Every walk reveals'),
        findsOneWidget,
      );
    });

    testWidgets('calls onComplete after animation finishes', (tester) async {
      var completed = false;
      await tester.pumpWidget(wrap(
        WalkPreviewOverlay(
          isFirstLaunch: true,
          onComplete: () => completed = true,
        ),
      ));

      // Animation is 5 seconds + 1s fade-out
      await tester.pumpAndSettle(const Duration(seconds: 7));

      expect(completed, isTrue);
    });

    testWidgets('reduced motion shows static card instead', (tester) async {
      var completed = false;
      await tester.pumpWidget(wrap(
        WalkPreviewOverlay(
          isFirstLaunch: true,
          onComplete: () => completed = true,
        ),
        reducedMotion: true,
      ));

      await tester.pump();

      // Should show the tagline without animation
      expect(
        find.textContaining('Every walk reveals'),
        findsOneWidget,
      );
    });

    testWidgets('reduced motion calls onComplete after brief delay',
        (tester) async {
      var completed = false;
      await tester.pumpWidget(wrap(
        WalkPreviewOverlay(
          isFirstLaunch: true,
          onComplete: () => completed = true,
        ),
        reducedMotion: true,
      ));

      // Static card shows for 3 seconds then completes
      await tester.pumpAndSettle(const Duration(seconds: 4));

      expect(completed, isTrue);
    });

    testWidgets('has semi-transparent background overlay', (tester) async {
      await tester.pumpWidget(wrap(
        WalkPreviewOverlay(
          isFirstLaunch: true,
          onComplete: () {},
        ),
      ));

      await tester.pump();

      // Should have a container with semi-transparent background
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasOverlay = containers.any((c) {
        final decoration = c.decoration;
        if (decoration is BoxDecoration && decoration.color != null) {
          return decoration.color!.a < 1.0 && decoration.color!.a > 0.0;
        }
        return false;
      });
      expect(hasOverlay, isTrue);
    });
  });
}
