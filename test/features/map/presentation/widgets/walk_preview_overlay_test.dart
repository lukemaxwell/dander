import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

      expect(completed, isTrue);
    });

    testWidgets('shows tagline text', (tester) async {
      await tester.pumpWidget(wrap(
        WalkPreviewOverlay(
          isFirstLaunch: true,
          onComplete: () {},
        ),
      ));

      await tester.pump(const Duration(seconds: 3));

      expect(
        find.textContaining('Every walk reveals'),
        findsOneWidget,
      );
    });

    testWidgets('does not auto-dismiss — requires tap', (tester) async {
      var completed = false;
      await tester.pumpWidget(wrap(
        WalkPreviewOverlay(
          isFirstLaunch: true,
          onComplete: () => completed = true,
        ),
      ));

      // Wait well past the animation duration
      await tester.pump(const Duration(seconds: 10));

      // Should still be showing — not auto-dismissed
      expect(completed, isFalse);
      expect(find.textContaining('Every walk reveals'), findsOneWidget);
    });

    testWidgets('shows tap to continue after animation completes',
        (tester) async {
      await tester.pumpWidget(wrap(
        WalkPreviewOverlay(
          isFirstLaunch: true,
          onComplete: () {},
        ),
      ));

      // Before animation completes — prompt not yet visible
      await tester.pump(const Duration(seconds: 1));

      // After animation completes
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('tap_to_continue')), findsOneWidget);
    });

    testWidgets('tap dismisses overlay and calls onComplete', (tester) async {
      var completed = false;
      await tester.pumpWidget(wrap(
        WalkPreviewOverlay(
          isFirstLaunch: true,
          onComplete: () => completed = true,
        ),
      ));

      // Let animation finish
      await tester.pump(const Duration(seconds: 6));

      // Tap to dismiss
      await tester.tap(find.byType(WalkPreviewOverlay));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
    });

    testWidgets('reduced motion shows static card with tap to dismiss',
        (tester) async {
      var completed = false;
      await tester.pumpWidget(wrap(
        WalkPreviewOverlay(
          isFirstLaunch: true,
          onComplete: () => completed = true,
        ),
        reducedMotion: true,
      ));

      await tester.pump();

      expect(find.textContaining('Every walk reveals'), findsOneWidget);
      expect(find.byKey(const Key('tap_to_continue')), findsOneWidget);

      // Should not auto-dismiss
      await tester.pump(const Duration(seconds: 5));
      expect(completed, isFalse);

      // Tap to dismiss
      await tester.tap(find.byType(WalkPreviewOverlay));
      await tester.pumpAndSettle();
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
