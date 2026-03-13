/// Immutable weekly streak tracker.
///
/// A "week" is an ISO 8601 week (Monday–Sunday).  The streak increments when
/// the user records at least one walk per calendar week, in consecutive weeks.
class StreakTracker {
  const StreakTracker({
    required this.currentStreak,
    required this.lastWalkDate,
  });

  factory StreakTracker.empty() =>
      const StreakTracker(currentStreak: 0, lastWalkDate: null);

  final int currentStreak;
  final DateTime? lastWalkDate;

  // ---------------------------------------------------------------------------
  // Week logic
  // ---------------------------------------------------------------------------

  /// ISO week number (1–53) for [date].
  static int _isoWeek(DateTime date) {
    // Algorithm: the ISO week number is based on the Thursday of the week.
    final thursday = date.add(Duration(days: 4 - date.weekday));
    final jan1 = DateTime(thursday.year, 1, 1);
    return ((thursday.difference(jan1).inDays) ~/ 7) + 1;
  }

  /// ISO year for [date] (may differ from calendar year near year-end).
  static int _isoYear(DateTime date) {
    final thursday = date.add(Duration(days: 4 - date.weekday));
    return thursday.year;
  }

  /// Returns `(isoYear, isoWeek)` pair for [date].
  static (int, int) _yearWeek(DateTime date) =>
      (_isoYear(date), _isoWeek(date));

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Records a walk on [walkDate] and returns an updated [StreakTracker].
  StreakTracker recordWalk(DateTime walkDate) {
    if (lastWalkDate == null) {
      // First ever walk
      return StreakTracker(currentStreak: 1, lastWalkDate: walkDate);
    }

    final (lastYear, lastWeek) = _yearWeek(lastWalkDate!);
    final (walkYear, walkWeek) = _yearWeek(walkDate);

    if (lastYear == walkYear && lastWeek == walkWeek) {
      // Same week — update date but keep streak the same
      return StreakTracker(
          currentStreak: currentStreak, lastWalkDate: walkDate);
    }

    // Check if the walk week is exactly one week after the last walk week
    final lastMonday = _mondayOf(lastWalkDate!);
    final walkMonday = _mondayOf(walkDate);
    final weekDiff = walkMonday.difference(lastMonday).inDays ~/ 7;

    if (weekDiff == 1) {
      // Consecutive week — increment streak
      return StreakTracker(
          currentStreak: currentStreak + 1, lastWalkDate: walkDate);
    }

    // Gap in weeks — reset streak
    return StreakTracker(currentStreak: 1, lastWalkDate: walkDate);
  }

  /// Returns the Monday of the week containing [date].
  static DateTime _mondayOf(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  /// True if the user has walked in the current ISO week.
  bool get isActiveThisWeek {
    if (lastWalkDate == null) return false;
    final (nowYear, nowWeek) = _yearWeek(DateTime.now());
    final (lastYear, lastWeek) = _yearWeek(lastWalkDate!);
    return lastYear == nowYear && lastWeek == nowWeek;
  }

  /// True if the streak is at risk: the last walk was in the previous ISO week
  /// and no walk has been recorded this week yet.
  ///
  /// Returns `false` if the streak is already broken (2+ weeks missed) or if
  /// the user has already walked this week.
  bool get isAtRisk {
    if (lastWalkDate == null) return false;
    if (isActiveThisWeek) return false;

    final nowMonday = _mondayOf(DateTime.now());
    final lastMonday = _mondayOf(lastWalkDate!);
    final weeksBehind = nowMonday.difference(lastMonday).inDays ~/ 7;

    // At risk only when exactly 1 week behind
    return weeksBehind == 1;
  }

  // ---------------------------------------------------------------------------
  // Utility
  // ---------------------------------------------------------------------------

  StreakTracker copyWith({int? currentStreak, DateTime? lastWalkDate}) =>
      StreakTracker(
        currentStreak: currentStreak ?? this.currentStreak,
        lastWalkDate: lastWalkDate ?? this.lastWalkDate,
      );

  Map<String, dynamic> toJson() => {
        'currentStreak': currentStreak,
        'lastWalkDate': lastWalkDate?.toIso8601String(),
      };

  factory StreakTracker.fromJson(Map<String, dynamic> json) {
    final raw = json['lastWalkDate'] as String?;
    return StreakTracker(
      currentStreak: (json['currentStreak'] as num).toInt(),
      lastWalkDate: raw != null ? DateTime.parse(raw) : null,
    );
  }
}
