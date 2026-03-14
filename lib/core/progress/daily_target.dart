/// Tracks daily exploration target progress.
///
/// Resets at midnight local time. Immutable — all mutations return new
/// instances.
class DailyTarget {
  const DailyTarget({
    required this.streetsToday,
    required this.target,
    required this.lastResetDate,
  });

  /// Creates an empty target for today.
  factory DailyTarget.empty() => DailyTarget(
        streetsToday: 0,
        target: 1,
        lastResetDate: DateTime.now(),
      );

  /// Streets walked today.
  final int streetsToday;

  /// Daily street target (default 1).
  final int target;

  /// Last date the counter was reset.
  final DateTime lastResetDate;

  /// Progress fraction (0.0–1.0), clamped.
  double get progress =>
      target <= 0 ? 1.0 : (streetsToday / target).clamp(0.0, 1.0);

  /// Whether the target has been met.
  bool get isComplete => streetsToday >= target;

  /// Whether the counter needs resetting (new calendar day).
  bool needsReset(DateTime now) {
    return now.year != lastResetDate.year ||
        now.month != lastResetDate.month ||
        now.day != lastResetDate.day;
  }

  /// Returns a reset instance if a new day, otherwise returns unchanged copy.
  DailyTarget resetIfNeeded(DateTime now) {
    if (!needsReset(now)) {
      return DailyTarget(
        streetsToday: streetsToday,
        target: target,
        lastResetDate: lastResetDate,
      );
    }
    return DailyTarget(
      streetsToday: 0,
      target: target,
      lastResetDate: now,
    );
  }

  /// Returns a new instance with streetsToday incremented by 1.
  DailyTarget increment() => DailyTarget(
        streetsToday: streetsToday + 1,
        target: target,
        lastResetDate: lastResetDate,
      );

  Map<String, dynamic> toJson() => {
        'streetsToday': streetsToday,
        'target': target,
        'lastResetDate': lastResetDate.toIso8601String(),
      };

  factory DailyTarget.fromJson(Map<String, dynamic> json) => DailyTarget(
        streetsToday: json['streetsToday'] as int? ?? 0,
        target: json['target'] as int? ?? 1,
        lastResetDate: json['lastResetDate'] != null
            ? DateTime.parse(json['lastResetDate'] as String)
            : DateTime.now(),
      );
}
