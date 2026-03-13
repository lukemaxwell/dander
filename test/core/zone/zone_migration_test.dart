import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/zone/zone.dart';
import 'package:dander/core/zone/zone_migration.dart';
import 'package:dander/core/zone/zone_repository.dart';
import 'package:dander/core/storage/app_state_repository.dart';
import 'package:dander/core/streets/street_repository.dart';
import 'package:dander/core/streets/street.dart';
import 'package:dander/core/quiz/quiz_repository.dart';
import 'package:dander/core/quiz/street_memory_record.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class FakeZoneRepository implements ZoneRepository {
  final List<Zone> _zones = [];

  @override
  Future<void> save(Zone zone) async {
    _zones.removeWhere((z) => z.id == zone.id);
    _zones.add(zone);
  }

  @override
  Future<Zone?> load(String id) async {
    try {
      return _zones.firstWhere((z) => z.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Zone>> loadAll() async => List.unmodifiable(_zones);

  @override
  Future<void> delete(String id) async {
    _zones.removeWhere((z) => z.id == id);
  }
}

class FakeAppStateRepository implements AppStateRepository {
  LatLng? _lastPosition;

  void seedLastPosition(LatLng position) => _lastPosition = position;

  @override
  Future<void> saveLastPosition(LatLng position) async {
    _lastPosition = position;
  }

  @override
  Future<LatLng?> getLastPosition() async => _lastPosition;

  @override
  Future<void> saveNeighbourhoodBounds(NeighbourhoodBounds bounds) async {}

  @override
  Future<NeighbourhoodBounds?> getNeighbourhoodBounds() async => null;

  @override
  Future<void> markFirstLaunchComplete() async {}

  @override
  Future<bool> isFirstLaunch() async => true;
}

class FakeStreetRepository implements StreetRepository {
  final List<Street> _walkedStreets = [];

  void seedWalkedStreets(List<Street> streets) {
    _walkedStreets
      ..clear()
      ..addAll(streets);
  }

  @override
  Future<List<Street>> getWalkedStreets() async =>
      List.unmodifiable(_walkedStreets);

  @override
  Future<void> saveStreets(
    List<Street> streets,
    dynamic bounds,
  ) async {}

  @override
  Future<List<Street>> getStreets(dynamic bounds) async => [];

  @override
  Future<void> markWalked(String streetId, DateTime walkedAt) async {}

  @override
  Future<bool> hasCache(dynamic bounds) async => false;
}

class FakeQuizRepository implements QuizRepository {
  final List<StreetMemoryRecord> _records = [];

  void seedRecords(List<StreetMemoryRecord> records) {
    _records
      ..clear()
      ..addAll(records);
  }

  @override
  Future<void> saveRecord(StreetMemoryRecord record) async {
    _records.removeWhere((r) => r.streetId == record.streetId);
    _records.add(record);
  }

  @override
  Future<List<StreetMemoryRecord>> getAllRecords() async =>
      List.unmodifiable(_records);

  @override
  Future<StreetMemoryRecord?> getRecord(String streetId) async {
    try {
      return _records.firstWhere((r) => r.streetId == streetId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> ensureRecord(String streetId) async {
    final existing = await getRecord(streetId);
    if (existing == null) {
      await saveRecord(StreetMemoryRecord.initial(streetId));
    }
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Street _walkedStreet(String id) => Street(
      id: id,
      name: id,
      nodes: const [],
      walkedAt: DateTime(2026, 1, 1),
    );

StreetMemoryRecord _record(String id, MemoryState state) =>
    StreetMemoryRecord.initial(id).copyWith(state: state);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late FakeZoneRepository zoneRepo;
  late FakeAppStateRepository appStateRepo;
  late FakeStreetRepository streetRepo;
  late FakeQuizRepository quizRepo;

  setUp(() {
    zoneRepo = FakeZoneRepository();
    appStateRepo = FakeAppStateRepository();
    streetRepo = FakeStreetRepository();
    quizRepo = FakeQuizRepository();
  });

  group('ZoneMigration.needsMigration', () {
    test('returns true when no zones exist', () async {
      final result = await ZoneMigration.needsMigration(zoneRepo);

      expect(result, isTrue);
    });

    test('returns false when at least one zone exists', () async {
      await zoneRepo.save(
        Zone(
          id: 'zone_home',
          name: 'Home',
          centre: const LatLng(51.5074, -0.1278),
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      final result = await ZoneMigration.needsMigration(zoneRepo);

      expect(result, isFalse);
    });
  });

  group('ZoneMigration.migrate', () {
    test('skips migration when no walked streets and no quiz records',
        () async {
      await ZoneMigration.migrate(
        zoneRepo: zoneRepo,
        appStateRepo: appStateRepo,
        streetRepo: streetRepo,
        quizRepo: quizRepo,
      );

      final zones = await zoneRepo.loadAll();
      expect(zones, isEmpty);
    });

    test('creates a home zone with id "zone_home" and name "Home"', () async {
      streetRepo.seedWalkedStreets([_walkedStreet('s1')]);

      await ZoneMigration.migrate(
        zoneRepo: zoneRepo,
        appStateRepo: appStateRepo,
        streetRepo: streetRepo,
        quizRepo: quizRepo,
      );

      final zone = await zoneRepo.load('zone_home');
      expect(zone, isNotNull);
      expect(zone!.id, 'zone_home');
      expect(zone.name, 'Home');
    });

    test('uses last known position as zone centre', () async {
      streetRepo.seedWalkedStreets([_walkedStreet('s1')]);
      appStateRepo.seedLastPosition(const LatLng(48.8566, 2.3522));

      await ZoneMigration.migrate(
        zoneRepo: zoneRepo,
        appStateRepo: appStateRepo,
        streetRepo: streetRepo,
        quizRepo: quizRepo,
      );

      final zone = await zoneRepo.load('zone_home');
      expect(zone!.centre.latitude, closeTo(48.8566, 0.0001));
      expect(zone.centre.longitude, closeTo(2.3522, 0.0001));
    });

    test('falls back to London when no position is saved', () async {
      // appStateRepo has no position seeded — but user has progress
      streetRepo.seedWalkedStreets([_walkedStreet('s1')]);

      await ZoneMigration.migrate(
        zoneRepo: zoneRepo,
        appStateRepo: appStateRepo,
        streetRepo: streetRepo,
        quizRepo: quizRepo,
      );

      final zone = await zoneRepo.load('zone_home');
      expect(zone!.centre.latitude, closeTo(51.5074, 0.0001));
      expect(zone.centre.longitude, closeTo(-0.1278, 0.0001));
    });

    test('calculates XP as walkedStreets * 10 + nonNewCard * 5', () async {
      // 3 walked streets → 3 × 10 = 30 XP
      streetRepo.seedWalkedStreets([
        _walkedStreet('s1'),
        _walkedStreet('s2'),
        _walkedStreet('s3'),
      ]);

      // 4 quiz records: 2 newCard (excluded), 1 learning + 1 mastered → 2 × 5 = 10 XP
      quizRepo.seedRecords([
        _record('s1', MemoryState.newCard),
        _record('s2', MemoryState.newCard),
        _record('s3', MemoryState.learning),
        _record('s4', MemoryState.mastered),
      ]);

      await ZoneMigration.migrate(
        zoneRepo: zoneRepo,
        appStateRepo: appStateRepo,
        streetRepo: streetRepo,
        quizRepo: quizRepo,
      );

      final zone = await zoneRepo.load('zone_home');
      // 30 + 10 = 40
      expect(zone!.xp, 40);
    });

    test('counts only non-newCard quiz records for XP', () async {
      // Seed one walked street so migration proceeds
      streetRepo.seedWalkedStreets([_walkedStreet('s1')]);
      quizRepo.seedRecords([
        _record('a', MemoryState.newCard),
        _record('b', MemoryState.newCard),
        _record('c', MemoryState.newCard),
      ]);

      await ZoneMigration.migrate(
        zoneRepo: zoneRepo,
        appStateRepo: appStateRepo,
        streetRepo: streetRepo,
        quizRepo: quizRepo,
      );

      final zone = await zoneRepo.load('zone_home');
      // All newCard → 0 quiz XP, 1 walked street → 10 street XP
      expect(zone!.xp, 10);
    });

    test('counts review and mastered quiz states as XP-eligible', () async {
      quizRepo.seedRecords([
        _record('a', MemoryState.review),
        _record('b', MemoryState.mastered),
        _record('c', MemoryState.learning),
      ]);

      await ZoneMigration.migrate(
        zoneRepo: zoneRepo,
        appStateRepo: appStateRepo,
        streetRepo: streetRepo,
        quizRepo: quizRepo,
      );

      final zone = await zoneRepo.load('zone_home');
      // 3 non-newCard × 5 = 15 XP
      expect(zone!.xp, 15);
    });

    test('is idempotent — does not create duplicate zones when called twice',
        () async {
      streetRepo.seedWalkedStreets([_walkedStreet('s1')]);

      await ZoneMigration.migrate(
        zoneRepo: zoneRepo,
        appStateRepo: appStateRepo,
        streetRepo: streetRepo,
        quizRepo: quizRepo,
      );

      await ZoneMigration.migrate(
        zoneRepo: zoneRepo,
        appStateRepo: appStateRepo,
        streetRepo: streetRepo,
        quizRepo: quizRepo,
      );

      final zones = await zoneRepo.loadAll();
      expect(zones, hasLength(1));
    });

    test(
        'is idempotent — does not overwrite existing zone when one already exists',
        () async {
      final existingZone = Zone(
        id: 'zone_home',
        name: 'Customised Home',
        centre: const LatLng(40.7128, -74.0060),
        xp: 9999,
        createdAt: DateTime(2025, 6, 1),
      );
      await zoneRepo.save(existingZone);

      // Add some streets to verify XP is not recalculated
      streetRepo.seedWalkedStreets([_walkedStreet('s1')]);

      await ZoneMigration.migrate(
        zoneRepo: zoneRepo,
        appStateRepo: appStateRepo,
        streetRepo: streetRepo,
        quizRepo: quizRepo,
      );

      final zone = await zoneRepo.load('zone_home');
      expect(zone!.xp, 9999);
      expect(zone.name, 'Customised Home');
    });

    test('XP is zero when no streets walked and all quiz records are newCard',
        () async {
      streetRepo.seedWalkedStreets([]);
      quizRepo.seedRecords([_record('s1', MemoryState.newCard)]);

      await ZoneMigration.migrate(
        zoneRepo: zoneRepo,
        appStateRepo: appStateRepo,
        streetRepo: streetRepo,
        quizRepo: quizRepo,
      );

      final zone = await zoneRepo.load('zone_home');
      expect(zone!.xp, 0);
    });

    test('creates zone with zero XP when only walked streets exist', () async {
      streetRepo.seedWalkedStreets([_walkedStreet('s1')]);

      await ZoneMigration.migrate(
        zoneRepo: zoneRepo,
        appStateRepo: appStateRepo,
        streetRepo: streetRepo,
        quizRepo: quizRepo,
      );

      final zone = await zoneRepo.load('zone_home');
      // 1 walked street × 10 = 10 XP
      expect(zone!.xp, 10);
    });

    test('createdAt is set to a recent datetime', () async {
      streetRepo.seedWalkedStreets([_walkedStreet('s1')]);
      final before = DateTime.now().subtract(const Duration(seconds: 1));

      await ZoneMigration.migrate(
        zoneRepo: zoneRepo,
        appStateRepo: appStateRepo,
        streetRepo: streetRepo,
        quizRepo: quizRepo,
      );

      final after = DateTime.now().add(const Duration(seconds: 1));
      final zone = await zoneRepo.load('zone_home');
      expect(zone!.createdAt.isAfter(before), isTrue);
      expect(zone.createdAt.isBefore(after), isTrue);
    });
  });
}
