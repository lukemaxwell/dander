import 'package:flutter_test/flutter_test.dart';
import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/discoveries/rarity_classifier.dart';

void main() {
  group('RarityClassifier.classify', () {
    // -------------------------------------------------------------------------
    // Rare (gold) cases
    // -------------------------------------------------------------------------
    group('rare tier', () {
      test('tourism=viewpoint → rare', () {
        expect(
          RarityClassifier.classify({'tourism': 'viewpoint'}),
          equals(RarityTier.rare),
        );
      });

      test('historic=* (any value) → rare', () {
        expect(
          RarityClassifier.classify({'historic': 'castle'}),
          equals(RarityTier.rare),
        );
        expect(
          RarityClassifier.classify({'historic': 'monument'}),
          equals(RarityTier.rare),
        );
        expect(
          RarityClassifier.classify({'historic': 'ruins'}),
          equals(RarityTier.rare),
        );
      });

      test('tourism=artwork → rare', () {
        expect(
          RarityClassifier.classify({'tourism': 'artwork'}),
          equals(RarityTier.rare),
        );
      });

      test('amenity=place_of_worship with name → rare', () {
        expect(
          RarityClassifier.classify({
            'amenity': 'place_of_worship',
            'name': 'St Paul Cathedral',
          }),
          equals(RarityTier.rare),
        );
      });

      test('amenity=place_of_worship without name → NOT rare', () {
        // Without a name it should not be classified as rare
        final result =
            RarityClassifier.classify({'amenity': 'place_of_worship'});
        expect(result, isNot(equals(RarityTier.rare)));
      });

      test('leisure=nature_reserve → rare', () {
        expect(
          RarityClassifier.classify({'leisure': 'nature_reserve'}),
          equals(RarityTier.rare),
        );
      });
    });

    // -------------------------------------------------------------------------
    // Uncommon (silver) cases
    // -------------------------------------------------------------------------
    group('uncommon tier', () {
      test('amenity=cafe without brand → uncommon', () {
        expect(
          RarityClassifier.classify({'amenity': 'cafe', 'name': 'Local Brew'}),
          equals(RarityTier.uncommon),
        );
      });

      test('amenity=cafe with brand → NOT uncommon (falls to common)', () {
        expect(
          RarityClassifier.classify({'amenity': 'cafe', 'brand': 'Starbucks'}),
          equals(RarityTier.common),
        );
      });

      test('amenity=library → uncommon', () {
        expect(
          RarityClassifier.classify({'amenity': 'library'}),
          equals(RarityTier.uncommon),
        );
      });

      test('amenity=community_centre → uncommon', () {
        expect(
          RarityClassifier.classify({'amenity': 'community_centre'}),
          equals(RarityTier.uncommon),
        );
      });

      test('leisure=park → uncommon', () {
        expect(
          RarityClassifier.classify({'leisure': 'park'}),
          equals(RarityTier.uncommon),
        );
      });

      test('tourism=museum → uncommon', () {
        expect(
          RarityClassifier.classify({'tourism': 'museum'}),
          equals(RarityTier.uncommon),
        );
      });
    });

    // -------------------------------------------------------------------------
    // Common (bronze) cases
    // -------------------------------------------------------------------------
    group('common tier', () {
      test('amenity=cafe with brand → common', () {
        expect(
          RarityClassifier.classify({'amenity': 'cafe', 'brand': 'Costa'}),
          equals(RarityTier.common),
        );
      });

      test('amenity=restaurant → common', () {
        expect(
          RarityClassifier.classify({'amenity': 'restaurant'}),
          equals(RarityTier.common),
        );
      });

      test('amenity=pharmacy → common', () {
        expect(
          RarityClassifier.classify({'amenity': 'pharmacy'}),
          equals(RarityTier.common),
        );
      });

      test('amenity=bank → common', () {
        expect(
          RarityClassifier.classify({'amenity': 'bank'}),
          equals(RarityTier.common),
        );
      });

      test('amenity=pub → common', () {
        expect(
          RarityClassifier.classify({'amenity': 'pub'}),
          equals(RarityTier.common),
        );
      });
    });

    // -------------------------------------------------------------------------
    // Unknown / unrecognised tags → default to common
    // -------------------------------------------------------------------------
    group('default', () {
      test('empty tags map → common', () {
        expect(RarityClassifier.classify({}), equals(RarityTier.common));
      });

      test('unrecognised tags → common', () {
        expect(
          RarityClassifier.classify({'amenity': 'atm'}),
          equals(RarityTier.common),
        );
      });
    });

    // -------------------------------------------------------------------------
    // Priority: rare > uncommon > common (rare rules win if multiple match)
    // -------------------------------------------------------------------------
    group('priority ordering', () {
      test('historic tag combined with leisure=park → rare wins', () {
        expect(
          RarityClassifier.classify({'historic': 'yes', 'leisure': 'park'}),
          equals(RarityTier.rare),
        );
      });
    });
  });

  // ---------------------------------------------------------------------------
  // RarityClassifier.inferCategory
  // ---------------------------------------------------------------------------
  group('RarityClassifier.inferCategory', () {
    test('amenity tag value returned as category', () {
      expect(
        RarityClassifier.inferCategory({'amenity': 'cafe'}),
        equals('cafe'),
      );
    });

    test('tourism tag value returned when no amenity', () {
      expect(
        RarityClassifier.inferCategory({'tourism': 'viewpoint'}),
        equals('viewpoint'),
      );
    });

    test('historic tag value returned', () {
      expect(
        RarityClassifier.inferCategory({'historic': 'castle'}),
        equals('castle'),
      );
    });

    test('leisure tag value returned', () {
      expect(
        RarityClassifier.inferCategory({'leisure': 'park'}),
        equals('park'),
      );
    });

    test('amenity takes priority over tourism', () {
      expect(
        RarityClassifier.inferCategory(
            {'amenity': 'cafe', 'tourism': 'attraction'}),
        equals('cafe'),
      );
    });

    test('empty tags → unknown', () {
      expect(RarityClassifier.inferCategory({}), equals('unknown'));
    });

    test('unrecognised tag key → unknown', () {
      expect(
        RarityClassifier.inferCategory({'building': 'yes'}),
        equals('unknown'),
      );
    });
  });
}
