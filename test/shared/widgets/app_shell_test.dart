import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:dander/shared/widgets/app_shell.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _wrapWithRouter(Widget shell) {
  final router = GoRouter(
    initialLocation: '/home',
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

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('AppShell', () {
    testWidgets('renders bottom navigation bar', (tester) async {
      await tester.pumpWidget(_wrapWithRouter(const SizedBox()));
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('has Explore tab', (tester) async {
      await tester.pumpWidget(_wrapWithRouter(const SizedBox()));
      expect(find.text('Explore'), findsOneWidget);
    });

    testWidgets('has Discoveries tab', (tester) async {
      await tester.pumpWidget(_wrapWithRouter(const SizedBox()));
      expect(find.text('Discoveries'), findsOneWidget);
    });

    testWidgets('has Profile tab', (tester) async {
      await tester.pumpWidget(_wrapWithRouter(const SizedBox()));
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('has Quiz tab', (tester) async {
      await tester.pumpWidget(_wrapWithRouter(const SizedBox()));
      expect(find.text('Quiz'), findsOneWidget);
    });

    testWidgets('bottom nav has 4 items including Quiz', (tester) async {
      await tester.pumpWidget(_wrapWithRouter(const SizedBox()));
      final nav = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar));
      expect(nav.items.length, equals(4));
      final labels = nav.items.map((item) => item.label).toList();
      expect(labels, contains('Quiz'));
    });
  });
}
