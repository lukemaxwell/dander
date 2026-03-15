import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/discoveries/discovery_repository.dart';
import 'package:dander/core/location/walk_repository.dart';
import 'package:dander/core/location/walk_session.dart';
import 'package:dander/core/quiz/quiz_repository.dart';
import 'package:dander/core/quiz/street_memory_record.dart';
import 'package:dander/core/streets/street.dart';
import 'package:dander/core/streets/street_repository.dart';
import 'package:dander/core/zone/zone.dart';
import 'package:dander/core/zone/zone_stats.dart';
import 'package:dander/core/zone/zone_stats_service.dart';

// ---------------------------------------------------------------------------
// Fake repositories
// ---------------------------------------------------------------------------

class _FakeStreetRepository implements StreetRepository {
  _FakeStreetRepository({this.walkedStreets = const []});

  final List<Street> walkedStreets;

  @override
  Future<List<Street>> getWalkedStreets() async => walkedStreets;

  @override
  Future<void> saveStreets(List<Street> streets, LatLngBounds bounds) async {}
  @override
  Future<List<Street>> getStreets(LatLngBounds bounds) async => [];
  @override
  Future<void> markWalked(String streetId, DateTime walkedAt) async {}
  @override
  Future<bool> hasCache(LatLngBounds bounds) async => false;
}

class _FakeDiscoveryRepository implements DiscoveryRepository {
  _FakeDiscoveryRepository({
    this.allCached = const [],
    this.discovered = const [],
  });

  final List<Discovery> allCached;
  final List<Discovery> discovered;

  @override
  Future<List<Discovery>> getAllCached() async => allCached;
  @override
  Future<List<Discovery>> getDiscovered() async => discovered;

  @override
  Future<void> savePOIs(List<Discovery> d, LatLngBounds b) async {}
  @override
  Future<List<Discovery>> getPOIs(LatLngBounds bounds) async => [];
  @override
  Future<void> markDiscovered(String id, DateTime at) async {}
  @override
  Future<bool> hasCache(LatLngBounds bounds) async => false;
  @override
  Future<void> saveDiscovered(Discovery discovery) async {}
}

class _FakeWalkRepository implements WalkRepository {
  _FakeWalkRepository({this.walks = const []});

  final List<WalkSession> walks;

  @override
  Future<List<WalkSession>> getWalks() async => walks;
  @override
  Future<WalkSession?> getWalk(String id) async => null;
  @override
  Future<void> saveWalk(WalkSession session) async {}
}

class _FakeQuizRepository implements QuizRepository {
  _FakeQuizRepository({this.records = const []});

  final List<StreetMemoryRecord> records;

  @override
  Future<List<StreetMemoryRecord>> getAllRecords() async => records;
  @override
  Future<StreetMemoryRecord?> getRecord(String streetId) async => null;
  @override
  Future<void> saveRecord(StreetMemoryRecord record) async {}
  @override
  Future<void> ensureRecord(String streetId) async {}
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

/// Zone centred on (51.5, -0.05) with 500m radius (L1, 0 XP).
Zone _testZone({int xp = 0}) => Zone(
      id: 'zone-1',
      name: 'Test Zone',
      centre: const LatLng(51.5, -0.05),
      xp: xp,
      createdAt: DateTime(2024, 1, 1),
    );

/// Creates a street with nodes at the given positions.
Street _street({
  required String id,
  required String name,
  required List<LatLng> nodes,
  DateTime? walkedAt,
}) =>
    Street(id: id, name: name, nodes: nodes, walkedAt: walkedAt);

/// Creates a discovery at the given position.
Discovery _discovery({
  required String id,
  required String name,
  required LatLng position,
  String category = 'cafe',
  RarityTier rarity = RarityTier.common,
  DateTime? discoveredAt,
}) =>
    Discovery(
      id: id,
      name: name,
      category: category,
      rarity: rarity,
      position: position,
      osmTags: const {},
      discoveredAt: discoveredAt,
    );

/// Approximately 100m north of zone centre (well within 500m radius).
const _insideZone = LatLng(51.5009, -0.05);

/// Approximately 200m east of zone centre (within 500m radius).
const _insideZone2 = LatLng(51.5, -0.047);

/// Approximately 2km away — outside 500m radius.
const _outsideZone = LatLng(51.52, -0.05);

ZoneStatsService _buildService({
  List<Street> walkedStreets = const [],
  List<Discovery> allCached = const [],
  List<Discovery> discovered = const [],
  List<WalkSession> walks = const [],
  List<StreetMemoryRecord> quizRecords = const [],
}) {
  return ZoneStatsService(
    streetRepository: _FakeStreetRepository(walkedStreets: walkedStreets),
    discoveryRepository: _FakeDiscoveryRepository(
      allCached: allCached,
      discovered: discovered,
    ),
    walkRepository: _FakeWalkRepository(walks: walks),
    quizRepository: _FakeQuizRepository(records: quizRecords),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ZoneStatsService', () {
    group('empty data', () {
      test('returns zero counts when all repos are empty', () async {
        final service = _buildService();
        final stats = await service.getStats(_testZone());

        expect(stats.streetsWalkedCount, 0);
        expect(stats.discoveryCount, 0);
        expect(stats.discoveriesByCategory, isEmpty);
        expect(stats.discoveriesByRarity, isEmpty);
        expect(stats.totalDistanceMeters, 0.0);
        expect(stats.masteryStates, isEmpty);
        expect(stats.explorationPct, 0.0);
        expect(stats.recentActivity, isEmpty);
      });
    });

    group('streets — geographic filtering', () {
      test('counts streets with nodes inside zone radius', () async {
        final service = _buildService(
          walkedStreets: [
            _street(
              id: 'st-1',
              name: 'Inside St',
              nodes: [_insideZone],
              walkedAt: DateTime(2024, 2, 1),
            ),
          ],
        );
        final stats = await service.getStats(_testZone());
        expect(stats.streetsWalkedCount, 1);
      });

      test('excludes streets with all nodes outside zone radius', () async {
        final service = _buildService(
          walkedStreets: [
            _street(
              id: 'st-far',
              name: 'Far Away St',
              nodes: [_outsideZone],
              walkedAt: DateTime(2024, 2, 1),
            ),
          ],
        );
        final stats = await service.getStats(_testZone());
        expect(stats.streetsWalkedCount, 0);
      });

      test('includes street if any node is inside zone radius', () async {
        final service = _buildService(
          walkedStreets: [
            _street(
              id: 'st-partial',
              name: 'Partial St',
              nodes: [_outsideZone, _insideZone],
              walkedAt: DateTime(2024, 2, 1),
            ),
          ],
        );
        final stats = await service.getStats(_testZone());
        expect(stats.streetsWalkedCount, 1);
      });

      test('counts multiple streets inside zone', () async {
        final service = _buildService(
          walkedStreets: [
            _street(
              id: 'st-1',
              name: 'Street A',
              nodes: [_insideZone],
              walkedAt: DateTime(2024, 2, 1),
            ),
            _street(
              id: 'st-2',
              name: 'Street B',
              nodes: [_insideZone2],
              walkedAt: DateTime(2024, 2, 2),
            ),
            _street(
              id: 'st-3',
              name: 'Street C (far)',
              nodes: [_outsideZone],
              walkedAt: DateTime(2024, 2, 3),
            ),
          ],
        );
        final stats = await service.getStats(_testZone());
        expect(stats.streetsWalkedCount, 2);
      });
    });

    group('discoveries — geographic filtering and grouping', () {
      test('counts discovered POIs inside zone radius', () async {
        final service = _buildService(
          allCached: [
            _discovery(
              id: 'd-1',
              name: 'Cafe A',
              position: _insideZone,
              discoveredAt: DateTime(2024, 3, 1),
            ),
            _discovery(
              id: 'd-2',
              name: 'Cafe B',
              position: _outsideZone,
              discoveredAt: DateTime(2024, 3, 2),
            ),
          ],
        );
        final stats = await service.getStats(_testZone());
        expect(stats.discoveryCount, 1);
      });

      test('groups discoveries by category', () async {
        final service = _buildService(
          allCached: [
            _discovery(
              id: 'd-1',
              name: 'Cafe A',
              position: _insideZone,
              category: 'cafe',
              discoveredAt: DateTime(2024, 3, 1),
            ),
            _discovery(
              id: 'd-2',
              name: 'Cafe B',
              position: _insideZone2,
              category: 'cafe',
              discoveredAt: DateTime(2024, 3, 2),
            ),
            _discovery(
              id: 'd-3',
              name: 'Park A',
              position: _insideZone,
              category: 'park',
              discoveredAt: DateTime(2024, 3, 3),
            ),
          ],
        );
        final stats = await service.getStats(_testZone());
        expect(stats.discoveriesByCategory['cafe'], 2);
        expect(stats.discoveriesByCategory['park'], 1);
      });

      test('groups discoveries by rarity', () async {
        final service = _buildService(
          allCached: [
            _discovery(
              id: 'd-1',
              name: 'Common POI',
              position: _insideZone,
              rarity: RarityTier.common,
              discoveredAt: DateTime(2024, 3, 1),
            ),
            _discovery(
              id: 'd-2',
              name: 'Rare POI',
              position: _insideZone2,
              rarity: RarityTier.rare,
              discoveredAt: DateTime(2024, 3, 2),
            ),
          ],
        );
        final stats = await service.getStats(_testZone());
        expect(stats.discoveriesByRarity[RarityTier.common], 1);
        expect(stats.discoveriesByRarity[RarityTier.rare], 1);
      });

      test('excludes undiscovered POIs from discovery count but includes in exploration pct denominator', () async {
        final service = _buildService(
          allCached: [
            _discovery(
              id: 'd-1',
              name: 'Found',
              position: _insideZone,
              discoveredAt: DateTime(2024, 3, 1),
            ),
            _discovery(
              id: 'd-2',
              name: 'Not Found',
              position: _insideZone2,
              // discoveredAt is null
            ),
          ],
        );
        final stats = await service.getStats(_testZone());
        expect(stats.discoveryCount, 1);
        expect(stats.explorationPct, closeTo(0.5, 0.01));
      });

      test('exploration pct is 0 when no cached POIs in zone', () async {
        final service = _buildService(
          allCached: [
            _discovery(
              id: 'd-far',
              name: 'Far POI',
              position: _outsideZone,
            ),
          ],
        );
        final stats = await service.getStats(_testZone());
        expect(stats.explorationPct, 0.0);
      });

      test('exploration pct is 1.0 when all POIs discovered', () async {
        final service = _buildService(
          allCached: [
            _discovery(
              id: 'd-1',
              name: 'POI',
              position: _insideZone,
              discoveredAt: DateTime(2024, 3, 1),
            ),
          ],
        );
        final stats = await service.getStats(_testZone());
        expect(stats.explorationPct, 1.0);
      });
    });

    group('walks — geographic filtering and distance', () {
      test('sums distance for walks with points inside zone', () async {
        // Walk with 2 points ~100m apart, both inside zone
        final walk = WalkSession.start(
          id: 'w-1',
          startTime: DateTime(2024, 4, 1, 10, 0),
        )
            .addPoint(WalkPoint(
              position: _insideZone,
              timestamp: DateTime(2024, 4, 1, 10, 1),
            ))
            .addPoint(WalkPoint(
              position: _insideZone2,
              timestamp: DateTime(2024, 4, 1, 10, 2),
            ))
            .completeAt(DateTime(2024, 4, 1, 10, 5));

        final service = _buildService(walks: [walk]);
        final stats = await service.getStats(_testZone());
        expect(stats.totalDistanceMeters, greaterThan(0));
      });

      test('excludes walks with no points inside zone', () async {
        final walk = WalkSession.start(
          id: 'w-far',
          startTime: DateTime(2024, 4, 1, 10, 0),
        )
            .addPoint(WalkPoint(
              position: _outsideZone,
              timestamp: DateTime(2024, 4, 1, 10, 1),
            ))
            .completeAt(DateTime(2024, 4, 1, 10, 5));

        final service = _buildService(walks: [walk]);
        final stats = await service.getStats(_testZone());
        expect(stats.totalDistanceMeters, 0.0);
      });
    });

    group('quiz mastery — cross-reference with zone streets', () {
      test('counts mastery states for streets inside zone', () async {
        final service = _buildService(
          walkedStreets: [
            _street(
              id: 'st-1',
              name: 'Inside St',
              nodes: [_insideZone],
              walkedAt: DateTime(2024, 2, 1),
            ),
            _street(
              id: 'st-2',
              name: 'Inside St 2',
              nodes: [_insideZone2],
              walkedAt: DateTime(2024, 2, 2),
            ),
          ],
          quizRecords: [
            StreetMemoryRecord(
              streetId: 'st-1',
              state: MemoryState.mastered,
              intervalDays: 30,
              easeFactor: 2.5,
              nextReviewDate: DateTime(2024, 5, 1),
              reviewHistory: const [],
            ),
            StreetMemoryRecord(
              streetId: 'st-2',
              state: MemoryState.learning,
              intervalDays: 1,
              easeFactor: 2.5,
              nextReviewDate: DateTime(2024, 3, 1),
              reviewHistory: const [],
            ),
            // Record for street outside zone — should be excluded
            StreetMemoryRecord(
              streetId: 'st-far',
              state: MemoryState.review,
              intervalDays: 7,
              easeFactor: 2.5,
              nextReviewDate: DateTime(2024, 3, 5),
              reviewHistory: const [],
            ),
          ],
        );
        final stats = await service.getStats(_testZone());
        expect(stats.masteryStates[MemoryState.mastered], 1);
        expect(stats.masteryStates[MemoryState.learning], 1);
        expect(stats.masteryStates.containsKey(MemoryState.review), isFalse);
      });

      test('streets without quiz records count as newCard', () async {
        final service = _buildService(
          walkedStreets: [
            _street(
              id: 'st-1',
              name: 'No Quiz',
              nodes: [_insideZone],
              walkedAt: DateTime(2024, 2, 1),
            ),
          ],
          quizRecords: [], // no records at all
        );
        final stats = await service.getStats(_testZone());
        expect(stats.masteryStates[MemoryState.newCard], 1);
      });
    });

    group('recent activity', () {
      test('includes walks and discoveries inside zone, sorted newest first',
          () async {
        final walk = WalkSession.start(
          id: 'w-1',
          startTime: DateTime(2024, 4, 1, 10, 0),
        )
            .addPoint(WalkPoint(
              position: _insideZone,
              timestamp: DateTime(2024, 4, 1, 10, 1),
            ))
            .completeAt(DateTime(2024, 4, 1, 10, 5));

        final service = _buildService(
          walks: [walk],
          allCached: [
            _discovery(
              id: 'd-1',
              name: 'Cafe A',
              position: _insideZone,
              discoveredAt: DateTime(2024, 4, 2),
            ),
          ],
        );
        final stats = await service.getStats(_testZone());
        expect(stats.recentActivity.length, 2);
        // Discovery is newer, should be first
        expect(stats.recentActivity[0].type, ZoneActivityType.discovery);
        expect(stats.recentActivity[1].type, ZoneActivityType.walk);
      });

      test('limits to 5 most recent entries', () async {
        final walks = List.generate(
          6,
          (i) => WalkSession.start(
            id: 'w-$i',
            startTime: DateTime(2024, 4, i + 1, 10, 0),
          )
              .addPoint(WalkPoint(
                position: _insideZone,
                timestamp: DateTime(2024, 4, i + 1, 10, 1),
              ))
              .completeAt(DateTime(2024, 4, i + 1, 10, 5)),
        );

        final service = _buildService(walks: walks);
        final stats = await service.getStats(_testZone());
        expect(stats.recentActivity.length, 5);
      });
    });

    group('larger zone radius', () {
      test('L2 zone (1500m) includes entities within expanded radius',
          () async {
        // 100 XP → L2 → 1500m radius
        // _outsideZone is ~2km away — still outside 1500m
        // But let's create a point ~1km away which IS inside 1500m
        const nearish = LatLng(51.509, -0.05); // ~1km north

        final service = _buildService(
          walkedStreets: [
            _street(
              id: 'st-near',
              name: 'Near St',
              nodes: [nearish],
              walkedAt: DateTime(2024, 2, 1),
            ),
          ],
        );
        final stats = await service.getStats(_testZone(xp: 100));
        expect(stats.streetsWalkedCount, 1);
      });
    });

    group('boundary conditions', () {
      test('handles discovery with unknown category', () async {
        final service = _buildService(
          allCached: [
            _discovery(
              id: 'd-1',
              name: 'Unknown Thing',
              position: _insideZone,
              category: 'unknown',
              discoveredAt: DateTime(2024, 3, 1),
            ),
          ],
        );
        final stats = await service.getStats(_testZone());
        // "unknown" category should still be counted
        expect(stats.discoveriesByCategory['unknown'], 1);
      });

      test('handles walk with no points', () async {
        final walk = WalkSession.start(
          id: 'w-empty',
          startTime: DateTime(2024, 4, 1, 10, 0),
        ).completeAt(DateTime(2024, 4, 1, 10, 5));

        final service = _buildService(walks: [walk]);
        final stats = await service.getStats(_testZone());
        expect(stats.totalDistanceMeters, 0.0);
        expect(stats.recentActivity, isEmpty);
      });
    });
  });
}
