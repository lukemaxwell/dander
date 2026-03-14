import 'package:flutter_test/flutter_test.dart';

import 'package:dander/core/challenges/challenge.dart';

void main() {
  group('Challenge', () {
    test('creates with default values', () {
      final challenge = Challenge(
        id: 'walk-new-route',
        title: 'Walk a route you have never taken',
        type: ChallengeType.distance,
        targetValue: 1000,
        currentValue: 0,
        xpReward: 50,
      );

      expect(challenge.isCompleted, isFalse);
      expect(challenge.progress, 0.0);
    });

    test('progress is fraction of target', () {
      final challenge = Challenge(
        id: 'discover-3',
        title: 'Discover 3 POIs',
        type: ChallengeType.discoveries,
        targetValue: 3,
        currentValue: 1,
        xpReward: 30,
      );

      expect(challenge.progress, closeTo(0.333, 0.01));
    });

    test('progress clamps at 1.0', () {
      final challenge = Challenge(
        id: 'quiz-streak',
        title: 'Get 10 quiz questions right in a row',
        type: ChallengeType.quizStreak,
        targetValue: 10,
        currentValue: 15,
        xpReward: 40,
      );

      expect(challenge.progress, 1.0);
    });

    test('isCompleted when currentValue >= targetValue', () {
      final challenge = Challenge(
        id: 'clear-fog',
        title: 'Clear 2% more fog',
        type: ChallengeType.fogCleared,
        targetValue: 2,
        currentValue: 2,
        xpReward: 25,
      );

      expect(challenge.isCompleted, isTrue);
    });

    test('addProgress returns new instance with updated value', () {
      final challenge = Challenge(
        id: 'walk-distance',
        title: 'Walk 1km',
        type: ChallengeType.distance,
        targetValue: 1000,
        currentValue: 400,
        xpReward: 50,
      );

      final updated = challenge.addProgress(300);

      expect(updated.currentValue, 700);
      expect(challenge.currentValue, 400); // Original unchanged
    });

    test('toJson and fromJson round-trip correctly', () {
      final original = Challenge(
        id: 'discover-3',
        title: 'Discover 3 POIs',
        type: ChallengeType.discoveries,
        targetValue: 3,
        currentValue: 1,
        xpReward: 30,
      );

      final json = original.toJson();
      final restored = Challenge.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.type, original.type);
      expect(restored.targetValue, original.targetValue);
      expect(restored.currentValue, original.currentValue);
      expect(restored.xpReward, original.xpReward);
    });

    test('ChallengeType serialises as string', () {
      final challenge = Challenge(
        id: 'test',
        title: 'Test',
        type: ChallengeType.quizStreak,
        targetValue: 10,
        currentValue: 0,
        xpReward: 20,
      );

      final json = challenge.toJson();
      expect(json['type'], 'quizStreak');
    });
  });

  group('ChallengeDefinitions', () {
    test('has at least 8 challenge definitions', () {
      expect(ChallengeDefinitions.all.length, greaterThanOrEqualTo(8));
    });

    test('all definitions have positive target and reward', () {
      for (final def in ChallengeDefinitions.all) {
        expect(def.targetValue, greaterThan(0),
            reason: '${def.id} targetValue should be > 0');
        expect(def.xpReward, greaterThan(0),
            reason: '${def.id} xpReward should be > 0');
      }
    });

    test('challengesForWeek returns 4 challenges', () {
      final challenges = ChallengeDefinitions.challengesForWeek(1);
      expect(challenges.length, 4);
    });

    test('different weeks return different challenge sets', () {
      final week1 = ChallengeDefinitions.challengesForWeek(1);
      final week2 = ChallengeDefinitions.challengesForWeek(2);

      final ids1 = week1.map((c) => c.id).toSet();
      final ids2 = week2.map((c) => c.id).toSet();

      // At least some should differ
      expect(ids1, isNot(equals(ids2)));
    });

    test('challengesForWeek wraps around available definitions', () {
      // Should not crash even for very high week numbers
      final challenges = ChallengeDefinitions.challengesForWeek(999);
      expect(challenges.length, 4);
    });
  });

  group('WeeklyProgress', () {
    test('creates from challenge list', () {
      final challenges = [
        Challenge(
          id: 'c1',
          title: 'Challenge 1',
          type: ChallengeType.distance,
          targetValue: 1000,
          currentValue: 1000,
          xpReward: 50,
        ),
        Challenge(
          id: 'c2',
          title: 'Challenge 2',
          type: ChallengeType.discoveries,
          targetValue: 3,
          currentValue: 3,
          xpReward: 30,
        ),
        Challenge(
          id: 'c3',
          title: 'Challenge 3',
          type: ChallengeType.quizStreak,
          targetValue: 10,
          currentValue: 5,
          xpReward: 40,
        ),
        Challenge(
          id: 'c4',
          title: 'Challenge 4',
          type: ChallengeType.fogCleared,
          targetValue: 2,
          currentValue: 0,
          xpReward: 25,
        ),
      ];

      final progress = WeeklyProgress(challenges: challenges);

      expect(progress.completedCount, 2);
      expect(progress.totalCount, 4);
      expect(progress.isPerfectWeek, isFalse);
    });

    test('isPerfectWeek when all completed', () {
      final challenges = [
        Challenge(
          id: 'c1',
          title: 'Done',
          type: ChallengeType.distance,
          targetValue: 100,
          currentValue: 100,
          xpReward: 10,
        ),
      ];

      final progress = WeeklyProgress(challenges: challenges);
      expect(progress.isPerfectWeek, isTrue);
    });

    test('totalXpAvailable sums all rewards', () {
      final challenges = [
        Challenge(
          id: 'c1',
          title: 'A',
          type: ChallengeType.distance,
          targetValue: 100,
          currentValue: 0,
          xpReward: 50,
        ),
        Challenge(
          id: 'c2',
          title: 'B',
          type: ChallengeType.discoveries,
          targetValue: 3,
          currentValue: 0,
          xpReward: 30,
        ),
      ];

      final progress = WeeklyProgress(challenges: challenges);
      expect(progress.totalXpAvailable, 80);
    });
  });
}
