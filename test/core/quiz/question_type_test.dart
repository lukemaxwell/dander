import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/quiz/question_type.dart';
import 'package:dander/core/quiz/memory_record.dart';
import 'package:dander/core/quiz/street_memory_record.dart';

void main() {
  group('QuestionType', () {
    test('has 5 values', () {
      expect(QuestionType.values.length, 5);
    });

    test('contains all expected types', () {
      expect(QuestionType.values, contains(QuestionType.streetName));
      expect(QuestionType.values, contains(QuestionType.direction));
      expect(QuestionType.values, contains(QuestionType.proximity));
      expect(QuestionType.values, contains(QuestionType.category));
      expect(QuestionType.values, contains(QuestionType.route));
    });

    test('serialises as string name', () {
      expect(QuestionType.streetName.name, 'streetName');
      expect(QuestionType.direction.name, 'direction');
    });

    test('deserialises from string name', () {
      expect(QuestionType.values.byName('streetName'), QuestionType.streetName);
      expect(QuestionType.values.byName('route'), QuestionType.route);
    });
  });

  group('MemoryRecord', () {
    test('creates with initial state', () {
      final record = MemoryRecord.initial('streetName:way/123');

      expect(record.questionId, 'streetName:way/123');
      expect(record.state, MemoryState.newCard);
      expect(record.intervalDays, 0);
      expect(record.easeFactor, 2.5);
      expect(record.reviewHistory, isEmpty);
    });

    test('copyWith returns new instance with updated fields', () {
      final record = MemoryRecord.initial('direction:poi1-poi2');
      final updated = record.copyWith(
        state: MemoryState.review,
        intervalDays: 3,
      );

      expect(updated.questionId, 'direction:poi1-poi2');
      expect(updated.state, MemoryState.review);
      expect(updated.intervalDays, 3);
      expect(updated.easeFactor, 2.5); // unchanged
      // Original unchanged
      expect(record.state, MemoryState.newCard);
      expect(record.intervalDays, 0);
    });

    test('toJson and fromJson round-trip correctly', () {
      final original = MemoryRecord(
        questionId: 'category:node/456',
        state: MemoryState.review,
        intervalDays: 7,
        easeFactor: 2.3,
        nextReviewDate: DateTime(2026, 3, 20),
        reviewHistory: [DateTime(2026, 3, 13), DateTime(2026, 3, 15)],
      );

      final json = original.toJson();
      final restored = MemoryRecord.fromJson(json);

      expect(restored.questionId, original.questionId);
      expect(restored.state, original.state);
      expect(restored.intervalDays, original.intervalDays);
      expect(restored.easeFactor, original.easeFactor);
      expect(restored.nextReviewDate, original.nextReviewDate);
      expect(restored.reviewHistory.length, 2);
    });

    test('toJson includes questionId field', () {
      final record = MemoryRecord.initial('proximity:node/789');
      final json = record.toJson();

      expect(json['questionId'], 'proximity:node/789');
      expect(json.containsKey('streetId'), isFalse);
    });

    test('reviewHistory is unmodifiable', () {
      final record = MemoryRecord(
        questionId: 'test',
        state: MemoryState.newCard,
        intervalDays: 0,
        easeFactor: 2.5,
        nextReviewDate: DateTime(2026, 3, 15),
        reviewHistory: [DateTime(2026, 3, 14)],
      );

      expect(
        () => record.reviewHistory.add(DateTime.now()),
        throwsUnsupportedError,
      );
    });
  });

  group('MemoryRecord.fromLegacy', () {
    test('converts StreetMemoryRecord to MemoryRecord', () {
      final legacy = StreetMemoryRecord(
        streetId: 'way/123',
        state: MemoryState.review,
        intervalDays: 5,
        easeFactor: 2.3,
        nextReviewDate: DateTime(2026, 3, 20),
        reviewHistory: [DateTime(2026, 3, 15)],
      );

      final migrated = MemoryRecord.fromLegacy(legacy);

      expect(migrated.questionId, 'streetName:way/123');
      expect(migrated.state, MemoryState.review);
      expect(migrated.intervalDays, 5);
      expect(migrated.easeFactor, 2.3);
      expect(migrated.nextReviewDate, DateTime(2026, 3, 20));
      expect(migrated.reviewHistory.length, 1);
    });

    test('preserves mastered state during migration', () {
      final legacy = StreetMemoryRecord(
        streetId: 'way/456',
        state: MemoryState.mastered,
        intervalDays: 45,
        easeFactor: 2.5,
        nextReviewDate: DateTime(2026, 5, 1),
        reviewHistory: const [],
      );

      final migrated = MemoryRecord.fromLegacy(legacy);

      expect(migrated.state, MemoryState.mastered);
      expect(migrated.intervalDays, 45);
    });

    test('prefixes questionId with streetName:', () {
      final legacy = StreetMemoryRecord.initial('way/789');
      final migrated = MemoryRecord.fromLegacy(legacy);

      expect(migrated.questionId, startsWith('streetName:'));
      expect(migrated.questionId, 'streetName:way/789');
    });
  });
}
