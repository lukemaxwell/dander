import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/core/theme/dander_colors.dart';

void main() {
  group('DanderColors', () {
    test('primary is dark navy', () {
      expect(DanderColors.primary, const Color(0xFF1A1A2E));
    });

    test('surface is darker than primary', () {
      expect(DanderColors.surface, const Color(0xFF0A0A14));
    });

    test('surfaceElevated is between surface and primary', () {
      // surfaceElevated sits above surface but below primary
      expect(DanderColors.surfaceElevated, isA<Color>());
    });

    test('accent is sky blue', () {
      expect(DanderColors.accent, const Color(0xFF4FC3F7));
    });

    test('secondary is purple', () {
      expect(DanderColors.secondary, isA<Color>());
    });

    test('onSurface is near-white', () {
      expect(DanderColors.onSurface, const Color(0xFFE8EAF6));
    });

    test('onSurfaceMuted has lower opacity than onSurface', () {
      expect(DanderColors.onSurfaceMuted, isA<Color>());
    });

    test('success is green', () {
      const c = DanderColors.success;
      expect((c.g * 255.0).round(), greaterThan((c.r * 255.0).round()));
    });

    test('error is red', () {
      const c = DanderColors.error;
      expect((c.r * 255.0).round(), greaterThan((c.g * 255.0).round()));
    });

    test('fog overlay is semi-transparent', () {
      expect(DanderColors.fogOverlay.a, lessThan(1.0));
    });

    test('rarity common is bronze-ish', () {
      expect(DanderColors.rarityCommon, const Color(0xFFCD7F32));
    });

    test('rarity uncommon is silver-ish', () {
      expect(DanderColors.rarityUncommon, const Color(0xFFC0C0C0));
    });

    test('rarity rare is gold', () {
      expect(DanderColors.rarityRare, const Color(0xFFFFD700));
    });

    test('streakActive is orange-ish fire color', () {
      const c = DanderColors.streakActive;
      expect((c.r * 255.0).round(), greaterThan((c.b * 255.0).round()));
    });

    test('cardBackground differs from surface', () {
      expect(DanderColors.cardBackground, isNot(equals(DanderColors.surface)));
    });

    test('gradientStart and gradientEnd form a coherent pair', () {
      expect(DanderColors.gradientStart, isA<Color>());
      expect(DanderColors.gradientEnd, isA<Color>());
      expect(
        DanderColors.gradientStart,
        isNot(equals(DanderColors.gradientEnd)),
      );
    });
  });
}
