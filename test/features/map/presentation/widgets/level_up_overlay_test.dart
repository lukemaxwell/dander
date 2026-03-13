import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/core/zone/level_up_detector.dart';
import 'package:dander/features/map/presentation/widgets/level_up_overlay.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('LevelUpOverlay — rendering', () {
    testWidgets('renders without throwing when event is null', (tester) async {
      await tester.pumpWidget(_wrap(
        const LevelUpOverlay(
          event: null,
          child: Text('map'),
        ),
      ));
      expect(find.byType(LevelUpOverlay), findsOneWidget);
    });

    testWidgets('renders child when event is null', (tester) async {
      await tester.pumpWidget(_wrap(
        const LevelUpOverlay(
          event: null,
          child: Text('map content'),
        ),
      ));
      expect(find.text('map content'), findsOneWidget);
    });

    testWidgets('shows level text when LevelUpEvent is provided', (tester) async {
      const event = LevelUpEvent(
        previousLevel: 1,
        newLevel: 2,
        newRadiusMeters: 1500.0,
      );
      await tester.pumpWidget(_wrap(
        const LevelUpOverlay(
          event: event,
          child: SizedBox(),
        ),
      ));
      // Should display the new level number
      expect(find.textContaining('2'), findsAtLeastNWidgets(1));
    });

    testWidgets('displays "Level" label when event is provided', (tester) async {
      const event = LevelUpEvent(
        previousLevel: 2,
        newLevel: 3,
        newRadiusMeters: 3000.0,
      );
      await tester.pumpWidget(_wrap(
        const LevelUpOverlay(
          event: event,
          child: SizedBox(),
        ),
      ));
      expect(find.textContaining('Level'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows radius info for L2 (1.5km)', (tester) async {
      const event = LevelUpEvent(
        previousLevel: 1,
        newLevel: 2,
        newRadiusMeters: 1500.0,
      );
      await tester.pumpWidget(_wrap(
        const LevelUpOverlay(
          event: event,
          child: SizedBox(),
        ),
      ));
      // Radius info text should be visible (e.g. "1.5km" or "1500m")
      expect(
        find.textContaining(RegExp(r'1\.5|1500')),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('shows radius info for L3 (3km)', (tester) async {
      const event = LevelUpEvent(
        previousLevel: 2,
        newLevel: 3,
        newRadiusMeters: 3000.0,
      );
      await tester.pumpWidget(_wrap(
        const LevelUpOverlay(
          event: event,
          child: SizedBox(),
        ),
      ));
      expect(
        find.textContaining(RegExp(r'3\.0|3000|3km|3 km')),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('shows radius info for L5 (100km)', (tester) async {
      const event = LevelUpEvent(
        previousLevel: 4,
        newLevel: 5,
        newRadiusMeters: 100000.0,
      );
      await tester.pumpWidget(_wrap(
        const LevelUpOverlay(
          event: event,
          child: SizedBox(),
        ),
      ));
      expect(
        find.textContaining(RegExp(r'100|unlimited', caseSensitive: false)),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('does not show overlay text when event is null', (tester) async {
      await tester.pumpWidget(_wrap(
        const LevelUpOverlay(
          event: null,
          child: Text('base'),
        ),
      ));
      // No level-up text should appear
      expect(find.textContaining('Level'), findsNothing);
    });

    testWidgets('renders child beneath overlay', (tester) async {
      const event = LevelUpEvent(
        previousLevel: 1,
        newLevel: 2,
        newRadiusMeters: 1500.0,
      );
      await tester.pumpWidget(_wrap(
        const LevelUpOverlay(
          event: event,
          child: Text('underlying map'),
        ),
      ));
      expect(find.text('underlying map'), findsOneWidget);
    });
  });

  group('LevelUpOverlay — widget structure', () {
    testWidgets('uses Stack to layer overlay on child', (tester) async {
      const event = LevelUpEvent(
        previousLevel: 1,
        newLevel: 2,
        newRadiusMeters: 1500.0,
      );
      await tester.pumpWidget(_wrap(
        const LevelUpOverlay(
          event: event,
          child: SizedBox.expand(),
        ),
      ));
      expect(find.byType(Stack), findsAtLeastNWidgets(1));
    });

    testWidgets('contains AnimatedBuilder or FadeTransition for animation',
        (tester) async {
      const event = LevelUpEvent(
        previousLevel: 3,
        newLevel: 4,
        newRadiusMeters: 8000.0,
      );
      await tester.pumpWidget(_wrap(
        const LevelUpOverlay(
          event: event,
          child: SizedBox(),
        ),
      ));
      final hasAnimated = tester.widgetList(find.byType(AnimatedBuilder)).isNotEmpty ||
          tester.widgetList(find.byType(FadeTransition)).isNotEmpty;
      expect(hasAnimated, isTrue);
    });
  });

  group('LevelUpOverlay — lifecycle', () {
    testWidgets('disposes without error after event shown', (tester) async {
      const event = LevelUpEvent(
        previousLevel: 1,
        newLevel: 2,
        newRadiusMeters: 1500.0,
      );
      await tester.pumpWidget(_wrap(
        const LevelUpOverlay(
          event: event,
          child: SizedBox(),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      // Replace widget — triggers dispose()
      await tester.pumpWidget(_wrap(const SizedBox()));
      expect(find.byType(LevelUpOverlay), findsNothing);
    });

    testWidgets('handles event changing from null to provided', (tester) async {
      await tester.pumpWidget(_wrap(
        const LevelUpOverlay(
          event: null,
          child: SizedBox(),
        ),
      ));
      expect(find.textContaining('Level'), findsNothing);

      const event = LevelUpEvent(
        previousLevel: 2,
        newLevel: 3,
        newRadiusMeters: 3000.0,
      );
      await tester.pumpWidget(_wrap(
        const LevelUpOverlay(
          event: event,
          child: SizedBox(),
        ),
      ));
      expect(find.textContaining('Level'), findsAtLeastNWidgets(1));
    });

    testWidgets('handles event changing from provided to null', (tester) async {
      const event = LevelUpEvent(
        previousLevel: 1,
        newLevel: 2,
        newRadiusMeters: 1500.0,
      );
      await tester.pumpWidget(_wrap(
        const LevelUpOverlay(
          event: event,
          child: SizedBox(),
        ),
      ));
      expect(find.textContaining('Level'), findsAtLeastNWidgets(1));

      await tester.pumpWidget(_wrap(
        const LevelUpOverlay(
          event: null,
          child: SizedBox(),
        ),
      ));
      expect(find.textContaining('Level'), findsNothing);
    });
  });

  group('LevelUpOverlay — radius formatting', () {
    testWidgets('formats 500m radius correctly', (tester) async {
      const event = LevelUpEvent(
        previousLevel: 0,
        newLevel: 1,
        newRadiusMeters: 500.0,
      );
      await tester.pumpWidget(_wrap(
        const LevelUpOverlay(
          event: event,
          child: SizedBox(),
        ),
      ));
      expect(
        find.textContaining(RegExp(r'500m|0\.5km|0\.5 km')),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('formats 8000m radius correctly', (tester) async {
      const event = LevelUpEvent(
        previousLevel: 3,
        newLevel: 4,
        newRadiusMeters: 8000.0,
      );
      await tester.pumpWidget(_wrap(
        const LevelUpOverlay(
          event: event,
          child: SizedBox(),
        ),
      ));
      expect(
        find.textContaining(RegExp(r'8\.0|8000|8km|8 km')),
        findsAtLeastNWidgets(1),
      );
    });
  });
}
