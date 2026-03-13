import 'package:flutter_test/flutter_test.dart';
import 'package:dander/core/storage/hive_boxes.dart';

void main() {
  group('HiveBoxes constants', () {
    test('fogState has correct value', () {
      expect(HiveBoxes.fogState, equals('fog_state'));
    });

    test('walks has correct value', () {
      expect(HiveBoxes.walks, equals('walk_history'));
    });

    test('discoveries has correct value', () {
      expect(HiveBoxes.discoveries, equals('discoveries'));
    });

    test('progress has correct value', () {
      expect(HiveBoxes.progress, equals('progress'));
    });

    test('appState has correct value', () {
      expect(HiveBoxes.appState, equals('app_state'));
    });

    test('all box names are unique', () {
      final names = [
        HiveBoxes.fogState,
        HiveBoxes.walks,
        HiveBoxes.discoveries,
        HiveBoxes.progress,
        HiveBoxes.appState,
      ];
      final uniqueNames = names.toSet();
      expect(uniqueNames.length, equals(names.length));
    });

    test('all box names are non-empty strings', () {
      expect(HiveBoxes.fogState, isNotEmpty);
      expect(HiveBoxes.walks, isNotEmpty);
      expect(HiveBoxes.discoveries, isNotEmpty);
      expect(HiveBoxes.progress, isNotEmpty);
      expect(HiveBoxes.appState, isNotEmpty);
    });

    test('box names contain only lowercase letters and underscores', () {
      final pattern = RegExp(r'^[a-z_]+$');
      expect(pattern.hasMatch(HiveBoxes.fogState), isTrue);
      expect(pattern.hasMatch(HiveBoxes.walks), isTrue);
      expect(pattern.hasMatch(HiveBoxes.discoveries), isTrue);
      expect(pattern.hasMatch(HiveBoxes.progress), isTrue);
      expect(pattern.hasMatch(HiveBoxes.appState), isTrue);
    });
  });
}
