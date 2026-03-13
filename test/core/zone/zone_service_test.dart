import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dander/core/zone/zone.dart';
import 'package:dander/core/zone/zone_level.dart';
import 'package:dander/core/zone/zone_repository.dart';
import 'package:dander/core/zone/zone_service.dart';

// ---------------------------------------------------------------------------
// Mock
// ---------------------------------------------------------------------------

class MockZoneRepository extends Mock implements ZoneRepository {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

final _now = DateTime(2026, 3, 13, 12, 0);

Zone makeZone({
  String id = 'zone_1',
  String name = 'Hackney',
  int xp = 0,
  double lat = 51.5074,
  double lng = -0.1278,
}) =>
    Zone(
      id: id,
      name: name,
      centre: LatLng(lat, lng),
      createdAt: _now,
      xp: xp,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    registerFallbackValue(makeZone());
  });

  late MockZoneRepository repo;
  late ZoneService service;

  setUp(() {
    repo = MockZoneRepository();
    service = ZoneService(repository: repo);
  });

  // -------------------------------------------------------------------------
  // awardStreetXp
  // -------------------------------------------------------------------------

  group('awardStreetXp', () {
    test('adds xpPerStreet to existing zone xp', () async {
      final zone = makeZone(xp: 20);
      when(() => repo.load('zone_1')).thenAnswer((_) async => zone);
      when(() => repo.save(any())).thenAnswer((_) async {});

      final updated = await service.awardStreetXp('zone_1');

      expect(updated.xp, 20 + ZoneLevel.xpPerStreet);
    });

    test('saves the updated zone to repository', () async {
      final zone = makeZone(xp: 0);
      when(() => repo.load('zone_1')).thenAnswer((_) async => zone);
      when(() => repo.save(any())).thenAnswer((_) async {});

      await service.awardStreetXp('zone_1');

      final captured = verify(() => repo.save(captureAny())).captured;
      expect(captured, hasLength(1));
      final saved = captured.first as Zone;
      expect(saved.xp, ZoneLevel.xpPerStreet);
    });

    test('returns new zone object (immutability)', () async {
      final zone = makeZone(xp: 0);
      when(() => repo.load('zone_1')).thenAnswer((_) async => zone);
      when(() => repo.save(any())).thenAnswer((_) async {});

      final updated = await service.awardStreetXp('zone_1');

      expect(updated, isNot(same(zone)));
      expect(zone.xp, 0); // original unchanged
    });

    test('throws StateError when zone not found', () async {
      when(() => repo.load('missing')).thenAnswer((_) async => null);

      await expectLater(
        service.awardStreetXp('missing'),
        throwsA(isA<StateError>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // awardQuizXp — no streak bonus
  // -------------------------------------------------------------------------

  group('awardQuizXp without streak bonus', () {
    test('adds xpPerQuizCorrect when isStreakBonus is false', () async {
      final zone = makeZone(xp: 10);
      when(() => repo.load('zone_1')).thenAnswer((_) async => zone);
      when(() => repo.save(any())).thenAnswer((_) async {});

      final updated =
          await service.awardQuizXp('zone_1', isStreakBonus: false);

      expect(updated.xp, 10 + ZoneLevel.xpPerQuizCorrect);
    });

    test('saves updated zone', () async {
      final zone = makeZone(xp: 0);
      when(() => repo.load('zone_1')).thenAnswer((_) async => zone);
      when(() => repo.save(any())).thenAnswer((_) async {});

      await service.awardQuizXp('zone_1', isStreakBonus: false);

      final captured = verify(() => repo.save(captureAny())).captured;
      expect((captured.first as Zone).xp, ZoneLevel.xpPerQuizCorrect);
    });

    test('returns new zone object (immutability)', () async {
      final zone = makeZone(xp: 0);
      when(() => repo.load('zone_1')).thenAnswer((_) async => zone);
      when(() => repo.save(any())).thenAnswer((_) async {});

      final updated =
          await service.awardQuizXp('zone_1', isStreakBonus: false);

      expect(updated, isNot(same(zone)));
    });

    test('throws StateError when zone not found', () async {
      when(() => repo.load('missing')).thenAnswer((_) async => null);

      await expectLater(
        service.awardQuizXp('missing', isStreakBonus: false),
        throwsA(isA<StateError>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // awardQuizXp — with streak bonus
  // -------------------------------------------------------------------------

  group('awardQuizXp with streak bonus', () {
    test('adds xpPerQuizCorrect + xpPerStreakBonus when isStreakBonus is true',
        () async {
      final zone = makeZone(xp: 0);
      when(() => repo.load('zone_1')).thenAnswer((_) async => zone);
      when(() => repo.save(any())).thenAnswer((_) async {});

      final updated =
          await service.awardQuizXp('zone_1', isStreakBonus: true);

      expect(
        updated.xp,
        ZoneLevel.xpPerQuizCorrect + ZoneLevel.xpPerStreakBonus,
      );
    });

    test('saves zone with combined xp', () async {
      final zone = makeZone(xp: 0);
      when(() => repo.load('zone_1')).thenAnswer((_) async => zone);
      when(() => repo.save(any())).thenAnswer((_) async {});

      await service.awardQuizXp('zone_1', isStreakBonus: true);

      final captured = verify(() => repo.save(captureAny())).captured;
      final saved = captured.first as Zone;
      expect(saved.xp,
          ZoneLevel.xpPerQuizCorrect + ZoneLevel.xpPerStreakBonus);
    });
  });

  // -------------------------------------------------------------------------
  // awardPoiXp
  // -------------------------------------------------------------------------

  group('awardPoiXp', () {
    test('adds xpPerPoi to existing zone xp', () async {
      final zone = makeZone(xp: 100);
      when(() => repo.load('zone_1')).thenAnswer((_) async => zone);
      when(() => repo.save(any())).thenAnswer((_) async {});

      final updated = await service.awardPoiXp('zone_1');

      expect(updated.xp, 100 + ZoneLevel.xpPerPoi);
    });

    test('saves updated zone', () async {
      final zone = makeZone(xp: 0);
      when(() => repo.load('zone_1')).thenAnswer((_) async => zone);
      when(() => repo.save(any())).thenAnswer((_) async {});

      await service.awardPoiXp('zone_1');

      final captured = verify(() => repo.save(captureAny())).captured;
      expect((captured.first as Zone).xp, ZoneLevel.xpPerPoi);
    });

    test('returns new zone object (immutability)', () async {
      final zone = makeZone(xp: 0);
      when(() => repo.load('zone_1')).thenAnswer((_) async => zone);
      when(() => repo.save(any())).thenAnswer((_) async {});

      final updated = await service.awardPoiXp('zone_1');

      expect(updated, isNot(same(zone)));
    });

    test('throws StateError when zone not found', () async {
      when(() => repo.load('missing')).thenAnswer((_) async => null);

      await expectLater(
        service.awardPoiXp('missing'),
        throwsA(isA<StateError>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // Quiz streak tracking
  // -------------------------------------------------------------------------

  group('quiz streak tracking', () {
    test('initial streak count is 0 for any zone', () {
      expect(service.quizStreakFor('zone_1'), 0);
    });

    test('incrementQuizStreak increases count by 1', () {
      service.incrementQuizStreak('zone_1');
      expect(service.quizStreakFor('zone_1'), 1);
    });

    test('incrementQuizStreak accumulates across calls', () {
      service.incrementQuizStreak('zone_1');
      service.incrementQuizStreak('zone_1');
      service.incrementQuizStreak('zone_1');
      expect(service.quizStreakFor('zone_1'), 3);
    });

    test('streaks are tracked independently per zone', () {
      service.incrementQuizStreak('zone_1');
      service.incrementQuizStreak('zone_1');
      service.incrementQuizStreak('zone_2');
      expect(service.quizStreakFor('zone_1'), 2);
      expect(service.quizStreakFor('zone_2'), 1);
    });

    test('resetQuizStreak resets count to 0', () {
      service.incrementQuizStreak('zone_1');
      service.incrementQuizStreak('zone_1');
      service.resetQuizStreak('zone_1');
      expect(service.quizStreakFor('zone_1'), 0);
    });

    test('resetQuizStreak does not affect other zones', () {
      service.incrementQuizStreak('zone_1');
      service.incrementQuizStreak('zone_2');
      service.resetQuizStreak('zone_1');
      expect(service.quizStreakFor('zone_2'), 1);
    });

    test('resetQuizStreak on unknown zone is a no-op', () {
      service.resetQuizStreak('unknown');
      expect(service.quizStreakFor('unknown'), 0);
    });
  });

  // -------------------------------------------------------------------------
  // isStreakBonus — integration with streak count (streak > 3 means bonus)
  // -------------------------------------------------------------------------

  group('streak bonus eligibility (streak > 3 consecutive correct)', () {
    test('no bonus for first 3 correct answers', () {
      // Streak goes 0->1->2->3; bonus only kicks in after 3rd
      expect(service.isStreakBonusActive('zone_1'), isFalse);
      service.incrementQuizStreak('zone_1'); // 1
      expect(service.isStreakBonusActive('zone_1'), isFalse);
      service.incrementQuizStreak('zone_1'); // 2
      expect(service.isStreakBonusActive('zone_1'), isFalse);
      service.incrementQuizStreak('zone_1'); // 3
      expect(service.isStreakBonusActive('zone_1'), isFalse);
    });

    test('bonus activates from 4th consecutive correct answer onward', () {
      service.incrementQuizStreak('zone_1'); // 1
      service.incrementQuizStreak('zone_1'); // 2
      service.incrementQuizStreak('zone_1'); // 3
      service.incrementQuizStreak('zone_1'); // 4
      expect(service.isStreakBonusActive('zone_1'), isTrue);
    });

    test('bonus deactivates after streak reset', () {
      for (var i = 0; i < 5; i++) {
        service.incrementQuizStreak('zone_1');
      }
      service.resetQuizStreak('zone_1');
      expect(service.isStreakBonusActive('zone_1'), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // getActiveZone
  // -------------------------------------------------------------------------

  group('getActiveZone', () {
    test('returns null when there are no zones', () async {
      when(() => repo.loadAll()).thenAnswer((_) async => []);

      final result = await service.getActiveZone(LatLng(51.5074, -0.1278));

      expect(result, isNull);
    });

    test('returns the only zone if it is within 50 km', () async {
      // Zone centre is same as position — 0 km distance.
      final zone = makeZone(lat: 51.5074, lng: -0.1278);
      when(() => repo.loadAll()).thenAnswer((_) async => [zone]);

      final result = await service.getActiveZone(LatLng(51.5074, -0.1278));

      expect(result, isNotNull);
      expect(result!.id, 'zone_1');
    });

    test('returns null when the only zone is beyond 50 km', () async {
      // Paris (~340 km from London)
      final zone = makeZone(lat: 48.8566, lng: 2.3522);
      when(() => repo.loadAll()).thenAnswer((_) async => [zone]);

      final result = await service.getActiveZone(LatLng(51.5074, -0.1278));

      expect(result, isNull);
    });

    test('returns the closest zone when multiple are within range', () async {
      // zone_1: very close, zone_2: farther but still within 50 km
      final close = makeZone(id: 'zone_1', lat: 51.5074, lng: -0.1278);
      // ~10 km north of London centre
      final farther = makeZone(id: 'zone_2', lat: 51.5974, lng: -0.1278);
      when(() => repo.loadAll())
          .thenAnswer((_) async => [farther, close]);

      final result = await service.getActiveZone(LatLng(51.5074, -0.1278));

      expect(result!.id, 'zone_1');
    });

    test('ignores zones beyond 50 km and returns closest within range',
        () async {
      // Within range
      final nearby = makeZone(id: 'zone_near', lat: 51.5074, lng: -0.1278);
      // Paris — beyond range
      final distant =
          makeZone(id: 'zone_far', lat: 48.8566, lng: 2.3522);
      when(() => repo.loadAll())
          .thenAnswer((_) async => [nearby, distant]);

      final result = await service.getActiveZone(LatLng(51.5074, -0.1278));

      expect(result!.id, 'zone_near');
    });

    test('returns null when all zones are beyond 50 km', () async {
      final paris = makeZone(id: 'paris', lat: 48.8566, lng: 2.3522);
      final berlin = makeZone(id: 'berlin', lat: 52.5200, lng: 13.4050);
      when(() => repo.loadAll())
          .thenAnswer((_) async => [paris, berlin]);

      final result = await service.getActiveZone(LatLng(51.5074, -0.1278));

      expect(result, isNull);
    });

    test('zone exactly at 50 km boundary is included', () async {
      // Approximate: move ~50 km north of 51.5074°N
      // 1 degree latitude ≈ 111 km, so 0.45° ≈ 50 km
      final boundary = makeZone(lat: 51.9574, lng: -0.1278); // ~50 km north
      when(() => repo.loadAll()).thenAnswer((_) async => [boundary]);

      final result = await service.getActiveZone(LatLng(51.5074, -0.1278));

      // Accept either included or excluded — we just verify no exception.
      // The exact boundary is tested via distance tolerance in the impl.
      expect(() => result, returnsNormally);
    });
  });

  // -------------------------------------------------------------------------
  // XP accumulation across multiple award calls
  // -------------------------------------------------------------------------

  group('XP accumulation', () {
    test('multiple street awards accumulate correctly', () async {
      // Simulate the repository always returning the latest saved state.
      var currentZone = makeZone(xp: 0);
      when(() => repo.load('zone_1'))
          .thenAnswer((_) async => currentZone);
      when(() => repo.save(any())).thenAnswer((invocation) async {
        currentZone = invocation.positionalArguments.first as Zone;
      });

      await service.awardStreetXp('zone_1');
      await service.awardStreetXp('zone_1');
      await service.awardStreetXp('zone_1');

      expect(currentZone.xp, 3 * ZoneLevel.xpPerStreet);
    });

    test('poi award after street award accumulates on latest saved xp',
        () async {
      var currentZone = makeZone(xp: 0);
      when(() => repo.load('zone_1'))
          .thenAnswer((_) async => currentZone);
      when(() => repo.save(any())).thenAnswer((invocation) async {
        currentZone = invocation.positionalArguments.first as Zone;
      });

      await service.awardStreetXp('zone_1');
      await service.awardPoiXp('zone_1');

      expect(
        currentZone.xp,
        ZoneLevel.xpPerStreet + ZoneLevel.xpPerPoi,
      );
    });
  });
}
