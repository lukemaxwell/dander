import 'package:flutter_test/flutter_test.dart';
import 'package:dander/core/quiz/street_memory_record.dart';

void main() {
  group('StreetMemoryRecord', () {
    // -------------------------------------------------------------------------
    // factory StreetMemoryRecord.initial
    // -------------------------------------------------------------------------
    group('initial factory', () {
      test('creates record with newCard state', () {
        final record = StreetMemoryRecord.initial('street-1');
        expect(record.state, equals(MemoryState.newCard));
      });

      test('creates record with interval 0', () {
        final record = StreetMemoryRecord.initial('street-1');
        expect(record.intervalDays, equals(0));
      });

      test('creates record with default easeFactor 2.5', () {
        final record = StreetMemoryRecord.initial('street-1');
        expect(record.easeFactor, equals(2.5));
      });

      test('creates record with nextReviewDate as today (date only)', () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final record = StreetMemoryRecord.initial('street-1');
        final recordDate = DateTime(
          record.nextReviewDate.year,
          record.nextReviewDate.month,
          record.nextReviewDate.day,
        );
        expect(recordDate, equals(today));
      });

      test('creates record with empty reviewHistory', () {
        final record = StreetMemoryRecord.initial('street-1');
        expect(record.reviewHistory, isEmpty);
      });

      test('sets the correct streetId', () {
        final record = StreetMemoryRecord.initial('baker-street-42');
        expect(record.streetId, equals('baker-street-42'));
      });
    });

    // -------------------------------------------------------------------------
    // copyWith
    // -------------------------------------------------------------------------
    group('copyWith', () {
      late StreetMemoryRecord base;

      setUp(() {
        base = StreetMemoryRecord.initial('street-1');
      });

      test('copyWith returns new object', () {
        final copy = base.copyWith(intervalDays: 3);
        expect(identical(base, copy), isFalse);
      });

      test('copyWith updates intervalDays', () {
        final copy = base.copyWith(intervalDays: 7);
        expect(copy.intervalDays, equals(7));
        expect(base.intervalDays, equals(0)); // original unchanged
      });

      test('copyWith updates state', () {
        final copy = base.copyWith(state: MemoryState.review);
        expect(copy.state, equals(MemoryState.review));
        expect(base.state, equals(MemoryState.newCard)); // original unchanged
      });

      test('copyWith updates easeFactor', () {
        final copy = base.copyWith(easeFactor: 1.8);
        expect(copy.easeFactor, equals(1.8));
      });

      test('copyWith updates nextReviewDate', () {
        final newDate = DateTime(2025, 6, 15);
        final copy = base.copyWith(nextReviewDate: newDate);
        expect(copy.nextReviewDate, equals(newDate));
      });

      test('copyWith updates reviewHistory', () {
        final history = [DateTime(2025, 6, 10), DateTime(2025, 6, 11)];
        final copy = base.copyWith(reviewHistory: history);
        expect(copy.reviewHistory, equals(history));
      });

      test('copyWith preserves unchanged fields', () {
        final copy = base.copyWith(intervalDays: 5);
        expect(copy.streetId, equals(base.streetId));
        expect(copy.state, equals(base.state));
        expect(copy.easeFactor, equals(base.easeFactor));
        expect(copy.nextReviewDate, equals(base.nextReviewDate));
        expect(copy.reviewHistory, equals(base.reviewHistory));
      });

      test('copyWith reviewHistory is independent (immutability)', () {
        final history = [DateTime(2025, 6, 10)];
        final copy = base.copyWith(reviewHistory: history);
        // Mutating the original list must not affect the record
        history.add(DateTime(2025, 6, 11));
        expect(copy.reviewHistory.length, equals(1));
      });
    });

    // -------------------------------------------------------------------------
    // JSON round-trip
    // -------------------------------------------------------------------------
    group('toJson / fromJson', () {
      test('round-trip preserves streetId', () {
        final record = StreetMemoryRecord.initial('my-street');
        final json = record.toJson();
        final restored = StreetMemoryRecord.fromJson(json);
        expect(restored.streetId, equals(record.streetId));
      });

      test('round-trip preserves state', () {
        final record = StreetMemoryRecord.initial('my-street')
            .copyWith(state: MemoryState.mastered);
        final restored = StreetMemoryRecord.fromJson(record.toJson());
        expect(restored.state, equals(MemoryState.mastered));
      });

      test('round-trip preserves intervalDays', () {
        final record = StreetMemoryRecord.initial('my-street')
            .copyWith(intervalDays: 14);
        final restored = StreetMemoryRecord.fromJson(record.toJson());
        expect(restored.intervalDays, equals(14));
      });

      test('round-trip preserves easeFactor', () {
        final record = StreetMemoryRecord.initial('my-street')
            .copyWith(easeFactor: 1.3);
        final restored = StreetMemoryRecord.fromJson(record.toJson());
        expect(restored.easeFactor, closeTo(1.3, 0.0001));
      });

      test('round-trip preserves nextReviewDate', () {
        final date = DateTime(2025, 8, 20);
        final record = StreetMemoryRecord.initial('my-street')
            .copyWith(nextReviewDate: date);
        final restored = StreetMemoryRecord.fromJson(record.toJson());
        expect(restored.nextReviewDate, equals(date));
      });

      test('round-trip preserves reviewHistory', () {
        final history = [
          DateTime(2025, 6, 1),
          DateTime(2025, 6, 8),
          DateTime(2025, 6, 22),
        ];
        final record = StreetMemoryRecord.initial('my-street')
            .copyWith(reviewHistory: history);
        final restored = StreetMemoryRecord.fromJson(record.toJson());
        expect(restored.reviewHistory.length, equals(3));
        expect(restored.reviewHistory[0], equals(history[0]));
        expect(restored.reviewHistory[2], equals(history[2]));
      });

      test('round-trip with empty reviewHistory', () {
        final record = StreetMemoryRecord.initial('my-street');
        final restored = StreetMemoryRecord.fromJson(record.toJson());
        expect(restored.reviewHistory, isEmpty);
      });

      test('all MemoryState values survive JSON round-trip', () {
        for (final state in MemoryState.values) {
          final record = StreetMemoryRecord.initial('s').copyWith(state: state);
          final restored = StreetMemoryRecord.fromJson(record.toJson());
          expect(restored.state, equals(state));
        }
      });
    });

    // -------------------------------------------------------------------------
    // Immutability
    // -------------------------------------------------------------------------
    group('immutability', () {
      test('original record is not mutated by copyWith', () {
        final original = StreetMemoryRecord.initial('street-1');
        final intervalBefore = original.intervalDays;
        final stateBefore = original.state;

        original.copyWith(intervalDays: 99, state: MemoryState.mastered);

        expect(original.intervalDays, equals(intervalBefore));
        expect(original.state, equals(stateBefore));
      });

      test('reviewHistory list from record cannot mutate record internals', () {
        final record = StreetMemoryRecord.initial('street-1').copyWith(
          reviewHistory: [DateTime(2025, 1, 1)],
        );
        // Attempt to mutate the returned list — record should be unaffected
        final list = record.reviewHistory;
        expect(() => list.add(DateTime(2025, 1, 2)),
            throwsUnsupportedError); // unmodifiable
      });
    });
  });
}
