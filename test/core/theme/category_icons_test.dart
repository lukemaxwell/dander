import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dander/core/theme/category_icons.dart';

void main() {
  group('CategoryIcons', () {
    group('forCategory — known categories', () {
      test('cafe maps to Icons.local_cafe', () {
        expect(CategoryIcons.forCategory('cafe'), equals(Icons.local_cafe));
      });

      test('park maps to Icons.park', () {
        expect(CategoryIcons.forCategory('park'), equals(Icons.park));
      });

      test('viewpoint maps to Icons.landscape', () {
        expect(
          CategoryIcons.forCategory('viewpoint'),
          equals(Icons.landscape),
        );
      });

      test('historic maps to Icons.account_balance', () {
        expect(
          CategoryIcons.forCategory('historic'),
          equals(Icons.account_balance),
        );
      });

      test('artwork maps to Icons.palette', () {
        expect(CategoryIcons.forCategory('artwork'), equals(Icons.palette));
      });

      test('museum maps to Icons.museum', () {
        expect(CategoryIcons.forCategory('museum'), equals(Icons.museum));
      });

      test('library maps to Icons.local_library', () {
        expect(
          CategoryIcons.forCategory('library'),
          equals(Icons.local_library),
        );
      });

      test('pub maps to Icons.sports_bar', () {
        expect(CategoryIcons.forCategory('pub'), equals(Icons.sports_bar));
      });

      test('restaurant maps to Icons.restaurant', () {
        expect(
          CategoryIcons.forCategory('restaurant'),
          equals(Icons.restaurant),
        );
      });
    });

    group('forCategory — unknown / edge cases', () {
      test('unknown category returns Icons.place', () {
        expect(CategoryIcons.forCategory('unknown'), equals(Icons.place));
      });

      test('empty string returns Icons.place', () {
        expect(CategoryIcons.forCategory(''), equals(Icons.place));
      });

      test('returns an IconData (not null) for any string', () {
        const categories = [
          'cafe',
          'park',
          'viewpoint',
          'historic',
          'artwork',
          'museum',
          'library',
          'pub',
          'restaurant',
          'random_unknown',
          '',
        ];
        for (final c in categories) {
          expect(CategoryIcons.forCategory(c), isA<IconData>());
        }
      });
    });
  });
}
