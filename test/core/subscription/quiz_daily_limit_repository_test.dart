import 'package:flutter_test/flutter_test.dart';

import 'package:dander/core/subscription/quiz_daily_limit_repository.dart';
import 'package:dander/core/subscription/subscription_state.dart';

// ---------------------------------------------------------------------------
// Fake storage
// ---------------------------------------------------------------------------

class _FakeStorage implements QuizLimitStorage {
  final Map<String, dynamic> _data = {};

  @override
  dynamic get(String key) => _data[key];

  @override
  Future<void> put(String key, dynamic value) async {
    _data[key] = value;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

QuizDailyLimitRepository _makeRepo({
  required DateTime now,
  bool isPro = false,
}) {
  final storage = _FakeStorage();
  final state = isPro
      ? const SubscriptionStatePro()
      : const SubscriptionStateFree();
  return QuizDailyLimitRepository(
    storage: storage,
    clock: () => now,
    subscriptionState: () => state,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  final day1 = DateTime(2026, 3, 15);
  final day2 = DateTime(2026, 3, 16);

  group('QuizDailyLimitRepository', () {
    group('getTodayCount', () {
      test('returns 0 on fresh storage', () async {
        final repo = _makeRepo(now: day1);

        expect(await repo.getTodayCount(), 0);
      });

      test('returns 0 when stored date is yesterday', () async {
        final storage = _FakeStorage();
        // Pre-seed data from yesterday.
        await storage.put('quiz_limit_date', '2026-03-14');
        await storage.put('quiz_limit_count', 9);

        final repo = QuizDailyLimitRepository(
          storage: storage,
          clock: () => day1,
          subscriptionState: () => const SubscriptionStateFree(),
        );

        expect(await repo.getTodayCount(), 0);
      });

      test('returns persisted count when date matches today', () async {
        final storage = _FakeStorage();
        await storage.put('quiz_limit_date', '2026-03-15');
        await storage.put('quiz_limit_count', 7);

        final repo = QuizDailyLimitRepository(
          storage: storage,
          clock: () => day1,
          subscriptionState: () => const SubscriptionStateFree(),
        );

        expect(await repo.getTodayCount(), 7);
      });
    });

    group('increment', () {
      test('increments count from 0 to 1', () async {
        final repo = _makeRepo(now: day1);

        await repo.increment();

        expect(await repo.getTodayCount(), 1);
      });

      test('increments count from 5 to 6', () async {
        final storage = _FakeStorage();
        await storage.put('quiz_limit_date', '2026-03-15');
        await storage.put('quiz_limit_count', 5);

        final repo = QuizDailyLimitRepository(
          storage: storage,
          clock: () => day1,
          subscriptionState: () => const SubscriptionStateFree(),
        );

        await repo.increment();

        expect(await repo.getTodayCount(), 6);
      });

      test('increments across multiple calls correctly', () async {
        final repo = _makeRepo(now: day1);

        await repo.increment();
        await repo.increment();
        await repo.increment();

        expect(await repo.getTodayCount(), 3);
      });

      test('resets count to 1 on a new day', () async {
        final storage = _FakeStorage();
        // Data from yesterday.
        await storage.put('quiz_limit_date', '2026-03-15');
        await storage.put('quiz_limit_count', 10);

        final repo = QuizDailyLimitRepository(
          storage: storage,
          clock: () => day2,
          subscriptionState: () => const SubscriptionStateFree(),
        );

        await repo.increment();

        expect(await repo.getTodayCount(), 1);
      });

      test('does not mutate original storage object', () async {
        final storage = _FakeStorage();
        await storage.put('quiz_limit_date', '2026-03-15');
        await storage.put('quiz_limit_count', 3);

        final repo = QuizDailyLimitRepository(
          storage: storage,
          clock: () => day1,
          subscriptionState: () => const SubscriptionStateFree(),
        );

        await repo.increment();

        // The old count value in storage is replaced (immutable write), not
        // modified in-place.
        expect(storage.get('quiz_limit_count'), 4);
      });
    });

    group('isLimitReached', () {
      test('returns false when count is 0', () async {
        final repo = _makeRepo(now: day1);

        expect(await repo.isLimitReached(), isFalse);
      });

      test('returns false when count is 9', () async {
        final storage = _FakeStorage();
        await storage.put('quiz_limit_date', '2026-03-15');
        await storage.put('quiz_limit_count', 9);

        final repo = QuizDailyLimitRepository(
          storage: storage,
          clock: () => day1,
          subscriptionState: () => const SubscriptionStateFree(),
        );

        expect(await repo.isLimitReached(), isFalse);
      });

      test('returns true when count is exactly 10', () async {
        final storage = _FakeStorage();
        await storage.put('quiz_limit_date', '2026-03-15');
        await storage.put('quiz_limit_count', 10);

        final repo = QuizDailyLimitRepository(
          storage: storage,
          clock: () => day1,
          subscriptionState: () => const SubscriptionStateFree(),
        );

        expect(await repo.isLimitReached(), isTrue);
      });

      test('returns true when count exceeds 10', () async {
        final storage = _FakeStorage();
        await storage.put('quiz_limit_date', '2026-03-15');
        await storage.put('quiz_limit_count', 15);

        final repo = QuizDailyLimitRepository(
          storage: storage,
          clock: () => day1,
          subscriptionState: () => const SubscriptionStateFree(),
        );

        expect(await repo.isLimitReached(), isTrue);
      });

      test('returns false for Pro user regardless of count', () async {
        final storage = _FakeStorage();
        await storage.put('quiz_limit_date', '2026-03-15');
        await storage.put('quiz_limit_count', 10);

        final repo = QuizDailyLimitRepository(
          storage: storage,
          clock: () => day1,
          subscriptionState: () => const SubscriptionStatePro(),
        );

        expect(await repo.isLimitReached(), isFalse);
      });

      test('returns false for Trial user regardless of count', () async {
        final storage = _FakeStorage();
        await storage.put('quiz_limit_date', '2026-03-15');
        await storage.put('quiz_limit_count', 10);

        final repo = QuizDailyLimitRepository(
          storage: storage,
          clock: () => day1,
          subscriptionState: () => const SubscriptionStateTrial(daysLeft: 3),
        );

        expect(await repo.isLimitReached(), isFalse);
      });

      test('returns false when count resets to 0 on new day', () async {
        final storage = _FakeStorage();
        await storage.put('quiz_limit_date', '2026-03-15');
        await storage.put('quiz_limit_count', 10);

        final repo = QuizDailyLimitRepository(
          storage: storage,
          clock: () => day2,
          subscriptionState: () => const SubscriptionStateFree(),
        );

        expect(await repo.isLimitReached(), isFalse);
      });
    });

    group('date key format', () {
      test('uses ISO-8601 date string yyyy-MM-dd', () async {
        final storage = _FakeStorage();
        final repo = QuizDailyLimitRepository(
          storage: storage,
          clock: () => DateTime(2026, 1, 5),
          subscriptionState: () => const SubscriptionStateFree(),
        );

        await repo.increment();

        expect(storage.get('quiz_limit_date'), '2026-01-05');
      });
    });
  });
}
