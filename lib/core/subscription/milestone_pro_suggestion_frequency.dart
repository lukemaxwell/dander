import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import 'package:dander/core/storage/hive_boxes.dart';

/// Hive box key for the milestone-trigger counter.
const _kCounterKey = 'milestone_count';

/// Determines whether the Pro-suggestion card should appear on the next
/// milestone event.
///
/// Strategy: show the card on every ODD milestone (1st, 3rd, 5th, …).
/// The counter starts at 0 (before any milestone) so:
///   - count 0 → shouldShow = false  (no milestones yet)
///   - count 1 → shouldShow = true   (1st milestone)
///   - count 2 → shouldShow = false  (2nd milestone)
///   - count 3 → shouldShow = true   (3rd milestone)
///   … and so on.
///
/// [record] increments the counter and must be called every time a milestone
/// fires (whether or not the Pro card was ultimately shown).
/// [shouldShow] reads the current counter without changing it.
class MilestoneProSuggestionFrequency {
  /// Production constructor — opens the default Hive box.
  MilestoneProSuggestionFrequency()
      : _box = Hive.box<dynamic>(HiveBoxes.milestoneProFrequency);

  /// Test/injection constructor — accepts an already-open [Box].
  @visibleForTesting
  MilestoneProSuggestionFrequency.withBox(Box<dynamic> box) : _box = box;

  final Box<dynamic> _box;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns `true` when the Pro card should be shown at this milestone.
  ///
  /// Odd counts (1, 3, 5, …) → true.
  /// Even counts including 0 (0, 2, 4, …) → false.
  bool shouldShow() {
    final count = _count;
    return count > 0 && count.isOdd;
  }

  /// Increments the stored milestone counter.
  ///
  /// Call this every time a milestone event fires, regardless of whether the
  /// Pro card is displayed.
  void record() {
    _box.put(_kCounterKey, _count + 1);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  int get _count {
    final raw = _box.get(_kCounterKey);
    if (raw == null) return 0;
    return (raw as num).toInt();
  }
}
