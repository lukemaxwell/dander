/// Central registry of all Hive box names used by the app.
///
/// Using named constants prevents typo-based bugs and makes it easy to find
/// all storage locations in one place.
abstract final class HiveBoxes {
  /// Stores the fog-of-war grid state (explored / unexplored cells).
  static const String fogState = 'fog_state';

  /// Stores walk history entries.
  static const String walks = 'walk_history';

  /// Stores discovered POI records.
  static const String discoveries = 'discoveries';

  /// Stores exploration progress metrics (percentage, streaks, badges).
  static const String progress = 'progress';

  /// Stores lightweight app-level state (last position, neighbourhood bounds,
  /// first-launch flag, etc.).
  static const String appState = 'app_state';

  /// Stores street data and walked-state records.
  static const String streets = 'streets';

  /// Stores spaced-repetition memory records for the street quiz.
  static const String quiz = 'quiz';
}
