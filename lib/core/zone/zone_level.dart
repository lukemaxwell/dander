/// XP thresholds and radius mapping for the zone progression system.
///
/// Levels expand the explorable fog radius:
///   L1 (0–99 XP)    → 500 m
///   L2 (100–299 XP)  → 1.5 km
///   L3 (300–699 XP)  → 3 km
///   L4 (700–1499 XP) → 8 km
///   L5 (1500+ XP)    → unlimited (100 km cap for practical purposes)
class ZoneLevel {
  ZoneLevel._();

  /// XP awarded for walking a new street.
  static const int xpPerStreet = 10;

  /// XP awarded for a correct quiz answer.
  static const int xpPerQuizCorrect = 5;

  /// Bonus XP per correct answer beyond a 3-answer streak.
  static const int xpPerStreakBonus = 2;

  /// XP awarded for discovering a POI.
  static const int xpPerPoi = 50;

  /// Ordered level definitions: (minXp, radiusMeters).
  static const List<(int, double)> _levels = [
    (0, 500.0),
    (100, 1500.0),
    (300, 3000.0),
    (700, 8000.0),
    (1500, 100000.0),
  ];

  /// Returns the 1-based level for the given [xp].
  static int levelForXp(int xp) {
    var level = 1;
    for (var i = 1; i < _levels.length; i++) {
      if (xp >= _levels[i].$1) {
        level = i + 1;
      }
    }
    return level;
  }

  /// Returns the fog radius in meters for the given [xp].
  static double radiusForXp(int xp) {
    final level = levelForXp(xp);
    return _levels[level - 1].$2;
  }

  /// Returns the XP threshold to reach the next level, or `null` if at max.
  static int? xpForNextLevel(int xp) {
    final level = levelForXp(xp);
    if (level >= _levels.length) return null;
    return _levels[level].$1;
  }
}
