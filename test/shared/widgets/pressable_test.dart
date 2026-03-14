import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/shared/widgets/pressable.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

Widget _wrapReduced(Widget child) => MaterialApp(
      home: Scaffold(
        body: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: child,
        ),
      ),
    );

void main() {
  group('Pressable — rendering', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(_wrap(
        Pressable(
          onTap: () {},
          child: const Text('press me'),
        ),
      ));
      expect(find.text('press me'), findsOneWidget);
    });

    testWidgets('renders without onTap callback', (tester) async {
      await tester.pumpWidget(_wrap(
        const Pressable(
          child: Text('no tap'),
        ),
      ));
      expect(find.text('no tap'), findsOneWidget);
    });
  });

  group('Pressable — tap behaviour', () {
    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(
        Pressable(
          onTap: () => tapped = true,
          child: const Text('tap'),
        ),
      ));
      await tester.tap(find.text('tap'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('does not call onTap when null', (tester) async {
      // Should not throw
      await tester.pumpWidget(_wrap(
        const Pressable(
          child: Text('no-op'),
        ),
      ));
      await tester.tap(find.text('no-op'));
      await tester.pump();
      // No assertion needed — just verifying no exception thrown.
      expect(find.text('no-op'), findsOneWidget);
    });
  });

  group('Pressable — press feedback', () {
    testWidgets('wraps child in Transform.scale and Opacity', (tester) async {
      await tester.pumpWidget(_wrap(
        Pressable(
          onTap: () {},
          child: const SizedBox(width: 80, height: 40),
        ),
      ));
      // Transform + Opacity should be present (animation scaffold)
      expect(find.byType(Transform), findsAtLeastNWidgets(1));
    });

    testWidgets('has Transform and Opacity inside for press feedback',
        (tester) async {
      await tester.pumpWidget(_wrap(
        Pressable(
          onTap: () {},
          child: const SizedBox(width: 100, height: 50),
        ),
      ));
      // The Pressable subtree should include a Transform (scale feedback)
      final transformInPressable = find.descendant(
        of: find.byType(Pressable),
        matching: find.byType(Transform),
      );
      expect(transformInPressable, findsAtLeastNWidgets(1));

      // And Opacity (opacity feedback)
      final opacityInPressable = find.descendant(
        of: find.byType(Pressable),
        matching: find.byType(Opacity),
      );
      expect(opacityInPressable, findsAtLeastNWidgets(1));
    });
  });

  group('Pressable — reduced motion', () {
    testWidgets('still calls onTap when reduced motion is on', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrapReduced(
        Pressable(
          onTap: () => tapped = true,
          child: const Text('reduced'),
        ),
      ));
      await tester.tap(find.text('reduced'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('no AnimatedBuilder inside Pressable when reduced motion', (tester) async {
      await tester.pumpWidget(_wrapReduced(
        Pressable(
          onTap: () {},
          child: const SizedBox(),
        ),
      ));
      // In reduced mode Pressable uses a plain GestureDetector — no AnimatedBuilder inside it
      final inPressable = find.descendant(
        of: find.byType(Pressable),
        matching: find.byType(AnimatedBuilder),
      );
      expect(inPressable, findsNothing);
    });
  });

  group('Pressable — enabled state', () {
    testWidgets('disabled Pressable does not call onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(
        Pressable(
          onTap: () => tapped = true,
          enabled: false,
          child: const Text('disabled'),
        ),
      ));
      await tester.tap(find.text('disabled'));
      await tester.pump();
      expect(tapped, isFalse);
    });
  });
}
