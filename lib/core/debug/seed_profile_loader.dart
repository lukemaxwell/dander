import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../discoveries/discovery_repository.dart';
import '../fog/fog_repository.dart';
import '../location/walk_repository.dart';
import '../storage/app_state_repository.dart';
import '../storage/hive_boxes.dart';
import '../zone/mystery_poi_repository.dart';
import '../zone/zone_repository.dart';
import 'fixtures/active_zone_fixture.dart';
import 'fixtures/empty_fixture.dart';
import 'fixtures/high_payoff_fixture.dart';
import 'fixtures/mid_progress_fixture.dart';
import 'fixtures/onboarding_complete_fixture.dart';
import 'fog_seeder.dart';
import 'seed_fixture.dart';
import 'seed_profile.dart';

/// Detects and loads seed profiles at app startup.
///
/// Call [load] after Hive boxes are opened but before the widget tree builds.
/// In release builds, [detect] always returns [SeedProfile.none] and [load]
/// is a no-op.
class SeedProfileLoader {
  SeedProfileLoader._();

  /// Returns the fixture for the given [profile], or `null` for [SeedProfile.none].
  static SeedFixture? fixtureFor(SeedProfile profile) {
    switch (profile) {
      case SeedProfile.none:
        return null;
      case SeedProfile.empty:
        return const EmptyFixture();
      case SeedProfile.onboardingComplete:
        return const OnboardingCompleteFixture();
      case SeedProfile.activeZone:
        return const ActiveZoneFixture();
      case SeedProfile.midProgress:
        return const MidProgressFixture();
      case SeedProfile.highPayoff:
        return const HighPayoffFixture();
    }
  }

  /// Loads the seed profile's fixture data into the provided repositories.
  ///
  /// Returns the detected [SeedProfile] (useful for conditional logic downstream).
  /// Returns [SeedProfile.none] and does nothing in release builds or when
  /// no profile is set.
  static Future<SeedProfile> load({
    required AppStateRepository appStateRepository,
    SeedProfile? overrideProfile,
  }) async {
    final profile = overrideProfile ?? SeedProfile.detect();

    if (!profile.isActive) return profile;

    final fixture = fixtureFor(profile);
    if (fixture == null) return profile;

    debugPrint('SeedProfileLoader: loading "${fixture.name}" fixture');

    // Suppress onboarding if fixture requests it.
    if (fixture.suppressOnboarding) {
      await appStateRepository.markFirstLaunchComplete();
      await appStateRepository.markFirstWalkContractCompleted();
      await appStateRepository.markFirstWalkContractDismissed();
    }

    // Let the fixture seed any additional state.
    await fixture.seedAppState(appStateRepository);

    // Seed zone, POI, and walk data when Hive boxes are available.
    // In unit tests that only provide AppStateRepository, boxes may not be open.
    if (Hive.isBoxOpen(HiveBoxes.zones)) {
      await fixture.seedData(
        zoneRepository: HiveZoneRepository.withBox(
          Hive.box<dynamic>(HiveBoxes.zones),
        ),
        mysteryPoiRepository: HiveMysteryPoiRepository.withBox(
          Hive.box<dynamic>(HiveBoxes.mysteryPois),
        ),
        walkRepository: HiveWalkRepository.withBox(
          Hive.box<dynamic>(HiveBoxes.walks),
        ),
        discoveryRepository: HiveDiscoveryRepository.withBox(
          Hive.box<dynamic>(HiveBoxes.discoveries),
        ),
      );
    }

    // Seed fog grid if the fixture provides walked paths and a position.
    final position = fixture.seedPosition;
    if (position != null &&
        fixture.walkedPaths.isNotEmpty &&
        Hive.isBoxOpen(HiveBoxes.fogState)) {
      final fogGrid = FogSeeder.seed(
        origin: position,
        walkedPaths: fixture.walkedPaths,
      );
      final fogRepo = FogRepository.withBox(
        Hive.box<dynamic>(HiveBoxes.fogState),
        origin: position,
      );
      await fogRepo.save(fogGrid);
      debugPrint(
        'SeedProfileLoader: seeded fog grid with '
        '${fogGrid.exploredCount} explored cells',
      );
    }

    debugPrint('SeedProfileLoader: "${fixture.name}" loaded successfully');
    return profile;
  }
}
