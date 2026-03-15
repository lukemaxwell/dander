import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:dander/core/subscription/milestone_pro_suggestion_frequency.dart';

void main() {
  late Box<dynamic> box;
  late MilestoneProSuggestionFrequency frequency;

  setUp(() async {
    Hive.init(
      '/tmp/hive_milestone_freq_test_${DateTime.now().millisecondsSinceEpoch}',
    );
    box = await Hive.openBox<dynamic>(
      'milestone_freq_test_${DateTime.now().millisecondsSinceEpoch}',
    );
    frequency = MilestoneProSuggestionFrequency.withBox(box);
  });

  tearDown(() async {
    await box.close();
  });

  group('MilestoneProSuggestionFrequency', () {
    group('shouldShow — before any record()', () {
      test('returns false when no milestone has been recorded', () {
        expect(frequency.shouldShow(), isFalse);
      });
    });

    group('shouldShow — alternating pattern after record()', () {
      test('first record() then shouldShow() returns true', () {
        frequency.record();
        expect(frequency.shouldShow(), isTrue);
      });

      test('second record() then shouldShow() returns false', () {
        frequency.record();
        frequency.record();
        expect(frequency.shouldShow(), isFalse);
      });

      test('third record() then shouldShow() returns true', () {
        frequency.record();
        frequency.record();
        frequency.record();
        expect(frequency.shouldShow(), isTrue);
      });

      test('fourth record() then shouldShow() returns false', () {
        frequency.record();
        frequency.record();
        frequency.record();
        frequency.record();
        expect(frequency.shouldShow(), isFalse);
      });
    });

    group('shouldShow — does not mutate state', () {
      test('calling shouldShow() multiple times without record() returns same value', () {
        frequency.record();
        final first = frequency.shouldShow();
        final second = frequency.shouldShow();
        expect(first, equals(second));
      });
    });

    group('record — persists count across instances', () {
      test('count persists so new instance reads same state', () async {
        frequency.record();
        frequency.record();
        // Reopen the same box with a new instance
        final frequency2 = MilestoneProSuggestionFrequency.withBox(box);
        expect(frequency2.shouldShow(), isFalse);
      });
    });
  });
}
