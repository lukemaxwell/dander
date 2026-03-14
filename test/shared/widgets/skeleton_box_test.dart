import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/shared/widgets/skeleton_box.dart';

Widget _wrap(Widget child, {bool reduced = false}) => MaterialApp(
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: child,
        ),
      ),
    );

void main() {
  group('SkeletonBox', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(_wrap(
        const SkeletonBox(width: 100, height: 20),
      ));
      expect(find.byType(SkeletonBox), findsOneWidget);
    });

    testWidgets('renders at specified dimensions', (tester) async {
      await tester.pumpWidget(_wrap(
        const SkeletonBox(width: 200, height: 16),
      ));
      final box = tester.renderObject<RenderBox>(find.byType(SkeletonBox));
      expect(box.size.width, closeTo(200, 1));
      expect(box.size.height, closeTo(16, 1));
    });

    testWidgets('contains AnimatedBuilder in normal motion', (tester) async {
      await tester.pumpWidget(_wrap(
        const SkeletonBox(width: 100, height: 20),
      ));
      final inSkeleton = find.descendant(
        of: find.byType(SkeletonBox),
        matching: find.byType(AnimatedBuilder),
      );
      expect(inSkeleton, findsAtLeastNWidgets(1));
    });

    testWidgets('no AnimatedBuilder in reduced-motion mode', (tester) async {
      await tester.pumpWidget(_wrap(
        const SkeletonBox(width: 100, height: 20),
        reduced: true,
      ));
      final inSkeleton = find.descendant(
        of: find.byType(SkeletonBox),
        matching: find.byType(AnimatedBuilder),
      );
      expect(inSkeleton, findsNothing);
    });
  });

  group('SkeletonList', () {
    testWidgets('renders count number of skeleton boxes', (tester) async {
      await tester.pumpWidget(_wrap(
        const SkeletonList(count: 3, itemHeight: 80),
      ));
      // Each item is a SkeletonBox
      expect(find.byType(SkeletonBox), findsNWidgets(3));
    });
  });
}
