import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/quiz/street_memory_record.dart';
import 'package:dander/core/zone/zone.dart';
import 'package:dander/core/zone/zone_stats.dart';
import 'package:dander/core/fog/fog_grid.dart';
import 'package:dander/core/zone/zone_stats_service.dart';
import 'package:dander/core/streets/street_repository.dart';
import 'package:dander/core/discoveries/discovery_repository.dart';
import 'package:dander/core/location/walk_repository.dart';
import 'package:dander/core/quiz/quiz_repository.dart';
import 'package:dander/features/zones/presentation/screens/zone_detail_screen.dart';

// ---------------------------------------------------------------------------
// Fake ZoneStatsService
// ---------------------------------------------------------------------------

class _FakeZoneStatsService extends ZoneStatsService {
  _FakeZoneStatsService({required this.stats})
      : super(
          streetRepository: _NoOpStreetRepo(),
          discoveryRepository: _NoOpDiscoveryRepo(),
          walkRepository: _NoOpWalkRepo(),
          quizRepository: _NoOpQuizRepo(),
        );

  final ZoneStats stats;

  @override
  Future<ZoneStats> getStats(Zone zone, {FogGrid? fogGrid}) async => stats;
}

// Minimal no-op repo stubs — required by ZoneStatsService constructor.
class _NoOpStreetRepo implements StreetRepository {
  @override
  dynamic noSuchMethod(Invocation inv) => throw UnimplementedError();
}

class _NoOpDiscoveryRepo implements DiscoveryRepository {
  @override
  dynamic noSuchMethod(Invocation inv) => throw UnimplementedError();
}

class _NoOpWalkRepo implements WalkRepository {
  @override
  dynamic noSuchMethod(Invocation inv) => throw UnimplementedError();
}

class _NoOpQuizRepo implements QuizRepository {
  @override
  dynamic noSuchMethod(Invocation inv) => throw UnimplementedError();
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Zone _testZone({
  String name = 'Hackney',
  int xp = 150,
  DateTime? createdAt,
}) =>
    Zone(
      id: 'zone-1',
      name: name,
      centre: const LatLng(51.5, -0.05),
      xp: xp,
      createdAt: createdAt ?? DateTime(2024, 3, 15),
    );

ZoneStats _populatedStats() => ZoneStats(
      streetsWalkedCount: 12,
      discoveryCount: 5,
      discoveriesByCategory: {'cafe': 3, 'park': 2},
      discoveriesByRarity: {
        RarityTier.common: 3,
        RarityTier.uncommon: 1,
        RarityTier.rare: 1,
      },
      totalDistanceMeters: 4500.0,
      masteryStates: {
        MemoryState.mastered: 4,
        MemoryState.review: 3,
        MemoryState.learning: 2,
        MemoryState.newCard: 3,
      },
      explorationPct: 0.6,
      recentActivity: [
        ZoneActivity(
          type: ZoneActivityType.discovery,
          description: 'Cafe A',
          timestamp: DateTime(2024, 4, 2),
        ),
        ZoneActivity(
          type: ZoneActivityType.walk,
          description: 'Walk',
          timestamp: DateTime(2024, 4, 1),
        ),
      ],
    );

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: child,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ZoneDetailScreen', () {
    group('header', () {
      testWidgets('displays zone name', (tester) async {
        final service = _FakeZoneStatsService(stats: _populatedStats());
        await tester.pumpWidget(_wrap(ZoneDetailScreen(
          zone: _testZone(name: 'Hackney Central'),
          statsService: service,
        )));
        await tester.pumpAndSettle();

        expect(find.text('Hackney Central'), findsOneWidget);
      });

      testWidgets('displays level badge', (tester) async {
        // 150 XP → L2
        final service = _FakeZoneStatsService(stats: _populatedStats());
        await tester.pumpWidget(_wrap(ZoneDetailScreen(
          zone: _testZone(xp: 150),
          statsService: service,
        )));
        await tester.pumpAndSettle();

        expect(find.textContaining('Lv.2'), findsAtLeastNWidgets(1));
      });

      testWidgets('displays created date', (tester) async {
        final service = _FakeZoneStatsService(stats: _populatedStats());
        await tester.pumpWidget(_wrap(ZoneDetailScreen(
          zone: _testZone(createdAt: DateTime(2024, 3, 15)),
          statsService: service,
        )));
        await tester.pumpAndSettle();

        expect(find.textContaining('Mar'), findsAtLeastNWidgets(1));
      });

      testWidgets('displays exploration ring', (tester) async {
        final service = _FakeZoneStatsService(stats: _populatedStats());
        await tester.pumpWidget(_wrap(ZoneDetailScreen(
          zone: _testZone(),
          statsService: service,
        )));
        await tester.pumpAndSettle();

        // Exploration ring should show percentage
        expect(find.textContaining('60%'), findsAtLeastNWidgets(1));
      });
    });

    group('XP progress', () {
      testWidgets('shows XP progress bar', (tester) async {
        final service = _FakeZoneStatsService(stats: _populatedStats());
        await tester.pumpWidget(_wrap(ZoneDetailScreen(
          zone: _testZone(xp: 150),
          statsService: service,
        )));
        await tester.pumpAndSettle();

        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('shows current and next XP', (tester) async {
        // 150 XP, next level at 300
        final service = _FakeZoneStatsService(stats: _populatedStats());
        await tester.pumpWidget(_wrap(ZoneDetailScreen(
          zone: _testZone(xp: 150),
          statsService: service,
        )));
        await tester.pumpAndSettle();

        expect(find.textContaining('150'), findsAtLeastNWidgets(1));
        expect(find.textContaining('300'), findsAtLeastNWidgets(1));
      });

      testWidgets('shows current and next radius', (tester) async {
        // L2 → 1.5km, next L3 → 3km
        final service = _FakeZoneStatsService(stats: _populatedStats());
        await tester.pumpWidget(_wrap(ZoneDetailScreen(
          zone: _testZone(xp: 150),
          statsService: service,
        )));
        await tester.pumpAndSettle();

        expect(find.textContaining('1.5km'), findsAtLeastNWidgets(1));
        expect(find.textContaining('3km'), findsAtLeastNWidgets(1));
      });

      testWidgets('shows max level text for max level zone', (tester) async {
        final service = _FakeZoneStatsService(stats: _populatedStats());
        await tester.pumpWidget(_wrap(ZoneDetailScreen(
          zone: _testZone(xp: 1500),
          statsService: service,
        )));
        await tester.pumpAndSettle();

        expect(find.textContaining('Max'), findsAtLeastNWidgets(1));
      });
    });

    group('exploration stats', () {
      testWidgets('shows streets walked count', (tester) async {
        final service = _FakeZoneStatsService(stats: _populatedStats());
        await tester.pumpWidget(_wrap(ZoneDetailScreen(
          zone: _testZone(),
          statsService: service,
        )));
        await tester.pumpAndSettle();

        expect(find.textContaining('12'), findsAtLeastNWidgets(1));
      });

      testWidgets('shows discovery count', (tester) async {
        final service = _FakeZoneStatsService(stats: _populatedStats());
        await tester.pumpWidget(_wrap(ZoneDetailScreen(
          zone: _testZone(),
          statsService: service,
        )));
        await tester.pumpAndSettle();

        expect(find.textContaining('5'), findsAtLeastNWidgets(1));
      });

      testWidgets('shows distance walked', (tester) async {
        final service = _FakeZoneStatsService(stats: _populatedStats());
        await tester.pumpWidget(_wrap(ZoneDetailScreen(
          zone: _testZone(),
          statsService: service,
        )));
        await tester.pumpAndSettle();

        // 4500m → 4.5 km
        expect(find.textContaining('4.5'), findsAtLeastNWidgets(1));
      });

      testWidgets('shows route, explore, and straighten icons', (tester) async {
        final service = _FakeZoneStatsService(stats: _populatedStats());
        await tester.pumpWidget(_wrap(ZoneDetailScreen(
          zone: _testZone(),
          statsService: service,
        )));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.route), findsOneWidget);
        expect(find.byIcon(Icons.explore), findsOneWidget);
        expect(find.byIcon(Icons.straighten), findsOneWidget);
      });
    });

    group('discovery breakdown', () {
      testWidgets('shows Discoveries section title', (tester) async {
        final service = _FakeZoneStatsService(stats: _populatedStats());
        await tester.pumpWidget(_wrap(ZoneDetailScreen(
          zone: _testZone(),
          statsService: service,
        )));
        await tester.pumpAndSettle();

        expect(find.text('Discoveries'), findsAtLeastNWidgets(1));
      });

      testWidgets('shows rarity rows', (tester) async {
        final service = _FakeZoneStatsService(stats: _populatedStats());
        await tester.pumpWidget(_wrap(ZoneDetailScreen(
          zone: _testZone(),
          statsService: service,
        )));
        await tester.pumpAndSettle();

        expect(find.text('Common'), findsOneWidget);
        expect(find.text('Uncommon'), findsOneWidget);
        expect(find.text('Rare'), findsOneWidget);
      });

      testWidgets('shows category chips', (tester) async {
        final service = _FakeZoneStatsService(stats: _populatedStats());
        await tester.pumpWidget(_wrap(ZoneDetailScreen(
          zone: _testZone(),
          statsService: service,
        )));
        await tester.pumpAndSettle();

        expect(find.textContaining('cafe'), findsAtLeastNWidgets(1));
        expect(find.textContaining('park'), findsAtLeastNWidgets(1));
      });
    });

    group('learning mastery', () {
      testWidgets('shows Quiz Mastery section title', (tester) async {
        final service = _FakeZoneStatsService(stats: _populatedStats());
        await tester.pumpWidget(_wrap(ZoneDetailScreen(
          zone: _testZone(),
          statsService: service,
        )));
        await tester.pumpAndSettle();

        expect(find.text('Quiz Mastery'), findsOneWidget);
      });

      testWidgets('shows mastery state labels', (tester) async {
        final service = _FakeZoneStatsService(stats: _populatedStats());
        await tester.pumpWidget(_wrap(ZoneDetailScreen(
          zone: _testZone(),
          statsService: service,
        )));
        await tester.pumpAndSettle();

        expect(find.text('Mastered'), findsOneWidget);
        expect(find.text('Review'), findsOneWidget);
        expect(find.text('Learning'), findsOneWidget);
        expect(find.text('New'), findsOneWidget);
      });
    });

    group('loading state', () {
      testWidgets('shows loading skeleton before data resolves',
          (tester) async {
        final service = _FakeZoneStatsService(stats: _populatedStats());
        await tester.pumpWidget(_wrap(ZoneDetailScreen(
          zone: _testZone(),
          statsService: service,
        )));
        // Don't settle — check the initial frame
        expect(find.byType(ZoneDetailLoadingSkeleton), findsOneWidget);
      });
    });

    group('empty state', () {
      testWidgets('shows encouraging message when stats are empty',
          (tester) async {
        final service = _FakeZoneStatsService(stats: ZoneStats.empty);
        await tester.pumpWidget(_wrap(ZoneDetailScreen(
          zone: _testZone(xp: 0),
          statsService: service,
        )));
        await tester.pumpAndSettle();

        // Should show encouraging text, not error text
        expect(
          find.textContaining('Start exploring'),
          findsAtLeastNWidgets(1),
        );
      });
    });

    group('back navigation', () {
      testWidgets('back button is present', (tester) async {
        final service = _FakeZoneStatsService(stats: _populatedStats());
        await tester.pumpWidget(_wrap(ZoneDetailScreen(
          zone: _testZone(),
          statsService: service,
        )));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      });
    });
  });
}
