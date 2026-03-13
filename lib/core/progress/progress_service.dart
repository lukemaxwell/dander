import 'dart:async';

import 'package:flutter_map/flutter_map.dart' show LatLngBounds;

import '../fog/fog_grid.dart';
import 'badge.dart';
import 'streak_tracker.dart';

/// Domain service for exploration progress, badge unlocking, and streak tracking.
///
/// All methods return new objects — nothing is mutated in place.
class ProgressService {
  ProgressService();

  final _explorationController = StreamController<double>.broadcast();
  final _badgeController = StreamController<Badge>.broadcast();

  /// Emits the latest exploration fraction whenever it changes.
  Stream<double> get explorationStream => _explorationController.stream;

  /// Emits a [Badge] whenever a new badge is unlocked.
  Stream<Badge> get badgeStream => _badgeController.stream;

  // ---------------------------------------------------------------------------
  // Exploration percentage
  // ---------------------------------------------------------------------------

  /// Returns the fraction of [grid] cells within [neighbourhood] that are
  /// explored (0.0–1.0).
  ///
  /// Delegates to [FogGrid.explorationPercentage].
  double computeExplorationPct(FogGrid grid, LatLngBounds neighbourhood) =>
      grid.explorationPercentage(neighbourhood);

  // ---------------------------------------------------------------------------
  // Badge checking
  // ---------------------------------------------------------------------------

  /// Returns an updated badge list, unlocking any badges whose threshold has
  /// been reached for the first time.
  ///
  /// Already-unlocked badges keep their original [Badge.unlockedAt] timestamp.
  List<Badge> checkBadges(
    double explorationPct,
    List<Badge> currentBadges,
    DateTime now,
  ) {
    final updated = <Badge>[];
    for (final badge in currentBadges) {
      if (badge.isUnlocked) {
        // Already unlocked — preserve as-is
        updated.add(badge);
      } else if (_shouldUnlock(badge, explorationPct)) {
        final unlocked = badge.unlock(now);
        updated.add(unlocked);
        _badgeController.add(unlocked);
      } else {
        updated.add(badge);
      }
    }
    return updated;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Returns true if [badge] should be unlocked at [explorationPct].
  ///
  /// For the [BadgeId.firstDander] badge (requiredExplorationPct == 0.0) we
  /// require strictly positive exploration so it is awarded on the *first walk*,
  /// not on app launch before any walking has occurred.
  static bool _shouldUnlock(Badge badge, double explorationPct) {
    if (badge.requiredExplorationPct == 0.0) {
      return explorationPct > 0.0;
    }
    return explorationPct >= badge.requiredExplorationPct;
  }

  // ---------------------------------------------------------------------------
  // Streak
  // ---------------------------------------------------------------------------

  /// Delegates to [StreakTracker.recordWalk] and returns the new tracker.
  StreakTracker recordWalk(StreakTracker current, DateTime walkDate) =>
      current.recordWalk(walkDate);

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  void dispose() {
    _explorationController.close();
    _badgeController.close();
  }
}
