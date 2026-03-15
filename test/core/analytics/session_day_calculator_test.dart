import 'package:flutter_test/flutter_test.dart';

import 'package:dander/core/analytics/session_day_calculator.dart';

void main() {
  group('SessionDayCalculator.calculate', () {
    test('same day returns day 1', () {
      final installDate = DateTime(2024, 1, 15, 9, 0);
      final now = DateTime(2024, 1, 15, 14, 30);
      expect(SessionDayCalculator.calculate(installDate, now), equals(1));
    });

    test('1 day later returns day 2', () {
      final installDate = DateTime(2024, 1, 15);
      final now = DateTime(2024, 1, 16);
      expect(SessionDayCalculator.calculate(installDate, now), equals(2));
    });

    test('30 days later returns day 31', () {
      final installDate = DateTime(2024, 1, 1);
      final now = DateTime(2024, 1, 31);
      expect(SessionDayCalculator.calculate(installDate, now), equals(31));
    });

    test('install date equals now (zero difference) returns day 1', () {
      final installDate = DateTime(2024, 6, 1);
      final now = DateTime(2024, 6, 1);
      expect(SessionDayCalculator.calculate(installDate, now), equals(1));
    });

    test('1 hour after install returns day 1', () {
      final installDate = DateTime(2024, 3, 10, 8, 0);
      final now = DateTime(2024, 3, 10, 9, 0);
      expect(SessionDayCalculator.calculate(installDate, now), equals(1));
    });

    test('23 hours 59 minutes later is still day 1', () {
      final installDate = DateTime(2024, 3, 10, 0, 0);
      final now = DateTime(2024, 3, 10, 23, 59);
      expect(SessionDayCalculator.calculate(installDate, now), equals(1));
    });

    test('exactly 24 hours later returns day 2', () {
      final installDate = DateTime(2024, 3, 10, 0, 0);
      final now = DateTime(2024, 3, 11, 0, 0);
      expect(SessionDayCalculator.calculate(installDate, now), equals(2));
    });

    test('365 days later returns day 366', () {
      final installDate = DateTime(2024, 1, 1);
      final now = DateTime(2024, 12, 31);
      // 365 days in 2024 (leap year), so Jan 1 to Dec 31 = 365 days
      expect(SessionDayCalculator.calculate(installDate, now), equals(366));
    });
  });
}
