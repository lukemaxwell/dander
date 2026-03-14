import 'package:flutter_test/flutter_test.dart';

import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/haptics/haptic_service.dart';

void main() {
  group('HapticService.discoveryByRarity', () {
    test('common rarity returns normally', () {
      expect(
        () => HapticService.discoveryByRarity(RarityTier.common),
        returnsNormally,
      );
    });

    test('uncommon rarity returns normally', () {
      expect(
        () => HapticService.discoveryByRarity(RarityTier.uncommon),
        returnsNormally,
      );
    });

    test('rare rarity returns normally', () {
      expect(
        () => HapticService.discoveryByRarity(RarityTier.rare),
        returnsNormally,
      );
    });

    test('legendary rarity returns normally', () {
      expect(
        () => HapticService.discoveryByRarity(RarityTier.legendary),
        returnsNormally,
      );
    });
  });
}
