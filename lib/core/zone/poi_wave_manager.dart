import 'dart:math' as math;

import 'mystery_poi.dart';

/// Pure, stateless helper that manages wave-based POI activation.
///
/// Full curated set (~20 POIs) is stored per zone. POIs are drip-fed:
///   - Wave 1: first [wave1Size] POIs become active.
///   - Wave 2: next [wave2Size] POIs activate when ≥50% of wave 1 is discovered.
///   - Wave 3: remaining POIs activate when ≥50% of wave 2 is discovered.
///
/// No state is held here — the caller owns and persists wave state.
class PoiWaveManager {
  PoiWaveManager._();

  /// Number of POIs active in wave 1.
  static const int wave1Size = 8;

  /// Number of additional POIs that activate in wave 2.
  static const int wave2Size = 6;

  /// Fraction of the current wave that must be discovered to unlock the next.
  static const double unlockThresholdPercent = 0.5;

  /// Maximum wave number — no wave beyond this is created.
  static const int maxWave = 3;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns the slice of [allPois] that should be active for [currentWave].
  ///
  /// - Wave 1 → first [wave1Size] entries (or all if fewer).
  /// - Wave 2 → first wave1Size + wave2Size entries cumulatively.
  /// - Wave 3+ → all entries.
  ///
  /// The original [allPois] list is never mutated.
  static List<MysteryPoi> activeForWave(
    List<MysteryPoi> allPois,
    int currentWave,
  ) {
    if (allPois.isEmpty) return const [];

    final cutoff = _cumulativeSize(currentWave, allPois.length);
    return List<MysteryPoi>.unmodifiable(allPois.take(cutoff).toList());
  }

  /// Returns the new wave number after checking whether the unlock threshold
  /// has been met.
  ///
  /// If [discoveredInWave] ≥ 50% of [waveSize], advances to the next wave
  /// (capped at [maxWave]).  Otherwise returns [currentWave] unchanged.
  ///
  /// [waveSize] is the number of POIs in the *current* wave — use [waveSize]
  /// to compute it, or pass the value directly.
  static int checkWaveUnlock(
    int currentWave,
    int discoveredInWave,
    int waveSize,
  ) {
    if (currentWave >= maxWave) return maxWave;
    if (waveSize == 0) return currentWave;

    final threshold = (waveSize * unlockThresholdPercent).ceil();
    if (discoveredInWave >= threshold) {
      return math.min(currentWave + 1, maxWave);
    }

    return currentWave;
  }

  /// Returns the number of POIs belonging *exclusively* to [wave].
  ///
  /// For wave 3, returns [maxInt] as a sentinel — the caller should use
  /// `allPois.length - wave1Size - wave2Size` for the actual count.
  static int waveSize(int wave) {
    switch (wave) {
      case 1:
        return wave1Size;
      case 2:
        return wave2Size;
      default:
        return (1 << 30); // effectively unlimited sentinel
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// The cumulative number of POIs active up to and including [wave],
  /// clamped to [total].
  static int _cumulativeSize(int wave, int total) {
    if (wave <= 1) return math.min(wave1Size, total);
    if (wave == 2) return math.min(wave1Size + wave2Size, total);
    return total; // wave 3+ → all
  }
}
