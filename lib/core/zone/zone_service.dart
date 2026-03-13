import 'package:latlong2/latlong.dart';

import 'zone.dart';
import 'zone_level.dart';
import 'zone_repository.dart';

/// Domain service for awarding XP to zones and locating the active zone.
///
/// All zone mutations produce new [Zone] objects — nothing is mutated in place.
///
/// The service maintains an in-memory quiz streak counter per zone so that
/// callers can determine whether a streak bonus should be applied before
/// calling [awardQuizXp].
class ZoneService {
  ZoneService({required ZoneRepository repository}) : _repository = repository;

  final ZoneRepository _repository;

  /// In-memory quiz streak counts keyed by zone id.
  final Map<String, int> _quizStreaks = {};

  /// Maximum distance in meters for a zone to be considered "active".
  static const double _activeZoneRadiusMeters = 50000.0;

  // ---------------------------------------------------------------------------
  // XP award methods
  // ---------------------------------------------------------------------------

  /// Awards [ZoneLevel.xpPerStreet] XP to the zone with [zoneId].
  ///
  /// Loads the zone, adds XP, persists the updated zone, and returns it.
  ///
  /// Throws [StateError] if no zone with [zoneId] exists in the repository.
  Future<Zone> awardStreetXp(String zoneId) async {
    return _awardXp(zoneId, ZoneLevel.xpPerStreet);
  }

  /// Awards quiz XP to the zone with [zoneId].
  ///
  /// Adds [ZoneLevel.xpPerQuizCorrect] and, when [isStreakBonus] is `true`,
  /// an additional [ZoneLevel.xpPerStreakBonus].
  ///
  /// Throws [StateError] if no zone with [zoneId] exists in the repository.
  Future<Zone> awardQuizXp(
    String zoneId, {
    required bool isStreakBonus,
  }) async {
    final amount = isStreakBonus
        ? ZoneLevel.xpPerQuizCorrect + ZoneLevel.xpPerStreakBonus
        : ZoneLevel.xpPerQuizCorrect;
    return _awardXp(zoneId, amount);
  }

  /// Awards [ZoneLevel.xpPerPoi] XP to the zone with [zoneId].
  ///
  /// Throws [StateError] if no zone with [zoneId] exists in the repository.
  Future<Zone> awardPoiXp(String zoneId) async {
    return _awardXp(zoneId, ZoneLevel.xpPerPoi);
  }

  // ---------------------------------------------------------------------------
  // Quiz streak management
  // ---------------------------------------------------------------------------

  /// Returns the current consecutive-correct quiz answer count for [zoneId].
  int quizStreakFor(String zoneId) => _quizStreaks[zoneId] ?? 0;

  /// Increments the quiz streak counter for [zoneId] by 1.
  void incrementQuizStreak(String zoneId) {
    _quizStreaks[zoneId] = quizStreakFor(zoneId) + 1;
  }

  /// Resets the quiz streak counter for [zoneId] to 0 (call on wrong answer).
  void resetQuizStreak(String zoneId) {
    _quizStreaks[zoneId] = 0;
  }

  /// Returns `true` if the streak bonus is currently active for [zoneId].
  ///
  /// The streak bonus activates once the player has answered more than 3
  /// consecutive questions correctly (i.e. streak count > 3).
  bool isStreakBonusActive(String zoneId) => quizStreakFor(zoneId) > 3;

  // ---------------------------------------------------------------------------
  // Active zone lookup
  // ---------------------------------------------------------------------------

  /// Returns the closest zone to [position] that is within 50 km, or `null`.
  ///
  /// When multiple zones are within range the one with the smallest
  /// Haversine distance to [position] is returned.
  Future<Zone?> getActiveZone(LatLng position) async {
    final zones = await _repository.loadAll();
    if (zones.isEmpty) return null;

    const distance = Distance();

    Zone? closest;
    double closestMeters = double.infinity;

    for (final zone in zones) {
      final meters = distance.as(
        LengthUnit.Meter,
        position,
        zone.centre,
      );
      if (meters <= _activeZoneRadiusMeters && meters < closestMeters) {
        closest = zone;
        closestMeters = meters;
      }
    }

    return closest;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Loads zone [zoneId], adds [amount] XP, saves it, and returns the result.
  Future<Zone> _awardXp(String zoneId, int amount) async {
    final zone = await _repository.load(zoneId);
    if (zone == null) {
      throw StateError('Zone "$zoneId" not found in repository.');
    }
    final updated = zone.addXp(amount);
    await _repository.save(updated);
    return updated;
  }
}
