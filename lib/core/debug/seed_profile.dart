import 'package:flutter/foundation.dart';

/// Named seed profiles for deterministic app states.
///
/// Supplied via `--dart-define=SEED_PROFILE=<name>` at build time.
/// Only active in debug builds — release builds always return [none].
enum SeedProfile {
  none,
  empty,
  onboardingComplete,
  activeZone,
  midProgress,
  highPayoff;

  /// The raw `--dart-define` value, or empty string in release builds.
  static const String _envValue = String.fromEnvironment('SEED_PROFILE');

  /// Returns the [SeedProfile] matching the `SEED_PROFILE` env var,
  /// or [SeedProfile.none] if unset or unrecognised.
  ///
  /// Disabled in release builds only — works in both debug and profile mode
  /// so marketing screenshots can be captured on physical devices.
  static SeedProfile detect() {
    if (kReleaseMode) return none;
    return fromString(_envValue);
  }

  /// Parses a profile name string into a [SeedProfile].
  ///
  /// Returns [SeedProfile.none] for empty or unrecognised values.
  /// Logs a warning for unrecognised non-empty values.
  static SeedProfile fromString(String value) {
    if (value.isEmpty) return none;
    switch (value) {
      case 'empty':
        return empty;
      case 'onboarding_complete':
        return onboardingComplete;
      case 'active_zone':
        return activeZone;
      case 'mid_progress':
        return midProgress;
      case 'high_payoff':
        return highPayoff;
      default:
        debugPrint('SeedProfile: unknown profile "$value", ignoring.');
        return none;
    }
  }

  /// Whether a seed profile is active (anything other than [none]).
  bool get isActive => this != none;
}
