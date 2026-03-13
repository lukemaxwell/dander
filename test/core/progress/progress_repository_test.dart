import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hive/hive.dart';
import 'package:dander/core/progress/badge.dart';
import 'package:dander/core/progress/streak_tracker.dart';
import 'package:dander/core/progress/progress_repository.dart';

class MockBox extends Mock implements Box<dynamic> {}

void main() {
  group('HiveProgressRepository', () {
    late MockBox mockBox;
    late HiveProgressRepository repository;

    setUp(() {
      mockBox = MockBox();
      repository = HiveProgressRepository.withBox(mockBox);
    });

    // -------------------------------------------------------------------------
    // Badges
    // -------------------------------------------------------------------------
    group('saveBadges / loadBadges', () {
      test('saveBadges writes JSON-encoded list to box', () async {
        final badges = BadgeDefinitions.badges;

        when(() => mockBox.put(any(), any())).thenAnswer((_) async {});
        await repository.saveBadges(badges);

        verify(() => mockBox.put(HiveProgressRepository.badgesKey, any()))
            .called(1);
      });

      test('loadBadges returns empty list when no data in box', () async {
        when(() => mockBox.get(HiveProgressRepository.badgesKey))
            .thenReturn(null);

        final result = await repository.loadBadges();
        expect(result, isEmpty);
      });

      test('round-trip: saveBadges then loadBadges preserves locked state',
          () async {
        final badges = BadgeDefinitions.badges;

        dynamic saved;
        when(() => mockBox.put(any(), any())).thenAnswer((inv) async {
          saved = inv.positionalArguments[1];
        });
        when(() => mockBox.get(HiveProgressRepository.badgesKey))
            .thenAnswer((_) => saved);

        await repository.saveBadges(badges);
        final loaded = await repository.loadBadges();

        expect(loaded.length, equals(badges.length));
        for (final badge in loaded) {
          expect(badge.isUnlocked, isFalse);
        }
      });

      test('round-trip: saveBadges then loadBadges preserves unlocked state',
          () async {
        final unlockedAt = DateTime(2024, 6, 1, 12, 0, 0);
        final badges = BadgeDefinitions.badges.map((b) {
          if (b.id == BadgeId.explorer) return b.unlock(unlockedAt);
          return b;
        }).toList();

        dynamic saved;
        when(() => mockBox.put(any(), any())).thenAnswer((inv) async {
          saved = inv.positionalArguments[1];
        });
        when(() => mockBox.get(HiveProgressRepository.badgesKey))
            .thenAnswer((_) => saved);

        await repository.saveBadges(badges);
        final loaded = await repository.loadBadges();

        final explorer = loaded.firstWhere((b) => b.id == BadgeId.explorer);
        expect(explorer.isUnlocked, isTrue);
        expect(explorer.unlockedAt, equals(unlockedAt));
      });

      test('loadBadges returns all 6 badge definitions when data present',
          () async {
        final badges = BadgeDefinitions.badges;

        dynamic saved;
        when(() => mockBox.put(any(), any())).thenAnswer((inv) async {
          saved = inv.positionalArguments[1];
        });
        when(() => mockBox.get(HiveProgressRepository.badgesKey))
            .thenAnswer((_) => saved);

        await repository.saveBadges(badges);
        final loaded = await repository.loadBadges();
        expect(loaded.length, equals(6));
      });

      test('loadBadges handles corrupted data gracefully (returns empty list)',
          () async {
        when(() => mockBox.get(HiveProgressRepository.badgesKey))
            .thenReturn('not valid json {{');

        final result = await repository.loadBadges();
        expect(result, isEmpty);
      });
    });

    // -------------------------------------------------------------------------
    // Streak
    // -------------------------------------------------------------------------
    group('saveStreak / loadStreak', () {
      test('saveStreak writes JSON-encoded tracker to box', () async {
        final tracker =
            StreakTracker(currentStreak: 3, lastWalkDate: DateTime(2024, 6, 1));

        when(() => mockBox.put(any(), any())).thenAnswer((_) async {});
        await repository.saveStreak(tracker);

        verify(() => mockBox.put(HiveProgressRepository.streakKey, any()))
            .called(1);
      });

      test('loadStreak returns empty tracker when no data in box', () async {
        when(() => mockBox.get(HiveProgressRepository.streakKey))
            .thenReturn(null);

        final result = await repository.loadStreak();
        expect(result.currentStreak, equals(0));
        expect(result.lastWalkDate, isNull);
      });

      test('round-trip: saveStreak then loadStreak preserves data', () async {
        final date = DateTime(2024, 6, 15, 9, 0, 0);
        final original = StreakTracker(currentStreak: 7, lastWalkDate: date);

        dynamic saved;
        when(() => mockBox.put(any(), any())).thenAnswer((inv) async {
          saved = inv.positionalArguments[1];
        });
        when(() => mockBox.get(HiveProgressRepository.streakKey))
            .thenAnswer((_) => saved);

        await repository.saveStreak(original);
        final loaded = await repository.loadStreak();

        expect(loaded.currentStreak, equals(7));
        expect(loaded.lastWalkDate, equals(date));
      });

      test('loadStreak handles corrupted data gracefully (returns empty)',
          () async {
        when(() => mockBox.get(HiveProgressRepository.streakKey))
            .thenReturn('{"bad": ');

        final result = await repository.loadStreak();
        expect(result.currentStreak, equals(0));
      });
    });
  });
}
