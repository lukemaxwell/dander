import 'zone.dart';

/// An immutable value object representing a zone level-up event.
///
/// Created by [LevelUpDetector.checkLevelUp] when a zone transitions
/// from one level to a higher one.
class LevelUpEvent {
  const LevelUpEvent({
    required this.previousLevel,
    required this.newLevel,
    required this.newRadiusMeters,
  });

  /// The level the zone held before the XP award.
  final int previousLevel;

  /// The new level the zone has reached.
  final int newLevel;

  /// The fog reveal radius (in meters) at [newLevel].
  final double newRadiusMeters;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LevelUpEvent &&
          runtimeType == other.runtimeType &&
          previousLevel == other.previousLevel &&
          newLevel == other.newLevel &&
          newRadiusMeters == other.newRadiusMeters;

  @override
  int get hashCode =>
      previousLevel.hashCode ^ newLevel.hashCode ^ newRadiusMeters.hashCode;

  @override
  String toString() =>
      'LevelUpEvent(previousLevel: $previousLevel, newLevel: $newLevel, '
      'newRadiusMeters: $newRadiusMeters)';
}

/// Pure utility for detecting zone level-up transitions.
///
/// Has no dependencies and no side effects — suitable for use anywhere.
abstract final class LevelUpDetector {
  /// Compares [before] and [after] zones and returns a [LevelUpEvent] if the
  /// zone level increased, or `null` if the level stayed the same.
  ///
  /// A level decrease (e.g. data correction) never produces an event.
  static LevelUpEvent? checkLevelUp(Zone before, Zone after) {
    final previousLevel = before.level;
    final newLevel = after.level;

    if (newLevel <= previousLevel) return null;

    return LevelUpEvent(
      previousLevel: previousLevel,
      newLevel: newLevel,
      newRadiusMeters: after.radiusMeters,
    );
  }
}
