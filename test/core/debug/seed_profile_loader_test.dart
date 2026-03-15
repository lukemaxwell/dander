import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/debug/seed_fixture.dart';
import 'package:dander/core/debug/seed_profile.dart';
import 'package:dander/core/debug/seed_profile_loader.dart';
import 'package:dander/core/debug/fixtures/empty_fixture.dart';
import 'package:dander/core/debug/fixtures/onboarding_complete_fixture.dart';
import 'package:dander/core/storage/app_state_repository.dart';

// ---------------------------------------------------------------------------
// In-memory AppStateRepository for testing
// ---------------------------------------------------------------------------

class InMemoryAppStateRepository implements AppStateRepository {
  LatLng? lastPosition;
  NeighbourhoodBounds? neighbourhoodBounds;
  bool firstLaunchComplete = false;
  bool firstWalkContractCompleted = false;
  bool firstWalkContractDismissed = false;

  @override
  Future<void> saveLastPosition(LatLng position) async {
    lastPosition = position;
  }

  @override
  Future<LatLng?> getLastPosition() async => lastPosition;

  @override
  Future<void> saveNeighbourhoodBounds(NeighbourhoodBounds bounds) async {
    neighbourhoodBounds = bounds;
  }

  @override
  Future<NeighbourhoodBounds?> getNeighbourhoodBounds() async =>
      neighbourhoodBounds;

  @override
  Future<void> markFirstLaunchComplete() async {
    firstLaunchComplete = true;
  }

  @override
  Future<bool> isFirstLaunch() async => !firstLaunchComplete;

  @override
  Future<void> markFirstWalkContractCompleted() async {
    firstWalkContractCompleted = true;
  }

  @override
  Future<bool> isFirstWalkContractCompleted() async =>
      firstWalkContractCompleted;

  @override
  Future<void> markFirstWalkContractDismissed() async {
    firstWalkContractDismissed = true;
  }

  @override
  Future<bool> isFirstWalkContractDismissed() async =>
      firstWalkContractDismissed;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late InMemoryAppStateRepository appState;

  setUp(() {
    appState = InMemoryAppStateRepository();
  });

  group('SeedProfileLoader.fixtureFor', () {
    test('returns null for SeedProfile.none', () {
      expect(SeedProfileLoader.fixtureFor(SeedProfile.none), isNull);
    });

    test('returns EmptyFixture for SeedProfile.empty', () {
      final fixture = SeedProfileLoader.fixtureFor(SeedProfile.empty);
      expect(fixture, isA<EmptyFixture>());
    });

    test('returns OnboardingCompleteFixture for SeedProfile.onboardingComplete', () {
      final fixture = SeedProfileLoader.fixtureFor(SeedProfile.onboardingComplete);
      expect(fixture, isA<OnboardingCompleteFixture>());
    });

    test('returns a fixture for every active profile', () {
      for (final profile in SeedProfile.values) {
        if (profile == SeedProfile.none) continue;
        expect(
          SeedProfileLoader.fixtureFor(profile),
          isNotNull,
          reason: '$profile should have a fixture',
        );
      }
    });
  });

  group('SeedProfileLoader.load', () {
    test('returns none and does nothing when no profile set', () async {
      final result = await SeedProfileLoader.load(
        appStateRepository: appState,
        overrideProfile: SeedProfile.none,
      );

      expect(result, equals(SeedProfile.none));
      expect(appState.firstLaunchComplete, isFalse);
    });

    test('suppresses onboarding for onboardingComplete profile', () async {
      final result = await SeedProfileLoader.load(
        appStateRepository: appState,
        overrideProfile: SeedProfile.onboardingComplete,
      );

      expect(result, equals(SeedProfile.onboardingComplete));
      expect(appState.firstLaunchComplete, isTrue);
      expect(appState.firstWalkContractCompleted, isTrue);
      expect(appState.firstWalkContractDismissed, isTrue);
    });

    test('does NOT suppress onboarding for empty profile', () async {
      await SeedProfileLoader.load(
        appStateRepository: appState,
        overrideProfile: SeedProfile.empty,
      );

      expect(appState.firstLaunchComplete, isFalse);
    });

    test('seeds last position for onboardingComplete profile', () async {
      await SeedProfileLoader.load(
        appStateRepository: appState,
        overrideProfile: SeedProfile.onboardingComplete,
      );

      expect(appState.lastPosition, isNotNull);
      expect(appState.lastPosition!.latitude, closeTo(51.4769, 0.01));
    });

    test('does NOT seed last position for empty profile', () async {
      await SeedProfileLoader.load(
        appStateRepository: appState,
        overrideProfile: SeedProfile.empty,
      );

      expect(appState.lastPosition, isNull);
    });

    test('overrideProfile takes precedence over detect()', () async {
      // Even though detect() would return none (no env var in tests),
      // the override forces a specific profile.
      final result = await SeedProfileLoader.load(
        appStateRepository: appState,
        overrideProfile: SeedProfile.midProgress,
      );

      expect(result, equals(SeedProfile.midProgress));
      expect(appState.firstLaunchComplete, isTrue);
    });
  });

  group('SeedFixture properties', () {
    test('EmptyFixture does not suppress onboarding', () {
      const fixture = EmptyFixture();
      expect(fixture.suppressOnboarding, isFalse);
      expect(fixture.name, equals('empty'));
    });

    test('OnboardingCompleteFixture suppresses onboarding', () {
      const fixture = OnboardingCompleteFixture();
      expect(fixture.suppressOnboarding, isTrue);
      expect(fixture.name, equals('onboarding_complete'));
    });

    test('OnboardingCompleteFixture has a valid default position', () {
      expect(
        OnboardingCompleteFixture.defaultPosition.latitude,
        closeTo(51.4769, 0.01),
      );
      expect(
        OnboardingCompleteFixture.defaultPosition.longitude,
        closeTo(-0.0005, 0.01),
      );
    });

    test('OnboardingCompleteFixture exposes seedPosition', () {
      const fixture = OnboardingCompleteFixture();
      expect(fixture.seedPosition, isNotNull);
      expect(fixture.seedPosition!.latitude, closeTo(51.4769, 0.01));
    });

    test('EmptyFixture has null seedPosition', () {
      const fixture = EmptyFixture();
      expect(fixture.seedPosition, isNull);
    });

    test('EmptyFixture has empty walkedPaths', () {
      const fixture = EmptyFixture();
      expect(fixture.walkedPaths, isEmpty);
    });

    test('OnboardingCompleteFixture has empty walkedPaths by default', () {
      const fixture = OnboardingCompleteFixture();
      expect(fixture.walkedPaths, isEmpty);
    });
  });
}
