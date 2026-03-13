/// Immutable daily quiz session streak tracker.
///
/// A "week" is an ISO 8601 week (Monday–Sunday).  The streak increments when
/// the user completes at least one quiz session per calendar week, in
/// consecutive weeks.
///
/// Identical logic to [StreakTracker] in `lib/core/progress/streak_tracker.dart`,
/// adapted for quiz sessions (sessions instead of walks, daily active check).
class QuizStreakTracker {
  const QuizStreakTracker({
    required this.currentStreak,
    required this.lastSessionDate,
  });

  factory QuizStreakTracker.empty() =>
      const QuizStreakTracker(currentStreak: 0, lastSessionDate: null);

  final int currentStreak;
  final DateTime? lastSessionDate;

  // ---------------------------------------------------------------------------
  // Week logic (shared with StreakTracker)
  // ---------------------------------------------------------------------------

  static int _isoWeek(DateTime date) {
    final thursday = date.add(Duration(days: 4 - date.weekday));
    final jan1 = DateTime(thursday.year, 1, 1);
    return ((thursday.difference(jan1).inDays) ~/ 7) + 1;
  }

  static int _isoYear(DateTime date) {
    final thursday = date.add(Duration(days: 4 - date.weekday));
    return thursday.year;
  }

  static (int, int) _yearWeek(DateTime date) => (_isoYear(date), _isoWeek(date));

  static DateTime _mondayOf(DateTime date) =>
      date.subtract(Duration(days: date.weekday - 1));

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Records a quiz session on [sessionDate] and returns an updated tracker.
  QuizStreakTracker recordSession(DateTime sessionDate) {
    if (lastSessionDate == null) {
      return QuizStreakTracker(currentStreak: 1, lastSessionDate: sessionDate);
    }

    final (lastYear, lastWeek) = _yearWeek(lastSessionDate!);
    final (sessionYear, sessionWeek) = _yearWeek(sessionDate);

    if (lastYear == sessionYear && lastWeek == sessionWeek) {
      return QuizStreakTracker(
          currentStreak: currentStreak, lastSessionDate: sessionDate);
    }

    final lastMonday = _mondayOf(lastSessionDate!);
    final sessionMonday = _mondayOf(sessionDate);
    final weekDiff = sessionMonday.difference(lastMonday).inDays ~/ 7;

    if (weekDiff == 1) {
      return QuizStreakTracker(
          currentStreak: currentStreak + 1, lastSessionDate: sessionDate);
    }

    return QuizStreakTracker(currentStreak: 1, lastSessionDate: sessionDate);
  }

  /// True if the user has completed a quiz session today.
  bool get isActiveToday {
    if (lastSessionDate == null) return false;
    final today = DateTime.now();
    return lastSessionDate!.year == today.year &&
        lastSessionDate!.month == today.month &&
        lastSessionDate!.day == today.day;
  }

  /// True if the streak is at risk: the last session was in the previous ISO
  /// week and no session has been completed this week yet.
  bool get isAtRisk {
    if (lastSessionDate == null) return false;
    if (isActiveToday) return false;

    final nowMonday = _mondayOf(DateTime.now());
    final lastMonday = _mondayOf(lastSessionDate!);
    final weeksBehind = nowMonday.difference(lastMonday).inDays ~/ 7;

    // Check if in same week (would be active this week, already handled)
    final (nowYear, nowWeek) = _yearWeek(DateTime.now());
    final (lastYear, lastWeek) = _yearWeek(lastSessionDate!);
    if (nowYear == lastYear && nowWeek == lastWeek) return false;

    return weeksBehind == 1;
  }

  // ---------------------------------------------------------------------------
  // Serialisation
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toJson() => {
        'currentStreak': currentStreak,
        'lastSessionDate': lastSessionDate?.toIso8601String(),
      };

  factory QuizStreakTracker.fromJson(Map<String, dynamic> json) {
    final raw = json['lastSessionDate'] as String?;
    return QuizStreakTracker(
      currentStreak: (json['currentStreak'] as num).toInt(),
      lastSessionDate: raw != null ? DateTime.parse(raw) : null,
    );
  }
}
