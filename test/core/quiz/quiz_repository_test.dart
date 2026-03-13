import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hive/hive.dart';
import 'package:dander/core/quiz/street_memory_record.dart';
import 'package:dander/core/quiz/quiz_repository.dart';

class MockBox extends Mock implements Box<dynamic> {}

void main() {
  group('HiveQuizRepository', () {
    late MockBox mockBox;
    late HiveQuizRepository repository;

    setUp(() {
      mockBox = MockBox();
      repository = HiveQuizRepository.withBox(mockBox);
    });

    // -------------------------------------------------------------------------
    // saveRecord
    // -------------------------------------------------------------------------
    group('saveRecord', () {
      test('saves record keyed by streetId', () async {
        final record = StreetMemoryRecord.initial('baker-street');
        when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

        await repository.saveRecord(record);

        verify(() => mockBox.put('baker-street', any())).called(1);
      });

      test('encodes record as JSON string', () async {
        final record = StreetMemoryRecord.initial('my-street');
        String? saved;
        when(() => mockBox.put(any(), any())).thenAnswer((inv) async {
          saved = inv.positionalArguments[1] as String;
        });

        await repository.saveRecord(record);

        expect(saved, isNotNull);
        expect(saved, contains('my-street'));
      });
    });

    // -------------------------------------------------------------------------
    // getAllRecords
    // -------------------------------------------------------------------------
    group('getAllRecords', () {
      test('returns empty list when box is empty', () async {
        when(() => mockBox.values).thenReturn([]);

        final result = await repository.getAllRecords();
        expect(result, isEmpty);
      });

      test('returns all persisted records', () async {
        final r1 = StreetMemoryRecord.initial('street-1');
        final r2 = StreetMemoryRecord.initial('street-2');

        final json1 = _encode(r1);
        final json2 = _encode(r2);
        when(() => mockBox.values).thenReturn([json1, json2]);

        final result = await repository.getAllRecords();
        expect(result.length, equals(2));
        expect(result.map((r) => r.streetId),
            containsAll(['street-1', 'street-2']));
      });

      test('deserialises records correctly', () async {
        final original = StreetMemoryRecord.initial('test-street')
            .copyWith(state: MemoryState.review, intervalDays: 7);
        when(() => mockBox.values).thenReturn([_encode(original)]);

        final result = await repository.getAllRecords();
        expect(result.first.state, equals(MemoryState.review));
        expect(result.first.intervalDays, equals(7));
      });
    });

    // -------------------------------------------------------------------------
    // getRecord
    // -------------------------------------------------------------------------
    group('getRecord', () {
      test('returns null for unknown streetId', () async {
        when(() => mockBox.get('unknown-street')).thenReturn(null);

        final result = await repository.getRecord('unknown-street');
        expect(result, isNull);
      });

      test('returns record for known streetId', () async {
        final record = StreetMemoryRecord.initial('park-lane');
        when(() => mockBox.get('park-lane')).thenReturn(_encode(record));

        final result = await repository.getRecord('park-lane');
        expect(result, isNotNull);
        expect(result!.streetId, equals('park-lane'));
      });

      test('returns record with correct fields', () async {
        final record = StreetMemoryRecord.initial('oxford-street')
            .copyWith(state: MemoryState.mastered, intervalDays: 30);
        when(() => mockBox.get('oxford-street')).thenReturn(_encode(record));

        final result = await repository.getRecord('oxford-street');
        expect(result!.state, equals(MemoryState.mastered));
        expect(result.intervalDays, equals(30));
      });
    });

    // -------------------------------------------------------------------------
    // ensureRecord
    // -------------------------------------------------------------------------
    group('ensureRecord', () {
      test('creates initial record when streetId not in box', () async {
        when(() => mockBox.get('new-street')).thenReturn(null);
        when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

        await repository.ensureRecord('new-street');

        verify(() => mockBox.put('new-street', any())).called(1);
      });

      test('does not overwrite existing record', () async {
        final existing = StreetMemoryRecord.initial('existing-street')
            .copyWith(state: MemoryState.review, intervalDays: 7);
        when(() => mockBox.get('existing-street'))
            .thenReturn(_encode(existing));

        await repository.ensureRecord('existing-street');

        verifyNever(() => mockBox.put(any(), any()));
      });

      test('created initial record has newCard state', () async {
        String? savedJson;
        when(() => mockBox.get('fresh-street')).thenReturn(null);
        when(() => mockBox.put(any(), any())).thenAnswer((inv) async {
          savedJson = inv.positionalArguments[1] as String;
        });

        await repository.ensureRecord('fresh-street');

        expect(savedJson, isNotNull);
        expect(savedJson, contains('newCard'));
      });
    });

    // -------------------------------------------------------------------------
    // Save/load round-trip
    // -------------------------------------------------------------------------
    group('save / load round-trip', () {
      test('save then getRecord returns equivalent record', () async {
        final record = StreetMemoryRecord.initial('round-trip-street')
            .copyWith(
                state: MemoryState.learning,
                intervalDays: 1,
                easeFactor: 2.3);

        dynamic saved;
        when(() => mockBox.put(any(), any())).thenAnswer((inv) async {
          saved = inv.positionalArguments[1];
        });
        when(() => mockBox.get('round-trip-street'))
            .thenAnswer((_) => saved);

        await repository.saveRecord(record);
        final loaded = await repository.getRecord('round-trip-street');

        expect(loaded, isNotNull);
        expect(loaded!.streetId, equals(record.streetId));
        expect(loaded.state, equals(record.state));
        expect(loaded.intervalDays, equals(record.intervalDays));
        expect(loaded.easeFactor, closeTo(record.easeFactor, 0.0001));
      });

      test('save then getAllRecords includes the saved record', () async {
        final record = StreetMemoryRecord.initial('all-records-street');
        String? savedJson;
        when(() => mockBox.put(any(), any())).thenAnswer((inv) async {
          savedJson = inv.positionalArguments[1] as String;
        });
        when(() => mockBox.values)
            .thenAnswer((_) => savedJson != null ? [savedJson] : []);

        await repository.saveRecord(record);
        final all = await repository.getAllRecords();

        expect(all.any((r) => r.streetId == 'all-records-street'), isTrue);
      });
    });
  });
}

/// Encodes a [StreetMemoryRecord] to JSON string as the repository would.
String _encode(StreetMemoryRecord record) {
  return jsonEncode(record.toJson());
}
