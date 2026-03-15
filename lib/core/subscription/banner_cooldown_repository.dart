import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Hive box key for the dismissal timestamp.
const _kDismissedAtKey = 'dismissed_at';

/// Duration after which the banner cooldown expires (48 hours).
const _kCooldownDuration = Duration(hours: 48);

/// Persists the last-dismissed timestamp for the zone-expansion banner.
///
/// The banner is suppressed for 48 hours after the user dismisses it.
/// All reads return new immutable values — no in-place mutation.
class BannerCooldownRepository {
  BannerCooldownRepository({
    DateTime Function()? clock,
  }) : _box = Hive.box<dynamic>(
          // Hive.box is synchronous once the box is already open.
          'banner_cooldown',
        ),
       _clock = clock ?? DateTime.now;

  /// Test constructor — accepts an already-open [Box].
  @visibleForTesting
  BannerCooldownRepository.withBox(Box<dynamic> box, {DateTime Function()? clock})
      : _box = box,
        _clock = clock ?? DateTime.now;

  final dynamic _box; // Box<dynamic> — typed loosely to avoid Hive import leak
  final DateTime Function() _clock;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns `true` when the user dismissed the banner within the last 48 hours.
  bool isOnCooldown() {
    final raw = (_box as Box<dynamic>).get(_kDismissedAtKey);
    if (raw == null) return false;

    final dismissedAt =
        DateTime.fromMillisecondsSinceEpoch((raw as num).toInt());
    final elapsed = _clock().difference(dismissedAt);
    return elapsed < _kCooldownDuration;
  }

  /// Records the current time as the last-dismissal timestamp.
  ///
  /// Subsequent [isOnCooldown] calls will return `true` for 48 hours.
  void markDismissed() {
    (_box as Box<dynamic>)
        .put(_kDismissedAtKey, _clock().millisecondsSinceEpoch);
  }

  /// Clears the stored timestamp so [isOnCooldown] returns `false`.
  ///
  /// Only intended for test helpers and developer tooling — do not call in
  /// production code paths.
  void resetForTest() {
    (_box as Box<dynamic>).delete(_kDismissedAtKey);
  }
}
