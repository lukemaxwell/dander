import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:dander/core/navigation/page_transitions.dart';

Widget _withMotion(Widget child, {bool reduced = false}) => MaterialApp(
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: child,
        ),
      ),
    );

// Minimal TickerProvider for tests.
class _TickerProvider implements TickerProvider {
  const _TickerProvider();
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

void main() {
  group('danderCrossfadePage', () {
    testWidgets('returns CustomTransitionPage in normal motion', (tester) async {
      late Page<void> page;
      await tester.pumpWidget(_withMotion(
        Builder(builder: (context) {
          page = danderCrossfadePage(context, const SizedBox());
          return const SizedBox();
        }),
      ));
      expect(page, isA<CustomTransitionPage<void>>());
    });

    testWidgets('returns NoTransitionPage when reduced motion', (tester) async {
      late Page<void> page;
      await tester.pumpWidget(_withMotion(
        Builder(builder: (context) {
          page = danderCrossfadePage(context, const SizedBox());
          return const SizedBox();
        }),
        reduced: true,
      ));
      expect(page, isA<NoTransitionPage<void>>());
    });

    testWidgets('uses 200ms transition duration in normal motion', (tester) async {
      late Page<void> page;
      await tester.pumpWidget(_withMotion(
        Builder(builder: (context) {
          page = danderCrossfadePage(context, const SizedBox());
          return const SizedBox();
        }),
      ));
      final custom = page as CustomTransitionPage<void>;
      expect(custom.transitionDuration.inMilliseconds, equals(200));
    });
  });

  group('danderSlideRightPage', () {
    testWidgets('returns CustomTransitionPage in normal motion', (tester) async {
      late Page<void> page;
      await tester.pumpWidget(_withMotion(
        Builder(builder: (context) {
          page = danderSlideRightPage(context, const SizedBox());
          return const SizedBox();
        }),
      ));
      expect(page, isA<CustomTransitionPage<void>>());
    });

    testWidgets('returns NoTransitionPage when reduced motion', (tester) async {
      late Page<void> page;
      await tester.pumpWidget(_withMotion(
        Builder(builder: (context) {
          page = danderSlideRightPage(context, const SizedBox());
          return const SizedBox();
        }),
        reduced: true,
      ));
      expect(page, isA<NoTransitionPage<void>>());
    });

    testWidgets('uses 250ms transition duration in normal motion', (tester) async {
      late Page<void> page;
      await tester.pumpWidget(_withMotion(
        Builder(builder: (context) {
          page = danderSlideRightPage(context, const SizedBox());
          return const SizedBox();
        }),
      ));
      final custom = page as CustomTransitionPage<void>;
      expect(custom.transitionDuration.inMilliseconds, equals(250));
    });
  });

  group('crossfadeTransitionBuilder', () {
    testWidgets('wraps child in FadeTransition', (tester) async {
      late Widget result;
      await tester.pumpWidget(_withMotion(
        Builder(builder: (context) {
          final anim = AnimationController(
            vsync: const _TickerProvider(),
            value: 0.5,
          );
          result = crossfadeTransitionBuilder(
            context,
            anim,
            anim,
            const Text('test'),
          );
          return result;
        }),
      ));
      expect(find.byType(FadeTransition), findsAtLeastNWidgets(1));
    });
  });

  group('slideRightTransitionBuilder', () {
    testWidgets('wraps child in SlideTransition', (tester) async {
      late Widget result;
      await tester.pumpWidget(_withMotion(
        Builder(builder: (context) {
          final anim = AnimationController(
            vsync: const _TickerProvider(),
            value: 0.5,
          );
          result = slideRightTransitionBuilder(
            context,
            anim,
            anim,
            const Text('slide'),
          );
          return result;
        }),
      ));
      expect(find.byType(SlideTransition), findsAtLeastNWidgets(1));
    });
  });
}
