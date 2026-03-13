import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/features/map/presentation/widgets/discovery_burst_overlay.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: Stack(children: [child])));

void main() {
  group('DiscoveryBurstOverlay — rendering', () {
    testWidgets('renders without error for a known category', (tester) async {
      await tester.pumpWidget(
        _wrap(
          DiscoveryBurstOverlay(
            position: const Offset(100, 200),
            category: 'cafe',
            onComplete: () {},
          ),
        ),
      );
      expect(find.byType(DiscoveryBurstOverlay), findsOneWidget);
    });

    testWidgets('renders without error for an unknown category', (tester) async {
      await tester.pumpWidget(
        _wrap(
          DiscoveryBurstOverlay(
            position: const Offset(50, 50),
            category: 'unknown_category_xyz',
            onComplete: () {},
          ),
        ),
      );
      expect(find.byType(DiscoveryBurstOverlay), findsOneWidget);
    });

    testWidgets('renders without error for empty category string', (tester) async {
      await tester.pumpWidget(
        _wrap(
          DiscoveryBurstOverlay(
            position: const Offset(0, 0),
            category: '',
            onComplete: () {},
          ),
        ),
      );
      expect(find.byType(DiscoveryBurstOverlay), findsOneWidget);
    });

    testWidgets('displays correct category icon for cafe', (tester) async {
      await tester.pumpWidget(
        _wrap(
          DiscoveryBurstOverlay(
            position: const Offset(100, 200),
            category: 'cafe',
            onComplete: () {},
          ),
        ),
      );
      // Pump a frame so the widget tree is built with animation at t=0
      await tester.pump();
      expect(find.byIcon(Icons.coffee), findsOneWidget);
    });

    testWidgets('displays correct icon for park category', (tester) async {
      await tester.pumpWidget(
        _wrap(
          DiscoveryBurstOverlay(
            position: const Offset(100, 200),
            category: 'park',
            onComplete: () {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.park), findsOneWidget);
    });

    testWidgets('displays default icon (Icons.place) for unknown category', (tester) async {
      await tester.pumpWidget(
        _wrap(
          DiscoveryBurstOverlay(
            position: const Offset(100, 200),
            category: 'not_a_real_category',
            onComplete: () {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.place), findsOneWidget);
    });

    testWidgets('uses Positioned to place overlay at the given screen position',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          DiscoveryBurstOverlay(
            position: const Offset(150, 250),
            category: 'pub',
            onComplete: () {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(Positioned), findsAtLeastNWidgets(1));
    });
  });

  group('DiscoveryBurstOverlay — animation', () {
    testWidgets('contains AnimatedBuilder for animation', (tester) async {
      await tester.pumpWidget(
        _wrap(
          DiscoveryBurstOverlay(
            position: const Offset(100, 200),
            category: 'cafe',
            onComplete: () {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AnimatedBuilder), findsAtLeastNWidgets(1));
    });

    testWidgets('fires onComplete callback after animation settles', (tester) async {
      var completed = false;
      await tester.pumpWidget(
        _wrap(
          DiscoveryBurstOverlay(
            position: const Offset(100, 200),
            category: 'cafe',
            onComplete: () => completed = true,
          ),
        ),
      );
      // pumpAndSettle drives all animations to completion
      await tester.pumpAndSettle();
      expect(completed, isTrue);
    });

    testWidgets('fires onComplete for unknown category', (tester) async {
      var completed = false;
      await tester.pumpWidget(
        _wrap(
          DiscoveryBurstOverlay(
            position: const Offset(20, 20),
            category: 'unknown_xyz',
            onComplete: () => completed = true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(completed, isTrue);
    });

    testWidgets('fires onComplete only once', (tester) async {
      var callCount = 0;
      await tester.pumpWidget(
        _wrap(
          DiscoveryBurstOverlay(
            position: const Offset(100, 200),
            category: 'viewpoint',
            onComplete: () => callCount++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Additional pumps should not trigger extra calls
      await tester.pump(const Duration(milliseconds: 100));
      expect(callCount, equals(1));
    });
  });

  group('DiscoveryBurstOverlay — lifecycle', () {
    testWidgets('disposes without error', (tester) async {
      await tester.pumpWidget(
        _wrap(
          DiscoveryBurstOverlay(
            position: const Offset(100, 200),
            category: 'cafe',
            onComplete: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      // Replace with an empty widget to trigger dispose
      await tester.pumpWidget(_wrap(const SizedBox()));
      expect(find.byType(DiscoveryBurstOverlay), findsNothing);
    });

    testWidgets('disposes mid-animation without error', (tester) async {
      await tester.pumpWidget(
        _wrap(
          DiscoveryBurstOverlay(
            position: const Offset(100, 200),
            category: 'historic',
            onComplete: () {},
          ),
        ),
      );
      // Pump only partway through animation
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpWidget(_wrap(const SizedBox()));
      expect(find.byType(DiscoveryBurstOverlay), findsNothing);
    });

    testWidgets('works at position (0, 0) — edge boundary', (tester) async {
      var completed = false;
      await tester.pumpWidget(
        _wrap(
          DiscoveryBurstOverlay(
            position: Offset.zero,
            category: 'cafe',
            onComplete: () => completed = true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The widget calls onComplete; caller is responsible for removal.
      expect(completed, isTrue);
      expect(find.byType(DiscoveryBurstOverlay), findsOneWidget);
    });

    testWidgets('works at large offset position', (tester) async {
      var completed = false;
      await tester.pumpWidget(
        _wrap(
          DiscoveryBurstOverlay(
            position: const Offset(9999, 9999),
            category: 'park',
            onComplete: () => completed = true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      // onComplete fires; caller drives removal.
      expect(completed, isTrue);
      expect(find.byType(DiscoveryBurstOverlay), findsOneWidget);
    });
  });
}
