import 'package:flutter_test/flutter_test.dart';

import 'package:dander/core/theme/dander_spacing.dart';

void main() {
  group('DanderSpacing', () {
    test('xs is 4', () => expect(DanderSpacing.xs, 4.0));
    test('sm is 8', () => expect(DanderSpacing.sm, 8.0));
    test('md is 12', () => expect(DanderSpacing.md, 12.0));
    test('lg is 16', () => expect(DanderSpacing.lg, 16.0));
    test('xl is 24', () => expect(DanderSpacing.xl, 24.0));
    test('xxl is 32', () => expect(DanderSpacing.xxl, 32.0));
    test('xxxl is 48', () => expect(DanderSpacing.xxxl, 48.0));

    test('values increase monotonically', () {
      final values = [
        DanderSpacing.xs,
        DanderSpacing.sm,
        DanderSpacing.md,
        DanderSpacing.lg,
        DanderSpacing.xl,
        DanderSpacing.xxl,
        DanderSpacing.xxxl,
      ];
      for (var i = 0; i < values.length - 1; i++) {
        expect(values[i], lessThan(values[i + 1]));
      }
    });

    test(
        'borderRadiusSm is 8', () => expect(DanderSpacing.borderRadiusSm, 8.0));
    test('borderRadiusMd is 12',
        () => expect(DanderSpacing.borderRadiusMd, 12.0));
    test('borderRadiusLg is 16',
        () => expect(DanderSpacing.borderRadiusLg, 16.0));
    test('borderRadiusXl is 24',
        () => expect(DanderSpacing.borderRadiusXl, 24.0));
    test('borderRadiusFull is very large', () {
      expect(DanderSpacing.borderRadiusFull, greaterThanOrEqualTo(100.0));
    });

    test('pagePadding is EdgeInsets with lg on all sides', () {
      expect(DanderSpacing.pagePadding.top, DanderSpacing.lg);
      expect(DanderSpacing.pagePadding.bottom, DanderSpacing.lg);
      expect(DanderSpacing.pagePadding.left, DanderSpacing.lg);
      expect(DanderSpacing.pagePadding.right, DanderSpacing.lg);
    });

    test('cardPadding is EdgeInsets with lg on all sides', () {
      expect(DanderSpacing.cardPadding.top, DanderSpacing.lg);
    });
  });
}
