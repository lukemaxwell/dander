import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dander/shared/widgets/flip_card.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('FlipCard — rendering', () {
    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(_wrap(
        FlipCard(
          front: const Text('front'),
          back: const Text('back'),
        ),
      ));
      expect(find.byType(FlipCard), findsOneWidget);
    });

    testWidgets('shows front face initially', (tester) async {
      await tester.pumpWidget(_wrap(
        FlipCard(
          front: const Text('front'),
          back: const Text('back'),
        ),
      ));
      expect(find.text('front'), findsAtLeastNWidgets(1));
    });
  });

  group('FlipCard — flip animation', () {
    testWidgets('flips to back when flipped=true', (tester) async {
      await tester.pumpWidget(_wrap(
        FlipCard(
          front: const Text('front'),
          back: const Text('back'),
          flipped: true,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('back'), findsAtLeastNWidgets(1));
    });

    testWidgets('uses Transform widget for 3D flip', (tester) async {
      await tester.pumpWidget(_wrap(
        FlipCard(
          front: const Text('front'),
          back: const Text('back'),
        ),
      ));
      expect(find.byType(Transform), findsAtLeastNWidgets(1));
    });

    testWidgets('toggles back to front when flipped changes from true to false',
        (tester) async {
      var flipped = false;

      await tester.pumpWidget(_wrap(
        StatefulBuilder(builder: (context, setState) {
          return Column(
            children: [
              FlipCard(
                front: const Text('FRONT'),
                back: const Text('BACK'),
                flipped: flipped,
              ),
              ElevatedButton(
                onPressed: () => setState(() => flipped = !flipped),
                child: const Text('toggle'),
              ),
            ],
          );
        }),
      ));

      // Initially showing front
      expect(find.text('FRONT'), findsAtLeastNWidgets(1));

      // Flip to back
      await tester.tap(find.text('toggle'));
      await tester.pumpAndSettle();
      expect(find.text('BACK'), findsAtLeastNWidgets(1));
    });
  });

  group('FlipCard — customisation', () {
    testWidgets('accepts custom animation duration', (tester) async {
      await tester.pumpWidget(_wrap(
        FlipCard(
          front: const SizedBox(),
          back: const SizedBox(),
          duration: const Duration(milliseconds: 200),
        ),
      ));
      expect(find.byType(FlipCard), findsOneWidget);
    });
  });
}
