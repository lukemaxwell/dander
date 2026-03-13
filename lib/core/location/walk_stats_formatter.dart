/// Utility class for formatting walk statistics into human-readable strings.
///
/// All methods are pure static functions — no state, no instantiation needed.
class WalkStatsFormatter {
  WalkStatsFormatter._();

  /// Formats a [Duration] into a compact human-readable string.
  ///
  /// - When duration < 1 hour: returns `"Xm Ys"` (e.g. `"45m 12s"`).
  /// - When duration >= 1 hour: returns `"Xh Ym"` (seconds omitted, e.g. `"1h 23m"`).
  static String formatDuration(Duration d) {
    final totalSeconds = d.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m ${seconds}s';
  }

  /// Formats a distance in metres.
  ///
  /// - When distance < 1000 m: returns `"X m"` (integer, e.g. `"450 m"`).
  /// - When distance >= 1000 m: returns `"X.Y km"` (1 decimal place, e.g. `"1.2 km"`).
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    final km = meters / 1000;
    return '${km.toStringAsFixed(1)} km';
  }

  /// Formats a fog-cleared percentage with 1 decimal place.
  ///
  /// Example: `12.3456` → `"12.3%"`.
  static String formatFogCleared(double percent) {
    return '${percent.toStringAsFixed(1)}%';
  }
}
