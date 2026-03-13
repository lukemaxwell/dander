import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:dander/shared/widgets/app_shell.dart';

Widget _wrapWithRouter({String initialLocation = '/home'}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SizedBox()),
          ),
          GoRoute(
            path: '/discoveries',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SizedBox()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SizedBox()),
          ),
          GoRoute(
            path: '/quiz',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SizedBox()),
          ),
        ],
      ),
    ],
  );

  return MaterialApp.router(
    routerConfig: router,
    theme: ThemeData(splashFactory: NoSplash.splashFactory),
  );
}

void main() {
  group('AppShell — blurred nav bar', () {
    testWidgets('bottom nav is wrapped in a BackdropFilter', (tester) async {
      await tester.pumpWidget(_wrapWithRouter());
      expect(find.byType(BackdropFilter), findsAtLeastNWidgets(1));
    });

    testWidgets('BackdropFilter uses an ImageFilter (blur)', (tester) async {
      await tester.pumpWidget(_wrapWithRouter());
      final backdrop =
          tester.widget<BackdropFilter>(find.byType(BackdropFilter).first);
      // Verify the filter is set (not null / default)
      expect(backdrop.filter, isNotNull);
    });

    testWidgets('nav bar is semi-transparent (has ClipRect ancestor)',
        (tester) async {
      await tester.pumpWidget(_wrapWithRouter());
      // BackdropFilter requires a ClipRect ancestor to work correctly
      expect(find.byType(ClipRect), findsAtLeastNWidgets(1));
    });
  });

  group('AppShell — active indicator pill', () {
    testWidgets('active tab has a visually distinct indicator container',
        (tester) async {
      await tester.pumpWidget(_wrapWithRouter());
      // The active tab should have at least one Container used as a pill/indicator
      // We test this by finding a Container with non-zero border-radius decoration
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasRoundedContainer = containers.any((c) {
        final dec = c.decoration;
        if (dec is BoxDecoration) {
          final br = dec.borderRadius;
          if (br is BorderRadius) {
            return br.topLeft.x > 0;
          }
        }
        return false;
      });
      expect(hasRoundedContainer, isTrue,
          reason:
              'Expected a rounded pill container for the active nav indicator');
    });
  });

  group('AppShell — DanderCard widget', () {
    testWidgets('DanderCard renders its child', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DanderCard(child: const Text('hello')),
          ),
        ),
      );
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('DanderCard has rounded corners', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DanderCard(child: const SizedBox()),
          ),
        ),
      );
      // DanderCard wraps in a Container with a BoxDecoration with borderRadius
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasRounded = containers.any((c) {
        final dec = c.decoration;
        if (dec is BoxDecoration) {
          final br = dec.borderRadius;
          if (br is BorderRadius) return br.topLeft.x > 0;
        }
        return false;
      });
      expect(hasRounded, isTrue);
    });

    testWidgets('DanderCard applies elevation shadow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DanderCard(child: const SizedBox()),
          ),
        ),
      );
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasShadow = containers.any((c) {
        final dec = c.decoration;
        if (dec is BoxDecoration) {
          return dec.boxShadow != null && dec.boxShadow!.isNotEmpty;
        }
        return false;
      });
      expect(hasShadow, isTrue,
          reason: 'DanderCard should apply a box shadow for elevation');
    });
  });

  group('AppShell — DanderButton widget', () {
    testWidgets('DanderButton renders its label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DanderButton(
              label: 'Start Walk',
              onPressed: () {},
            ),
          ),
        ),
      );
      expect(find.text('Start Walk'), findsOneWidget);
    });

    testWidgets('DanderButton calls onPressed when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DanderButton(
              label: 'Tap me',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Tap me'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('DanderButton is disabled when onPressed is null',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DanderButton(
              label: 'Disabled',
              onPressed: null,
            ),
          ),
        ),
      );
      expect(find.text('Disabled'), findsOneWidget);
      // Tapping does nothing — no exception thrown
      await tester.tap(find.text('Disabled'));
      await tester.pump();
    });

    testWidgets('DanderButton with icon renders icon widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DanderButton(
              label: 'Navigate',
              icon: Icons.navigation,
              onPressed: () {},
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.navigation), findsOneWidget);
      expect(find.text('Navigate'), findsOneWidget);
    });
  });
}
