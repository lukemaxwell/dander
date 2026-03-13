import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:dander/core/fog/fog_texture_generator.dart';

void main() {
  group('FogTextureGenerator', () {
    test('generates an image of 128x128 pixels', () async {
      final image = await FogTextureGenerator.generate();

      expect(image.width, 128);
      expect(image.height, 128);

      image.dispose();
    });

    test('returns a valid non-null image', () async {
      final image = await FogTextureGenerator.generate();

      expect(image, isA<ui.Image>());

      image.dispose();
    });

    test('can be called multiple times safely', () async {
      final image1 = await FogTextureGenerator.generate();
      final image2 = await FogTextureGenerator.generate();

      expect(image1.width, 128);
      expect(image2.width, 128);

      image1.dispose();
      image2.dispose();
    });

    test('accepts custom size parameter', () async {
      final image = await FogTextureGenerator.generate(size: 64);

      expect(image.width, 64);
      expect(image.height, 64);

      image.dispose();
    });
  });
}
