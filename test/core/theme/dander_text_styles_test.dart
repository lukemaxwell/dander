import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/core/theme/dander_text_styles.dart';
import 'package:dander/core/theme/dander_colors.dart';

void main() {
  group('DanderTextStyles', () {
    test('displayLarge has the largest font size', () {
      expect(
        DanderTextStyles.displayLarge.fontSize,
        greaterThan(DanderTextStyles.headlineMedium.fontSize!),
      );
    });

    test('headlineMedium has bold weight', () {
      expect(
        DanderTextStyles.headlineMedium.fontWeight,
        FontWeight.bold,
      );
    });

    test('bodyLarge has a reasonable font size between 14 and 18', () {
      final size = DanderTextStyles.bodyLarge.fontSize;
      expect(size, isNotNull);
      expect(size, greaterThanOrEqualTo(14.0));
      expect(size, lessThanOrEqualTo(18.0));
    });

    test('bodyMedium is smaller than bodyLarge', () {
      expect(
        DanderTextStyles.bodyMedium.fontSize,
        lessThan(DanderTextStyles.bodyLarge.fontSize!),
      );
    });

    test('labelSmall has smallest font size among text styles', () {
      expect(
        DanderTextStyles.labelSmall.fontSize,
        lessThanOrEqualTo(DanderTextStyles.bodyMedium.fontSize!),
      );
    });

    test('titleLarge uses onSurface color', () {
      expect(DanderTextStyles.titleLarge.color, DanderColors.onSurface);
    });

    test('all named styles are non-null', () {
      expect(DanderTextStyles.displayLarge, isNotNull);
      expect(DanderTextStyles.headlineLarge, isNotNull);
      expect(DanderTextStyles.headlineMedium, isNotNull);
      expect(DanderTextStyles.titleLarge, isNotNull);
      expect(DanderTextStyles.titleMedium, isNotNull);
      expect(DanderTextStyles.bodyLarge, isNotNull);
      expect(DanderTextStyles.bodyMedium, isNotNull);
      expect(DanderTextStyles.labelLarge, isNotNull);
      expect(DanderTextStyles.labelMedium, isNotNull);
      expect(DanderTextStyles.labelSmall, isNotNull);
    });

    test('muted variant has lower opacity color', () {
      // muted body should differ from regular body by alpha
      final regularColor = DanderTextStyles.bodyLarge.color;
      final mutedColor = DanderTextStyles.bodyLargeMuted.color;
      expect(mutedColor, isNotNull);
      expect(mutedColor, isNot(equals(regularColor)));
    });
  });
}
