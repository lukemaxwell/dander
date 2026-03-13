import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/core/theme/category_pin_config.dart';

void main() {
  group('CategoryPinConfig', () {
    group('forCategory — known categories', () {
      test('cafe returns Icons.coffee and warm brown', () {
        final config = CategoryPinConfig.forCategory('cafe');
        expect(config.icon, equals(Icons.coffee));
        expect(config.color, equals(const Color(0xFF8D6E63)));
      });

      test('park returns Icons.park and green', () {
        final config = CategoryPinConfig.forCategory('park');
        expect(config.icon, equals(Icons.park));
        expect(config.color, equals(const Color(0xFF66BB6A)));
      });

      test('historic returns Icons.account_balance and gold', () {
        final config = CategoryPinConfig.forCategory('historic');
        expect(config.icon, equals(Icons.account_balance));
        expect(config.color, equals(const Color(0xFFFFD700)));
      });

      test('street_art returns Icons.palette and purple', () {
        final config = CategoryPinConfig.forCategory('street_art');
        expect(config.icon, equals(Icons.palette));
        expect(config.color, equals(const Color(0xFFAB47BC)));
      });

      test('viewpoint returns Icons.visibility and cyan', () {
        final config = CategoryPinConfig.forCategory('viewpoint');
        expect(config.icon, equals(Icons.visibility));
        expect(config.color, equals(const Color(0xFF4FC3F7)));
      });

      test('pub returns Icons.sports_bar and amber', () {
        final config = CategoryPinConfig.forCategory('pub');
        expect(config.icon, equals(Icons.sports_bar));
        expect(config.color, equals(const Color(0xFFFF8F00)));
      });

      test('library returns Icons.menu_book and blue', () {
        final config = CategoryPinConfig.forCategory('library');
        expect(config.icon, equals(Icons.menu_book));
        expect(config.color, equals(const Color(0xFF42A5F5)));
      });
    });

    group('forCategory — default / edge cases', () {
      test('unknown category returns Icons.place and default white', () {
        final config = CategoryPinConfig.forCategory('unknown_xyz');
        expect(config.icon, equals(Icons.place));
        expect(config.color, equals(const Color(0xFFE8EAF6)));
      });

      test('empty string returns default icon and color', () {
        final config = CategoryPinConfig.forCategory('');
        expect(config.icon, equals(Icons.place));
        expect(config.color, equals(const Color(0xFFE8EAF6)));
      });

      test('result icon is always an IconData instance', () {
        const categories = [
          'cafe',
          'park',
          'historic',
          'street_art',
          'viewpoint',
          'pub',
          'library',
          'totally_unknown',
          '',
        ];
        for (final c in categories) {
          expect(
            CategoryPinConfig.forCategory(c).icon,
            isA<IconData>(),
            reason: 'category "$c" should produce a non-null IconData',
          );
        }
      });

      test('result color is always a Color instance', () {
        const categories = [
          'cafe',
          'park',
          'historic',
          'street_art',
          'viewpoint',
          'pub',
          'library',
          'totally_unknown',
          '',
        ];
        for (final c in categories) {
          expect(
            CategoryPinConfig.forCategory(c).color,
            isA<Color>(),
            reason: 'category "$c" should produce a non-null Color',
          );
        }
      });
    });

    group('CategoryPinData record', () {
      test('two configs for the same category are equal', () {
        expect(
          CategoryPinConfig.forCategory('cafe'),
          equals(CategoryPinConfig.forCategory('cafe')),
        );
      });

      test('configs for different categories are not equal', () {
        expect(
          CategoryPinConfig.forCategory('cafe'),
          isNot(equals(CategoryPinConfig.forCategory('park'))),
        );
      });
    });
  });
}
