import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dander/shared/widgets/gradient_overlay.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('GradientOverlay — structure', () {
    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(_wrap(
        GradientOverlay(child: const SizedBox.expand()),
      ));
      expect(find.byType(GradientOverlay), findsOneWidget);
    });

    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(_wrap(
        GradientOverlay(child: const Text('map')),
      ));
      expect(find.text('map'), findsOneWidget);
    });

    testWidgets('uses a Stack to layer gradient over child', (tester) async {
      await tester.pumpWidget(_wrap(
        GradientOverlay(child: const SizedBox.expand()),
      ));
      expect(find.byType(Stack), findsAtLeastNWidgets(1));
    });

    testWidgets('gradient container uses BoxDecoration with LinearGradient',
        (tester) async {
      await tester.pumpWidget(_wrap(
        GradientOverlay(child: const SizedBox.expand()),
      ));
      // Find a Container whose decoration is a BoxDecoration with a gradient
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasGradient = containers.any((c) {
        final dec = c.decoration;
        return dec is BoxDecoration && dec.gradient != null;
      });
      expect(hasGradient, isTrue,
          reason: 'Expected a Container with a gradient decoration');
    });
  });

  group('GradientOverlay — customisation', () {
    testWidgets('accepts custom begin/end alignments', (tester) async {
      await tester.pumpWidget(_wrap(
        GradientOverlay(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          child: const SizedBox.expand(),
        ),
      ));
      expect(find.byType(GradientOverlay), findsOneWidget);
    });

    testWidgets('accepts custom colors list', (tester) async {
      await tester.pumpWidget(_wrap(
        GradientOverlay(
          colors: const [Colors.black, Colors.transparent],
          child: const SizedBox.expand(),
        ),
      ));
      expect(find.byType(GradientOverlay), findsOneWidget);
    });
  });
}
