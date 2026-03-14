import 'package:flutter/material.dart' hide Badge;
import 'package:go_router/go_router.dart';

import 'package:dander/core/discoveries/discovery.dart' show Discovery;
import 'package:dander/core/discoveries/discovery_repository.dart';
import 'package:dander/core/location/walk_repository.dart';
import 'package:dander/core/location/walk_session.dart';
import 'package:dander/core/progress/badge.dart';
import 'package:dander/core/progress/streak_tracker.dart';
import 'package:get_it/get_it.dart';
import 'package:dander/core/zone/zone_repository.dart';
import 'package:dander/features/discoveries/presentation/screens/discoveries_screen.dart';
import 'package:dander/features/map/presentation/screens/map_screen.dart';
import 'package:dander/features/profile/presentation/screens/profile_screen.dart';
import 'package:dander/features/quiz/presentation/screens/quiz_home_screen.dart';
import 'package:dander/features/splash/presentation/screens/splash_screen.dart';
import 'package:dander/features/walks/presentation/screens/walk_history_screen.dart';
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
  static const String walkHistory = '/walk-history';
}

/// The application [GoRouter] instance.
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
          pageBuilder: (context, state) => NoTransitionPage(
            child: _DiscoveriesLoader(),
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
            child: _ProfileLoader(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.walkHistory,
      pageBuilder: (context, state) => NoTransitionPage(
        child: _WalkHistoryLoader(),
      ),
    ),
    GoRoute(path: '/', redirect: (context, state) => AppRoutes.home),
  ],
);

void _noop() {}

/// Returns the [GlobalKey<NavigatorState>] for the root navigator.
GlobalKey<NavigatorState> get routerNavigatorKey =>
    router.routerDelegate.navigatorKey;

// ---------------------------------------------------------------------------
// Data loaders — fetch from repositories before building screens
// ---------------------------------------------------------------------------

class _DiscoveriesLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Discovery>>(
      future: _loadDiscoveries(),
      builder: (context, snapshot) {
        final discoveries = snapshot.data ?? const [];
        return DiscoveriesScreen(discoveries: discoveries);
      },
    );
  }

  Future<List<Discovery>> _loadDiscoveries() async {
    try {
      final repo = GetIt.instance<DiscoveryRepository>();
      return await repo.getDiscovered();
    } catch (_) {
      return const [];
    }
  }
}

class _ProfileLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ProfileData>(
      future: _loadProfileData(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        return ProfileScreen(
          discoveries: data?.discoveries ?? const [],
          explorationPct: 0.0,
          streak: StreakTracker.empty(),
          badges: BadgeDefinitions.badges,
          zoneName: data?.zoneName,
          totalSteps: data?.totalSteps ?? 0,
          totalDistanceMeters: data?.totalDistanceMeters ?? 0.0,
        );
      },
    );
  }

  Future<_ProfileData> _loadProfileData() async {
    var discoveries = <Discovery>[];
    var totalSteps = 0;
    var totalDistanceMeters = 0.0;
    String? zoneName;

    try {
      final discoveryRepo = GetIt.instance<DiscoveryRepository>();
      discoveries = await discoveryRepo.getDiscovered();
    } catch (_) {}

    try {
      final walkRepo = GetIt.instance<WalkRepository>();
      final walks = await walkRepo.getWalks();
      for (final walk in walks) {
        totalSteps += walk.estimatedSteps;
        totalDistanceMeters += walk.distanceMeters;
      }
    } catch (_) {}

    try {
      final zoneRepo = GetIt.instance<ZoneRepository>();
      final zones = await zoneRepo.loadAll();
      if (zones.isNotEmpty) {
        zoneName = zones.first.name;
      }
    } catch (_) {}

    return _ProfileData(
      discoveries: discoveries,
      totalSteps: totalSteps,
      totalDistanceMeters: totalDistanceMeters,
      zoneName: zoneName,
    );
  }
}

class _ProfileData {
  const _ProfileData({
    required this.discoveries,
    required this.totalSteps,
    required this.totalDistanceMeters,
    this.zoneName,
  });

  final List<Discovery> discoveries;
  final int totalSteps;
  final double totalDistanceMeters;
  final String? zoneName;
}

class _WalkHistoryLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<WalkSession>>(
      future: _loadWalks(),
      builder: (context, snapshot) {
        final walks = snapshot.data ?? const <WalkSession>[];
        return WalkHistoryScreen(walks: walks);
      },
    );
  }

  Future<List<WalkSession>> _loadWalks() async {
    try {
      final repo = GetIt.instance<WalkRepository>();
      return await repo.getWalks();
    } catch (_) {
      return const [];
    }
  }
}
