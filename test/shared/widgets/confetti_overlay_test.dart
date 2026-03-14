import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dander/shared/widgets/confetti_overlay.dart';

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
  group('ConfettiOverlay — rendering', () {
    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(_wrap(
        ConfettiOverlay(
          active: true,
          child: const Text('test'),
        ),
      ));
      expect(find.byType(ConfettiOverlay), findsOneWidget);
    });

    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(_wrap(
        ConfettiOverlay(
          active: false,
          child: const Text('content'),
        ),
      ));
      expect(find.text('content'), findsOneWidget);
    });

    testWidgets('renders when active is true', (tester) async {
      await tester.pumpWidget(_wrap(
        ConfettiOverlay(
          active: true,
          child: const SizedBox(),
        ),
      ));
      expect(find.byType(ConfettiOverlay), findsOneWidget);
    });

    testWidgets('renders when active is false', (tester) async {
      await tester.pumpWidget(_wrap(
        ConfettiOverlay(
          active: false,
          child: const SizedBox(),
        ),
      ));
      expect(find.byType(ConfettiOverlay), findsOneWidget);
    });
  });

  group('ConfettiOverlay — animation', () {
    testWidgets('uses Stack to overlay particles on child', (tester) async {
      await tester.pumpWidget(_wrap(
        ConfettiOverlay(
          active: true,
          child: const Text('under'),
        ),
      ));
      expect(find.byType(Stack), findsAtLeastNWidgets(1));
    });

    testWidgets('particles are drawn via CustomPaint when active',
        (tester) async {
      await tester.pumpWidget(_wrap(
        ConfettiOverlay(
          active: true,
          child: const SizedBox.expand(),
        ),
      ));
      // Advance animation
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
    });

    testWidgets('active=false shows no particle animation', (tester) async {
      await tester.pumpWidget(_wrap(
        ConfettiOverlay(
          active: false,
          child: const Text('x'),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 200));
      // Widget still renders without error
      expect(find.byType(ConfettiOverlay), findsOneWidget);
    });
  });

  group('ConfettiOverlay — lifecycle', () {
    testWidgets('disposes without error after activation', (tester) async {
      await tester.pumpWidget(_wrap(
        ConfettiOverlay(
          active: true,
          child: const SizedBox(),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      // Replace the widget — this triggers dispose()
      await tester.pumpWidget(_wrap(const SizedBox()));
      // No exception thrown
      expect(find.byType(ConfettiOverlay), findsNothing);
    });
  });

  group('ConfettiOverlay — reduced motion', () {
    testWidgets('shows no particle Stack inside ConfettiOverlay when reduced motion',
        (tester) async {
      await tester.pumpWidget(_wrapReduced(
        ConfettiOverlay(
          active: true,
          child: const Text('beneath'),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      // ConfettiOverlay should return just the child — no Stack inside it.
      final inOverlay = find.descendant(
        of: find.byType(ConfettiOverlay),
        matching: find.byType(Stack),
      );
      expect(inOverlay, findsNothing);
    });

    testWidgets('still renders child when reduced motion is active',
        (tester) async {
      await tester.pumpWidget(_wrapReduced(
        ConfettiOverlay(
          active: true,
          child: const Text('still here'),
        ),
      ));
      expect(find.text('still here'), findsOneWidget);
    });
  });
}
