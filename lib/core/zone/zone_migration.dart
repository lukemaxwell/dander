import 'package:latlong2/latlong.dart';

import 'zone.dart';
import 'zone_level.dart';
import 'zone_repository.dart';
import '../storage/app_state_repository.dart';
import '../streets/street_repository.dart';
import '../quiz/quiz_repository.dart';
import '../quiz/street_memory_record.dart';

/// Migrates legacy fog/quiz/street state into the Zone model on first run.
///
/// This is a one-shot, idempotent service. It must be called at app startup
/// before any zone-aware features are activated.
abstract final class ZoneMigration {
  /// The well-known id assigned to the user's first (home) zone.
  static const String homeZoneId = 'zone_home';

  /// London coordinates used as a fallback when no GPS position is saved.
  static const LatLng _londonFallback = LatLng(51.5074, -0.1278);

  /// Returns `true` when no zones have been persisted yet.
  ///
  /// The caller should call [migrate] immediately when this returns `true`.
  static Future<bool> needsMigration(ZoneRepository zoneRepo) async {
    final zones = await zoneRepo.loadAll();
    return zones.isEmpty;
  }

  /// Creates the user's first Zone from existing app state.
  ///
  /// Safe to call multiple times — does nothing when a zone already exists.
  ///
  /// XP estimation:
  ///   - Each walked street contributes [ZoneLevel.xpPerStreet] (10 XP).
  ///   - Each quiz record whose [MemoryState] is not [MemoryState.newCard]
  ///     contributes [ZoneLevel.xpPerQuizCorrect] (5 XP).
  static Future<void> migrate({
    required ZoneRepository zoneRepo,
    required AppStateRepository appStateRepo,
    required StreetRepository streetRepo,
    required QuizRepository quizRepo,
  }) async {
    final alreadyMigrated = !(await needsMigration(zoneRepo));
    if (alreadyMigrated) return;

    final centre = await appStateRepo.getLastPosition() ?? _londonFallback;

    final walkedStreets = await streetRepo.getWalkedStreets();
    final quizRecords = await quizRepo.getAllRecords();

    final streetXp = walkedStreets.length * ZoneLevel.xpPerStreet;
    final quizXp = quizRecords
            .where((r) => r.state != MemoryState.newCard)
            .length *
        ZoneLevel.xpPerQuizCorrect;

    final zone = Zone(
      id: homeZoneId,
      name: 'Home',
      centre: centre,
      xp: streetXp + quizXp,
      createdAt: DateTime.now(),
    );

    await zoneRepo.save(zone);
  }
}
