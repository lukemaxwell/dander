import 'package:flutter_test/flutter_test.dart';
import 'package:dander/core/progress/streak_shield.dart';

void main() {
  group('StreakShield', () {
    group('creation', () {
      test('empty shield has no shield', () {
        final shield = StreakShield.empty();
        expect(shield.hasShield, isFalse);
        expect(shield.earnedAt, isNull);
      });
    });

    group('earning', () {
      test('earn sets hasShield to true', () {
        final shield = StreakShield.empty();
        final earned = shield.earn(DateTime(2024, 6, 15));
        expect(earned.hasShield, isTrue);
        expect(earned.earnedAt, DateTime(2024, 6, 15));
      });

      test('earn does not mutate original', () {
        final shield = StreakShield.empty();
        shield.earn(DateTime(2024, 6, 15));
        expect(shield.hasShield, isFalse);
      });

      test('cannot earn when already holding a shield', () {
        final shield = StreakShield.empty().earn(DateTime(2024, 6, 10));
        final attempted = shield.earn(DateTime(2024, 6, 15));
        // Should keep the original earnedAt
        expect(attempted.earnedAt, DateTime(2024, 6, 10));
      });
    });

    group('consuming', () {
      test('consume removes the shield', () {
        final shield = StreakShield.empty().earn(DateTime(2024, 6, 15));
        final consumed = shield.consume();
        expect(consumed.hasShield, isFalse);
        expect(consumed.earnedAt, isNull);
      });

      test('consume does not mutate original', () {
        final shield = StreakShield.empty().earn(DateTime(2024, 6, 15));
        shield.consume();
        expect(shield.hasShield, isTrue);
      });

      test('consume on empty shield returns empty', () {
        final shield = StreakShield.empty();
        final consumed = shield.consume();
        expect(consumed.hasShield, isFalse);
      });
    });

    group('serialization', () {
      test('round-trips empty shield through JSON', () {
        final shield = StreakShield.empty();
        final json = shield.toJson();
        final restored = StreakShield.fromJson(json);
        expect(restored.hasShield, isFalse);
      });

      test('round-trips earned shield through JSON', () {
        final shield = StreakShield.empty().earn(DateTime(2024, 6, 15));
        final json = shield.toJson();
        final restored = StreakShield.fromJson(json);
        expect(restored.hasShield, isTrue);
        expect(restored.earnedAt, isNotNull);
      });
    });
  });
}
