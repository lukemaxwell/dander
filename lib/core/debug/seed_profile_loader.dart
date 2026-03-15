import 'package:flutter/foundation.dart';

import '../storage/app_state_repository.dart';
import 'fixtures/empty_fixture.dart';
import 'fixtures/onboarding_complete_fixture.dart';
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
        // TODO: implement in #197
        return const OnboardingCompleteFixture();
      case SeedProfile.midProgress:
        // TODO: implement in #198
        return const OnboardingCompleteFixture();
      case SeedProfile.highPayoff:
        // TODO: implement in #198
        return const OnboardingCompleteFixture();
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

    debugPrint('SeedProfileLoader: "${fixture.name}" loaded successfully');
    return profile;
  }
}
