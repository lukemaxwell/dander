import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/core/theme/dander_elevation.dart';

void main() {
  group('DanderElevation', () {
    test('level0 has no shadows', () {
      expect(DanderElevation.level0, isEmpty);
    });

    test('level1 has one shadow', () {
      expect(DanderElevation.level1, hasLength(1));
    });

    test('level2 has at least one shadow', () {
      expect(DanderElevation.level2, isNotEmpty);
    });

    test('level3 has at least one shadow', () {
      expect(DanderElevation.level3, isNotEmpty);
    });

    test('shadows are BoxShadow instances', () {
      for (final shadow in DanderElevation.level3) {
        expect(shadow, isA<BoxShadow>());
      }
    });

    test('higher levels have more spread or blur than level1', () {
      final l1Blur = DanderElevation.level1.first.blurRadius;
      final l3Blur = DanderElevation.level3
          .map((s) => s.blurRadius)
          .reduce((a, b) => a > b ? a : b);
      expect(l3Blur, greaterThanOrEqualTo(l1Blur));
    });
  });
}
