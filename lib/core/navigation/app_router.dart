import 'package:flutter/material.dart' hide Badge;
import 'package:go_router/go_router.dart';

import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/progress/badge.dart';
import 'package:dander/core/progress/streak_tracker.dart';
import 'package:get_it/get_it.dart';

import 'package:dander/core/discoveries/discovery.dart' show Discovery;
import 'package:dander/core/zone/zone_repository.dart';
import 'package:dander/features/discoveries/presentation/screens/discoveries_screen.dart';
import 'package:dander/features/map/presentation/screens/map_screen.dart';
import 'package:dander/features/profile/presentation/screens/profile_screen.dart';
import 'package:dander/features/quiz/presentation/screens/quiz_home_screen.dart';
import 'package:dander/features/splash/presentation/screens/splash_screen.dart';
import 'package:dander/features/zones/presentation/screens/zones_screen.dart';
import 'package:dander/shared/widgets/app_shell.dart';

/// Named route paths used throughout the app.
abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String home = '/home';
  static const String discoveries = '/discoveries';
  static const String quiz = '/quiz';
  static const String zones = '/zones';
  static const String profile = '/profile';
}

/// The application [GoRouter] instance.
///
/// Routes:
/// - `/home`         — [MapScreen] (fog-of-war map)
/// - `/discoveries`  — [DiscoveriesScreen]
/// - `/profile`      — [ProfileScreen]
/// - `/`             — redirects to [AppRoutes.home]
final GoRouter router = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      pageBuilder: (context, state) => NoTransitionPage(
        child: SplashScreen(
          onComplete: () => router.go(AppRoutes.home),
        ),
      ),
    ),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: MapScreen()),
        ),
        GoRoute(
          path: AppRoutes.discoveries,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DiscoveriesScreen(
              discoveries: <Discovery>[],
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.quiz,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: QuizHomeScreen(
              walkedStreets: [],
              records: [],
              onStartReview: _noop,
              onPracticeAll: _noop,
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.zones,
          pageBuilder: (context, state) => NoTransitionPage(
            child: ZonesScreen(
              repository: GetIt.instance<ZoneRepository>(),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.profile,
          pageBuilder: (context, state) => NoTransitionPage(
            child: ProfileScreen(
              discoveries: const <Discovery>[],
              explorationPct: 0.0,
              streak: StreakTracker.empty(),
              badges: BadgeDefinitions.badges,
            ),
          ),
        ),
      ],
    ),
    GoRoute(path: '/', redirect: (context, state) => AppRoutes.home),
  ],
);

void _noop() {}

/// Returns the [GlobalKey<NavigatorState>] for the root navigator.
///
/// Convenience accessor used in tests.
GlobalKey<NavigatorState> get routerNavigatorKey =>
    router.routerDelegate.navigatorKey;
