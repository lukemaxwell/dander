import 'dart:convert';

import 'package:hive/hive.dart';

import '../storage/hive_boxes.dart';
import 'challenge.dart';

/// Abstract interface for persisting weekly challenge data.
abstract class ChallengeRepository {
  /// Loads the current weekly challenges, returning empty list if none stored.
  Future<List<Challenge>> loadWeeklyChallenges();

  /// Saves the current weekly challenges.
  Future<void> saveWeeklyChallenges(List<Challenge> challenges);

  /// Loads the stored week number (for rotation detection).
  Future<int> loadWeekNumber();

  /// Saves the current week number.
  Future<void> saveWeekNumber(int weekNumber);
}

/// Hive-backed implementation of [ChallengeRepository].
class HiveChallengeRepository implements ChallengeRepository {
  HiveChallengeRepository({String boxName = HiveBoxes.challenges})
      : _box = null,
        _boxName = boxName;

  /// Constructor that injects an already-open [Box] — used in tests.
  HiveChallengeRepository.withBox(Box<dynamic> box)
      : _box = box,
        _boxName = HiveBoxes.challenges;

  static const String _challengesKey = 'weekly_challenges';
  static const String _weekNumberKey = 'week_number';

  final Box<dynamic>? _box;
  final String _boxName;

  Future<Box<dynamic>> _openBox() async {
    if (_box != null) return _box!;
    if (Hive.isBoxOpen(_boxName)) return Hive.box(_boxName);
    return Hive.openBox(_boxName);
  }

  @override
  Future<List<Challenge>> loadWeeklyChallenges() async {
    final box = await _openBox();
    final raw = box.get(_challengesKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw as String) as List<dynamic>;
      return list
          .map((e) => Challenge.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveWeeklyChallenges(List<Challenge> challenges) async {
    final box = await _openBox();
    final json = challenges.map((c) => c.toJson()).toList();
    await box.put(_challengesKey, jsonEncode(json));
  }

  @override
  Future<int> loadWeekNumber() async {
    final box = await _openBox();
    final raw = box.get(_weekNumberKey);
    if (raw == null) return 0;
    return raw as int;
  }

  @override
  Future<void> saveWeekNumber(int weekNumber) async {
    final box = await _openBox();
    await box.put(_weekNumberKey, weekNumber);
  }
}
