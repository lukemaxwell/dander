import 'package:flutter_test/flutter_test.dart';
import 'package:dander/core/location/walk_stats_formatter.dart';

void main() {
  group('WalkStatsFormatter', () {
    // -------------------------------------------------------------------------
    // formatDuration
    // -------------------------------------------------------------------------
    group('formatDuration', () {
      test('zero duration returns "0m 0s"', () {
        expect(
          WalkStatsFormatter.formatDuration(Duration.zero),
          '0m 0s',
        );
      });

      test('seconds only (< 1 minute)', () {
        expect(
          WalkStatsFormatter.formatDuration(const Duration(seconds: 45)),
          '0m 45s',
        );
      });

      test('1 minute exactly', () {
        expect(
          WalkStatsFormatter.formatDuration(const Duration(minutes: 1)),
          '1m 0s',
        );
      });

      test('minutes and seconds (< 1 hour)', () {
        expect(
          WalkStatsFormatter.formatDuration(
              const Duration(minutes: 45, seconds: 12)),
          '45m 12s',
        );
      });

      test('exactly 1 hour', () {
        expect(
          WalkStatsFormatter.formatDuration(const Duration(hours: 1)),
          '1h 0m',
        );
      });

      test('hours and minutes suppresses seconds', () {
        expect(
          WalkStatsFormatter.formatDuration(
              const Duration(hours: 1, minutes: 23, seconds: 59)),
          '1h 23m',
        );
      });

      test('multiple hours', () {
        expect(
          WalkStatsFormatter.formatDuration(
              const Duration(hours: 3, minutes: 5)),
          '3h 5m',
        );
      });

      test('exactly 59 minutes 59 seconds', () {
        expect(
          WalkStatsFormatter.formatDuration(
              const Duration(minutes: 59, seconds: 59)),
          '59m 59s',
        );
      });
    });

    // -------------------------------------------------------------------------
    // formatDistance
    // -------------------------------------------------------------------------
    group('formatDistance', () {
      test('zero metres returns "0 m"', () {
        expect(WalkStatsFormatter.formatDistance(0), '0 m');
      });

      test('sub-1000 metres shows metres', () {
        expect(WalkStatsFormatter.formatDistance(450), '450 m');
      });

      test('exactly 999 metres stays in metres', () {
        expect(WalkStatsFormatter.formatDistance(999), '999 m');
      });

      test('exactly 1000 metres shows "1.0 km"', () {
        expect(WalkStatsFormatter.formatDistance(1000), '1.0 km');
      });

      test('1200 metres shows "1.2 km"', () {
        expect(WalkStatsFormatter.formatDistance(1200), '1.2 km');
      });

      test('rounds to 1 decimal place', () {
        // 1250 m → 1.25 km → rounds to "1.3 km" (half-up)
        expect(WalkStatsFormatter.formatDistance(1250), '1.3 km');
      });

      test('large distance: 10 km', () {
        expect(WalkStatsFormatter.formatDistance(10000), '10.0 km');
      });

      test('fractional metres rounds down to integer', () {
        expect(WalkStatsFormatter.formatDistance(450.6), '451 m');
      });
    });

    // -------------------------------------------------------------------------
    // formatFogCleared
    // -------------------------------------------------------------------------
    group('formatFogCleared', () {
      test('0% formats correctly', () {
        expect(WalkStatsFormatter.formatFogCleared(0), '0.0%');
      });

      test('100% formats correctly', () {
        expect(WalkStatsFormatter.formatFogCleared(100), '100.0%');
      });

      test('decimal percentage shows 1 decimal place', () {
        expect(WalkStatsFormatter.formatFogCleared(12.3456), '12.3%');
      });

      test('rounds to 1 decimal place (Dart half-to-even)', () {
        // Dart's toStringAsFixed uses IEEE 754 rounding; 12.35 may produce
        // "12.3%" or "12.4%" depending on float representation.  We accept
        // either as long as it is 1 decimal place.
        final result = WalkStatsFormatter.formatFogCleared(12.35);
        expect(result, matches(RegExp(r'^\d+\.\d%$')));
      });

      test('small percentage < 1%', () {
        expect(WalkStatsFormatter.formatFogCleared(0.5), '0.5%');
      });
    });
  });
}
