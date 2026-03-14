import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:dander/core/challenges/challenge.dart';
import 'package:dander/core/challenges/challenge_repository.dart';

void main() {
  late Box<dynamic> box;
  late HiveChallengeRepository repo;

  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('challenge_repo_test');
    Hive.init(dir.path);
    box = await Hive.openBox('test_challenges');
    repo = HiveChallengeRepository.withBox(box);
  });

  tearDown(() async {
    await box.clear();
    await box.close();
  });

  group('ChallengeRepository', () {
    test('loadWeeklyChallenges returns empty list when no data', () async {
      final challenges = await repo.loadWeeklyChallenges();
      expect(challenges, isEmpty);
    });

    test('saveWeeklyChallenges and loadWeeklyChallenges round-trip', () async {
      final challenges = [
        const Challenge(
          id: 'walk-1km',
          title: 'Walk 1km',
          type: ChallengeType.distance,
          targetValue: 1000,
          currentValue: 400,
          xpReward: 50,
        ),
        const Challenge(
          id: 'discover-3',
          title: 'Discover 3 POIs',
          type: ChallengeType.discoveries,
          targetValue: 3,
          currentValue: 1,
          xpReward: 30,
        ),
      ];

      await repo.saveWeeklyChallenges(challenges);
      final loaded = await repo.loadWeeklyChallenges();

      expect(loaded.length, 2);
      expect(loaded[0].id, 'walk-1km');
      expect(loaded[0].currentValue, 400);
      expect(loaded[1].id, 'discover-3');
      expect(loaded[1].currentValue, 1);
    });

    test('loadWeekNumber returns 0 when no data', () async {
      final weekNumber = await repo.loadWeekNumber();
      expect(weekNumber, 0);
    });

    test('saveWeekNumber and loadWeekNumber round-trip', () async {
      await repo.saveWeekNumber(42);
      final weekNumber = await repo.loadWeekNumber();
      expect(weekNumber, 42);
    });

    test('overwriting challenges replaces previous data', () async {
      final first = [
        const Challenge(
          id: 'old',
          title: 'Old',
          type: ChallengeType.distance,
          targetValue: 100,
          currentValue: 0,
          xpReward: 10,
        ),
      ];
      await repo.saveWeeklyChallenges(first);

      final second = [
        const Challenge(
          id: 'new',
          title: 'New',
          type: ChallengeType.fogCleared,
          targetValue: 5,
          currentValue: 2,
          xpReward: 25,
        ),
      ];
      await repo.saveWeeklyChallenges(second);

      final loaded = await repo.loadWeeklyChallenges();
      expect(loaded.length, 1);
      expect(loaded[0].id, 'new');
    });

    test('handles corrupted JSON gracefully', () async {
      await box.put('weekly_challenges', 'not valid json');
      final challenges = await repo.loadWeeklyChallenges();
      expect(challenges, isEmpty);
    });
  });
}
