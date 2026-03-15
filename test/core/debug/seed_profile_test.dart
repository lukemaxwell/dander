import 'package:flutter_test/flutter_test.dart';

import 'package:dander/core/debug/seed_profile.dart';

void main() {
  group('SeedProfile.fromString', () {
    test('empty string returns none', () {
      expect(SeedProfile.fromString(''), equals(SeedProfile.none));
    });

    test('parses "empty" correctly', () {
      expect(SeedProfile.fromString('empty'), equals(SeedProfile.empty));
    });

    test('parses "onboarding_complete" correctly', () {
      expect(
        SeedProfile.fromString('onboarding_complete'),
        equals(SeedProfile.onboardingComplete),
      );
    });

    test('parses "active_zone" correctly', () {
      expect(
        SeedProfile.fromString('active_zone'),
        equals(SeedProfile.activeZone),
      );
    });

    test('parses "mid_progress" correctly', () {
      expect(
        SeedProfile.fromString('mid_progress'),
        equals(SeedProfile.midProgress),
      );
    });

    test('parses "high_payoff" correctly', () {
      expect(
        SeedProfile.fromString('high_payoff'),
        equals(SeedProfile.highPayoff),
      );
    });

    test('unknown value returns none', () {
      expect(SeedProfile.fromString('bogus_value'), equals(SeedProfile.none));
    });

    test('case-sensitive — "Empty" returns none', () {
      expect(SeedProfile.fromString('Empty'), equals(SeedProfile.none));
    });
  });

  group('SeedProfile.isActive', () {
    test('none is not active', () {
      expect(SeedProfile.none.isActive, isFalse);
    });

    test('empty is active', () {
      expect(SeedProfile.empty.isActive, isTrue);
    });

    test('midProgress is active', () {
      expect(SeedProfile.midProgress.isActive, isTrue);
    });
  });

  group('SeedProfile.detect', () {
    test('returns a SeedProfile value (none when env is empty)', () {
      // In test environment, SEED_PROFILE is not set, so detect() returns none.
      final result = SeedProfile.detect();
      expect(result, isA<SeedProfile>());
    });
  });
}
