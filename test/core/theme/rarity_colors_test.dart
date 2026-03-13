import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/theme/rarity_colors.dart';

void main() {
  group('RarityColors', () {
    group('colour constants', () {
      test('common is bronze (0xFFCD7F32)', () {
        expect(RarityColors.common, equals(const Color(0xFFCD7F32)));
      });

      test('uncommon is silver (0xFFC0C0C0)', () {
        expect(RarityColors.uncommon, equals(const Color(0xFFC0C0C0)));
      });

      test('rare is gold (0xFFFFD700)', () {
        expect(RarityColors.rare, equals(const Color(0xFFFFD700)));
      });
    });

    group('forTier', () {
      test('returns common colour for RarityTier.common', () {
        expect(
          RarityColors.forTier(RarityTier.common),
          equals(RarityColors.common),
        );
      });

      test('returns uncommon colour for RarityTier.uncommon', () {
        expect(
          RarityColors.forTier(RarityTier.uncommon),
          equals(RarityColors.uncommon),
        );
      });

      test('returns rare colour for RarityTier.rare', () {
        expect(
          RarityColors.forTier(RarityTier.rare),
          equals(RarityColors.rare),
        );
      });

      test('covers all three tiers without throwing', () {
        for (final tier in RarityTier.values) {
          expect(() => RarityColors.forTier(tier), returnsNormally);
        }
      });
    });

    group('label', () {
      test('returns "Common" for RarityTier.common', () {
        expect(RarityColors.label(RarityTier.common), equals('Common'));
      });

      test('returns "Uncommon" for RarityTier.uncommon', () {
        expect(RarityColors.label(RarityTier.uncommon), equals('Uncommon'));
      });

      test('returns "Rare" for RarityTier.rare', () {
        expect(RarityColors.label(RarityTier.rare), equals('Rare'));
      });

      test('covers all three tiers without throwing', () {
        for (final tier in RarityTier.values) {
          expect(() => RarityColors.label(tier), returnsNormally);
        }
      });

      test('returns non-empty string for every tier', () {
        for (final tier in RarityTier.values) {
          expect(RarityColors.label(tier), isNotEmpty);
        }
      });
    });
  });
}
