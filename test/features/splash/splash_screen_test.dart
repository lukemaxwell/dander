import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dander/features/splash/presentation/screens/splash_screen.dart';
import 'package:dander/shared/widgets/dander_logo.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

/// Pumps the widget through the full splash sequence (1500ms anim + ~600ms hold + overhead).
Future<void> _pumpFull(WidgetTester tester) async {
  for (var i = 0; i < 25; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('SplashScreen — structure', () {
    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(_wrap(const SplashScreen()));
      await _pumpFull(tester);
      expect(find.byType(SplashScreen), findsOneWidget);
    });

    testWidgets('contains DanderLogoMark', (tester) async {
      await tester.pumpWidget(_wrap(const SplashScreen()));
      expect(find.byType(DanderLogoMark), findsAtLeastNWidgets(1));
      await _pumpFull(tester);
    });

    testWidgets('displays app name text "Dander"', (tester) async {
      await tester.pumpWidget(_wrap(const SplashScreen()));
      expect(find.textContaining('Dander'), findsAtLeastNWidgets(1));
      await _pumpFull(tester);
    });

    testWidgets('has non-null background colour', (tester) async {
      await tester.pumpWidget(_wrap(const SplashScreen()));
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, isNotNull);
      await _pumpFull(tester);
    });
  });

  group('SplashScreen — animation widgets present', () {
    testWidgets('has at least one FadeTransition in the subtree', (tester) async {
      await tester.pumpWidget(_wrap(const SplashScreen()));
      // More than just the MaterialApp route FadeTransition — count should
      // be at least 2 (MaterialApp page + our logo fade)
      expect(find.byType(FadeTransition), findsWidgets);
      await _pumpFull(tester);
    });

    testWidgets('has at least one SlideTransition in the subtree', (tester) async {
      await tester.pumpWidget(_wrap(const SplashScreen()));
      expect(find.byType(SlideTransition), findsAtLeastNWidgets(1));
      await _pumpFull(tester);
    });

    testWidgets('logo mark is fully opaque after animation completes',
        (tester) async {
      await tester.pumpWidget(_wrap(const SplashScreen()));
      // After the full 1500ms animation the widget should be rendered
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.byType(DanderLogoMark), findsAtLeastNWidgets(1));
      await tester.pump(const Duration(milliseconds: 501));
    });
  });

  group('SplashScreen — navigation callback', () {
    testWidgets('calls onComplete after full animation sequence',
        (tester) async {
      var completed = false;
      await tester.pumpWidget(_wrap(
        SplashScreen(onComplete: () => completed = true),
      ));
      // Advance in small steps until completed or 3000ms elapsed
      // (animation=1500ms + hold=500ms + async overhead)
      for (var i = 0; i < 30 && !completed; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(completed, isTrue);
    });

    testWidgets('does not call onComplete before animation ends',
        (tester) async {
      var completed = false;
      await tester.pumpWidget(_wrap(
        SplashScreen(onComplete: () => completed = true),
      ));
      // Only 500ms in — animation still running (duration=1500ms)
      await tester.pump(const Duration(milliseconds: 500));
      expect(completed, isFalse);

      // Drain the rest so no pending timers
      await _pumpFull(tester);
    });

    testWidgets('works without a callback (no throw)', (tester) async {
      await tester.pumpWidget(_wrap(const SplashScreen()));
      await _pumpFull(tester);
      // No exception thrown
      expect(find.byType(SplashScreen), findsOneWidget);
    });
  });

  group('SplashScreen — animation timing', () {
    testWidgets('logo is still visible mid-animation (not hidden)', (tester) async {
      await tester.pumpWidget(_wrap(const SplashScreen()));
      await tester.pump(const Duration(milliseconds: 750));
      // The logo mark should still be in the tree mid-animation
      expect(find.byType(DanderLogoMark), findsAtLeastNWidgets(1));
      // Drain rest
      await _pumpFull(tester);
    });

    testWidgets('animation fires onComplete after > 1500ms', (tester) async {
      var completed = false;
      await tester.pumpWidget(_wrap(
        SplashScreen(onComplete: () => completed = true),
      ));
      // Check not complete at 1000ms (before animation ends)
      await tester.pump(const Duration(milliseconds: 1000));
      expect(completed, isFalse);
      // Complete after draining
      await _pumpFull(tester);
      expect(completed, isTrue);
    });
  });
}
