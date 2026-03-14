import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/features/map/presentation/widgets/post_first_walk_overlay.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('PostFirstWalkOverlay', () {
    testWidgets('renders share prompt text', (tester) async {
      await tester.pumpWidget(wrap(
        PostFirstWalkOverlay(
          onShare: () {},
          onDismiss: () {},
        ),
      ));

      expect(
        find.textContaining('Share your first exploration'),
        findsOneWidget,
      );
    });

    testWidgets('has a share button', (tester) async {
      await tester.pumpWidget(wrap(
        PostFirstWalkOverlay(
          onShare: () {},
          onDismiss: () {},
        ),
      ));

      expect(find.textContaining('Share'), findsWidgets);
    });

    testWidgets('share button calls onShare', (tester) async {
      var shared = false;
      await tester.pumpWidget(wrap(
        PostFirstWalkOverlay(
          onShare: () => shared = true,
          onDismiss: () {},
        ),
      ));

      await tester.tap(find.widgetWithText(GestureDetector, 'Share'));
      await tester.pump();

      expect(shared, isTrue);
    });

    testWidgets('dismiss button calls onDismiss', (tester) async {
      var dismissed = false;
      await tester.pumpWidget(wrap(
        PostFirstWalkOverlay(
          onShare: () {},
          onDismiss: () => dismissed = true,
        ),
      ));

      await tester.tap(find.textContaining('Not now'));
      await tester.pump();

      expect(dismissed, isTrue);
    });

    testWidgets('has semi-transparent background', (tester) async {
      await tester.pumpWidget(wrap(
        PostFirstWalkOverlay(
          onShare: () {},
          onDismiss: () {},
        ),
      ));

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
