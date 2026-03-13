import 'dart:convert';

import 'package:hive/hive.dart';

import 'badge.dart';
import 'streak_tracker.dart';

/// Abstract interface for persisting exploration progress data.
abstract class ProgressRepository {
  Future<void> saveBadges(List<Badge> badges);
  Future<List<Badge>> loadBadges();

  Future<void> saveStreak(StreakTracker streak);
  Future<StreakTracker> loadStreak();
}

/// Hive-backed implementation of [ProgressRepository].
///
/// Badges are stored as a JSON string under [badgesKey].
/// The streak is stored as a JSON string under [streakKey].
class HiveProgressRepository implements ProgressRepository {
  HiveProgressRepository({String boxName = 'progress'})
      : _box = null,
        _boxName = boxName;

  /// Constructor that injects an already-open [Box] — used in tests.
  HiveProgressRepository.withBox(Box<dynamic> box)
      : _box = box,
        _boxName = 'progress';

  static const String badgesKey = 'badges';
  static const String streakKey = 'streak';

  final Box<dynamic>? _box;
  final String _boxName;

  Future<Box<dynamic>> _openBox() async {
    if (_box != null) return _box!;
    if (Hive.isBoxOpen(_boxName)) return Hive.box(_boxName);
    return Hive.openBox(_boxName);
  }

  // ---------------------------------------------------------------------------
  // Badges
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveBadges(List<Badge> badges) async {
    final box = await _openBox();
    final encoded = jsonEncode(badges.map((b) => b.toJson()).toList());
    await box.put(badgesKey, encoded);
  }

  @override
  Future<List<Badge>> loadBadges() async {
    final box = await _openBox();
    final raw = box.get(badgesKey);
    if (raw == null) return [];

    try {
      final list = jsonDecode(raw as String) as List<dynamic>;
      final definitions = {
        for (final b in BadgeDefinitions.badges) b.id.name: b
      };
      final result = <Badge>[];
      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final idName = map['id'] as String?;
        if (idName == null) continue;
        final definition = definitions[idName];
        if (definition == null) continue;
        result.add(Badge.fromJson(map, definition));
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Streak
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveStreak(StreakTracker streak) async {
    final box = await _openBox();
    final encoded = jsonEncode(streak.toJson());
    await box.put(streakKey, encoded);
  }

  @override
  Future<StreakTracker> loadStreak() async {
    final box = await _openBox();
    final raw = box.get(streakKey);
    if (raw == null) return StreakTracker.empty();

    try {
      final map = jsonDecode(raw as String) as Map<String, dynamic>;
      return StreakTracker.fromJson(map);
    } catch (_) {
      return StreakTracker.empty();
    }
  }
}
