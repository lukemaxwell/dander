import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:dander/core/analytics/install_date_repository.dart';

// ---------------------------------------------------------------------------
// In-memory Hive box stub for unit tests
// ---------------------------------------------------------------------------

/// Minimal fake Hive Box backed by a Map.
///
/// Only implements the [get] and [put] operations needed by
/// [InstallDateRepository]. All other methods are unimplemented.
class _FakeBox extends Fake implements Box<dynamic> {
  final Map<String, dynamic> _store = {};

  @override
  dynamic get(dynamic key, {dynamic defaultValue}) =>
      _store[key as String] ?? defaultValue;

  @override
  Future<void> put(dynamic key, dynamic value) async {
    _store[key as String] = value;
  }

  @override
  bool containsKey(dynamic key) => _store.containsKey(key);
}

void main() {
  group('InstallDateRepository', () {
    late _FakeBox box;
    late InstallDateRepository repository;

    setUp(() {
      box = _FakeBox();
      repository = InstallDateRepository(box);
    });

    test('first call creates and returns a date', () async {
      final date = await repository.getOrCreate();
      expect(date, isA<DateTime>());
    });

    test('first call stores a date within a reasonable window of now', () async {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final date = await repository.getOrCreate();
      final after = DateTime.now().add(const Duration(seconds: 1));

      expect(date.isAfter(before), isTrue);
      expect(date.isBefore(after), isTrue);
    });

    test('second call returns the same date as the first', () async {
      final first = await repository.getOrCreate();
      final second = await repository.getOrCreate();
      expect(second, equals(first));
    });

    test('stored date is preserved across repository instances using same box',
        () async {
      final repoA = InstallDateRepository(box);
      final originalDate = await repoA.getOrCreate();

      // Create a new repository pointing at the same box.
      final repoB = InstallDateRepository(box);
      final retrievedDate = await repoB.getOrCreate();

      expect(retrievedDate, equals(originalDate));
    });

    test('does not overwrite an existing stored date', () async {
      // Pre-populate the box with a known past date.
      final pastDate = DateTime(2023, 6, 15, 12, 0, 0);
      await box.put('install_date', pastDate.toIso8601String());

      final date = await repository.getOrCreate();
      expect(date, equals(pastDate));
    });
  });
}
