import 'package:dander/core/location/walk_session.dart';

/// Aggregated summary of walks for a single week.
///
/// Immutable value object. Use [WeeklySummary.fromWalks] to create from raw
/// walk sessions.
class WeeklySummary {
  const WeeklySummary({
    required this.weekStart,
    required this.totalWalks,
    required this.totalDistanceMetres,
    required this.totalDuration,
    required this.totalDiscoveries,
    required this.fogClearedPercent,
    required this.activeDays,
    required this.currentStreak,
  });

  /// The Monday that starts this week.
  final DateTime weekStart;

  /// Number of walks completed this week.
  final int totalWalks;

  /// Total distance walked in metres.
  final double totalDistanceMetres;

  /// Combined duration of all walks.
  final Duration totalDuration;

  /// Number of POI discoveries this week.
  final int totalDiscoveries;

  /// Current fog cleared percentage (cumulative, not just this week).
  final double fogClearedPercent;

  /// Number of unique days with at least one walk.
  final int activeDays;

  /// Current weekly streak count.
  final int currentStreak;

  /// Total distance in kilometres.
  double get totalDistanceKm => totalDistanceMetres / 1000.0;

  /// Estimated steps based on walk session stride calculation.
  int get estimatedSteps =>
      (totalDistanceMetres / WalkSession.strideMeters).round();

  /// Creates a [WeeklySummary] by aggregating a list of [WalkSession]s.
  factory WeeklySummary.fromWalks({
    required List<WalkSession> walks,
    required DateTime weekStart,
    required double fogClearedPercent,
    int currentStreak = 0,
    int totalDiscoveries = 0,
  }) {
    if (walks.isEmpty) {
      return WeeklySummary(
        weekStart: weekStart,
        totalWalks: 0,
        totalDistanceMetres: 0,
        totalDuration: Duration.zero,
        totalDiscoveries: totalDiscoveries,
        fogClearedPercent: fogClearedPercent,
        activeDays: 0,
        currentStreak: currentStreak,
      );
    }

    var totalDistance = 0.0;
    var totalDuration = Duration.zero;
    final uniqueDays = <int>{};

    for (final walk in walks) {
      totalDistance += walk.distanceMeters;
      totalDuration += walk.duration;
      uniqueDays.add(_dayKey(walk.startTime));
    }

    return WeeklySummary(
      weekStart: weekStart,
      totalWalks: walks.length,
      totalDistanceMetres: totalDistance,
      totalDuration: totalDuration,
      totalDiscoveries: totalDiscoveries,
      fogClearedPercent: fogClearedPercent,
      activeDays: uniqueDays.length,
      currentStreak: currentStreak,
    );
  }

  /// Returns a unique integer key for the day of a DateTime.
  static int _dayKey(DateTime dt) => dt.year * 10000 + dt.month * 100 + dt.day;
}
