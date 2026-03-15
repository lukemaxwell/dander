import 'package:flutter/material.dart' hide Badge;
import 'package:go_router/go_router.dart';

import 'package:dander/core/challenges/challenge.dart';
import 'package:dander/core/challenges/challenge_repository.dart';
import 'package:dander/core/discoveries/discovery.dart' show Discovery;
import 'package:dander/core/discoveries/discovery_repository.dart';
import 'package:dander/core/location/walk_repository.dart';
import 'package:dander/core/location/walk_session.dart';
import 'package:dander/core/progress/badge.dart';
import 'package:dander/core/progress/streak_tracker.dart';
import 'package:get_it/get_it.dart';
import 'package:dander/core/zone/zone_repository.dart';
import 'package:dander/features/discoveries/presentation/screens/discoveries_screen.dart';
import 'package:dander/features/discoveries/presentation/widgets/discoveries_loading_skeleton.dart';
import 'package:dander/features/profile/presentation/widgets/profile_loading_skeleton.dart';
import 'package:dander/features/map/presentation/screens/map_screen.dart';
import 'package:dander/features/profile/presentation/screens/profile_screen.dart';
import 'package:dander/features/quiz/presentation/screens/quiz_home_screen.dart';
import 'package:dander/features/splash/presentation/screens/splash_screen.dart';
import 'package:dander/features/walks/presentation/screens/walk_history_screen.dart';
import 'package:dander/features/zones/presentation/screens/zone_detail_screen.dart';
import 'package:dander/features/zones/presentation/screens/zones_screen.dart';
import 'package:dander/core/zone/zone.dart';
import 'package:dander/core/zone/zone_stats_service.dart';
import 'package:dander/core/navigation/page_transitions.dart';
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
  static const String zoneDetail = '/zones/:id';
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
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              pageBuilder: (context, state) =>
                  danderCrossfadePage(context, const MapScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.discoveries,
              pageBuilder: (context, state) =>
                  danderCrossfadePage(context, _DiscoveriesLoader()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.quiz,
              pageBuilder: (context, state) => danderCrossfadePage(
                context,
                const QuizHomeScreen(
                  walkedStreets: [],
                  records: [],
                  onStartReview: _noop,
                  onPracticeAll: _noop,
                ),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.zones,
              pageBuilder: (context, state) => danderCrossfadePage(
                context,
                ZonesScreen(
                  repository: GetIt.instance<ZoneRepository>(),
                  onZoneTapped: (id) => router.push('/zones/$id'),
                ),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profile,
              pageBuilder: (context, state) =>
                  danderCrossfadePage(context, _ProfileLoader()),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.zoneDetail,
      pageBuilder: (context, state) {
        final zoneId = state.pathParameters['id']!;
        return danderSlideRightPage(context, _ZoneDetailLoader(zoneId: zoneId));
      },
    ),
    GoRoute(
      path: AppRoutes.walkHistory,
      pageBuilder: (context, state) =>
          danderSlideRightPage(context, _WalkHistoryLoader()),
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
    return FutureBuilder<_DiscoveriesData>(
      future: _loadDiscoveries(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const DiscoveriesLoadingSkeleton();
        }
        final data = snapshot.data;
        return DiscoveriesScreen(
          discoveries: data?.discovered ?? const [],
          allPois: data?.allPois ?? const [],
        );
      },
    );
  }

  Future<_DiscoveriesData> _loadDiscoveries() async {
    try {
      final repo = GetIt.instance<DiscoveryRepository>();
      final results = await Future.wait([
        repo.getDiscovered(),
        repo.getAllCached(),
      ]);
      return _DiscoveriesData(
        discovered: results[0],
        allPois: results[1],
      );
    } catch (_) {
      return const _DiscoveriesData(discovered: [], allPois: []);
    }
  }
}

class _DiscoveriesData {
  const _DiscoveriesData({
    required this.discovered,
    required this.allPois,
  });

  final List<Discovery> discovered;
  final List<Discovery> allPois;
}

class _ProfileLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ProfileData>(
      future: _loadProfileData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ProfileLoadingSkeleton();
        }
        final data = snapshot.data;
        return ProfileScreen(
          discoveries: data?.discoveries ?? const [],
          explorationPct: 0.0,
          streak: StreakTracker.empty(),
          badges: BadgeDefinitions.badges,
          zoneName: data?.zoneName,
          totalSteps: data?.totalSteps ?? 0,
          totalDistanceMeters: data?.totalDistanceMeters ?? 0.0,
          weeklyChallenges: data?.weeklyChallenges ?? const [],
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

    var weeklyChallenges = <Challenge>[];
    try {
      final challengeRepo = GetIt.instance<ChallengeRepository>();
      weeklyChallenges = await challengeRepo.loadWeeklyChallenges();
      if (weeklyChallenges.isEmpty) {
        // Generate challenges for the current week
        final now = DateTime.now();
        final weekNumber =
            now.difference(DateTime(now.year, 1, 1)).inDays ~/ 7;
        weeklyChallenges = ChallengeDefinitions.challengesForWeek(weekNumber);
        await challengeRepo.saveWeeklyChallenges(weeklyChallenges);
        await challengeRepo.saveWeekNumber(weekNumber);
      }
    } catch (_) {}

    return _ProfileData(
      discoveries: discoveries,
      totalSteps: totalSteps,
      totalDistanceMeters: totalDistanceMeters,
      zoneName: zoneName,
      weeklyChallenges: weeklyChallenges,
    );
  }
}

class _ProfileData {
  const _ProfileData({
    required this.discoveries,
    required this.totalSteps,
    required this.totalDistanceMeters,
    this.zoneName,
    this.weeklyChallenges = const [],
  });

  final List<Discovery> discoveries;
  final int totalSteps;
  final double totalDistanceMeters;
  final String? zoneName;
  final List<Challenge> weeklyChallenges;
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

class _ZoneDetailLoader extends StatelessWidget {
  const _ZoneDetailLoader({required this.zoneId});

  final String zoneId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Zone?>(
      future: _loadZone(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final zone = snapshot.data;
        if (zone == null) {
          return const Scaffold(
            body: Center(child: Text('Zone not found')),
          );
        }

        return ZoneDetailScreen(
          zone: zone,
          statsService: GetIt.instance<ZoneStatsService>(),
        );
      },
    );
  }

  Future<Zone?> _loadZone() async {
    try {
      final repo = GetIt.instance<ZoneRepository>();
      return await repo.load(zoneId);
    } catch (_) {
      return null;
    }
  }
}
