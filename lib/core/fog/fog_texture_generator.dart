import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// Generates a small tileable noise image for the fog overlay.
///
/// The output is a square [ui.Image] filled with subtle, randomly placed
/// semi-transparent marks in dark tones. It is designed to be tiled via
/// [ImageShader] over the fog fill to add atmospheric depth.
abstract final class FogTextureGenerator {
  /// Generates a [size]×[size] noise texture image.
  ///
  /// Uses a seeded PRNG for deterministic output per call. The pattern
  /// consists of small dots at varying low opacities to create a subtle
  /// topographic / parchment feel.
  static Future<ui.Image> generate({int size = 128}) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()));

    // Transparent base — the texture is composited over the fog.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      Paint()..color = const Color(0x00000000),
    );

    final rng = math.Random(42); // deterministic seed
    final dotPaint = Paint()..style = PaintingStyle.fill;

    // Layer 1: fine grain — many small dots
    for (var i = 0; i < size * 4; i++) {
      final x = rng.nextDouble() * size;
      final y = rng.nextDouble() * size;
      final alpha = (rng.nextDouble() * 0.18 + 0.08); // 8-26% opacity
      final radius = rng.nextDouble() * 1.5 + 0.5; // 0.5-2px

      dotPaint.color = Color.fromRGBO(200, 210, 230, alpha);
      canvas.drawCircle(Offset(x, y), radius, dotPaint);
    }

    // Layer 2: sparse larger marks for variation
    for (var i = 0; i < size ~/ 2; i++) {
      final x = rng.nextDouble() * size;
      final y = rng.nextDouble() * size;
      final alpha = (rng.nextDouble() * 0.12 + 0.05); // 5-17% opacity
      final radius = rng.nextDouble() * 3.0 + 1.5; // 1.5-4.5px

      dotPaint.color = Color.fromRGBO(180, 190, 210, alpha);
      canvas.drawCircle(Offset(x, y), radius, dotPaint);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    picture.dispose();
    return image;
  }
}
