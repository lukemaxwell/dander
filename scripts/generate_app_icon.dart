/// Generates a 1024x1024 app icon PNG at assets/icon/app_icon.png.
///
/// Usage: dart run scripts/generate_app_icon.dart
///
/// Design: bold white map-pin on a deep amber → burnt-orange radial gradient.
/// The pin shape (disc + pointed tail) is instantly recognisable at every
/// size from 20 pt to 1024 px.
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

void main() {
  const size = 1024;
  final image = img.Image(width: size, height: size);
  _drawIcon(image, size);
  final pngBytes = img.encodePng(image);
  final file = File('assets/icon/app_icon.png');
  file.writeAsBytesSync(pngBytes);
  stdout.writeln('Generated: ${file.path} (${file.lengthSync()} bytes)');
}

// ---------------------------------------------------------------------------
// Colour helpers
// ---------------------------------------------------------------------------

img.ColorRgba8 _hex(int argb) {
  final a = (argb >> 24) & 0xFF;
  final r = (argb >> 16) & 0xFF;
  final g = (argb >> 8) & 0xFF;
  final b = argb & 0xFF;
  return img.ColorRgba8(r, g, b, a == 0 ? 255 : a);
}

img.ColorRgba8 _blend(img.ColorRgba8 c1, img.ColorRgba8 c2, double t) {
  return img.ColorRgba8(
    (c1.r + (c2.r - c1.r) * t).round(),
    (c1.g + (c2.g - c1.g) * t).round(),
    (c1.b + (c2.b - c1.b) * t).round(),
    (c1.a + (c2.a - c1.a) * t).round(),
  );
}

img.ColorRgba8 _withAlpha(img.ColorRgba8 c, int alpha) =>
    img.ColorRgba8(c.r.toInt(), c.g.toInt(), c.b.toInt(), alpha);

// ---------------------------------------------------------------------------
// Drawing primitives
// ---------------------------------------------------------------------------

void _setPixelBlended(img.Image image, int x, int y, img.ColorRgba8 color) {
  if (x < 0 || x >= image.width || y < 0 || y >= image.height) return;
  final alpha = color.a / 255.0;
  if (alpha <= 0) return;
  if (alpha >= 1.0) {
    image.setPixelRgba(x, y, color.r, color.g, color.b, color.a);
    return;
  }
  final existing = image.getPixel(x, y);
  final r = (existing.r * (1 - alpha) + color.r * alpha).round();
  final g = (existing.g * (1 - alpha) + color.g * alpha).round();
  final b = (existing.b * (1 - alpha) + color.b * alpha).round();
  image.setPixelRgba(x, y, r, g, b, 255);
}

void _drawFilledCircle(
  img.Image image,
  int cx,
  int cy,
  int radius,
  img.ColorRgba8 color,
) {
  for (var dy = -radius; dy <= radius; dy++) {
    for (var dx = -radius; dx <= radius; dx++) {
      if (dx * dx + dy * dy <= radius * radius) {
        _setPixelBlended(image, cx + dx, cy + dy, color);
      }
    }
  }
}

void _drawRadialGradient(
  img.Image image,
  int cx,
  int cy,
  int radius,
  img.ColorRgba8 colorInner,
  img.ColorRgba8 colorOuter,
) {
  final r2 = radius * radius;
  for (var dy = -radius; dy <= radius; dy++) {
    for (var dx = -radius; dx <= radius; dx++) {
      final dist2 = dx * dx + dy * dy;
      if (dist2 <= r2) {
        final t = math.sqrt(dist2.toDouble()) / radius;
        _setPixelBlended(image, cx + dx, cy + dy, _blend(colorInner, colorOuter, t));
      }
    }
  }
}

void _drawFilledPolygon(
  img.Image image,
  List<(double, double)> vertices,
  img.ColorRgba8 color,
) {
  if (vertices.isEmpty) return;
  double minY = vertices[0].$2, maxY = vertices[0].$2;
  for (final v in vertices) {
    if (v.$2 < minY) minY = v.$2;
    if (v.$2 > maxY) maxY = v.$2;
  }
  for (var py = minY.floor(); py <= maxY.ceil(); py++) {
    final intersections = <double>[];
    final n = vertices.length;
    for (var i = 0; i < n; i++) {
      final (x1, y1) = vertices[i];
      final (x2, y2) = vertices[(i + 1) % n];
      if ((y1 <= py && y2 > py) || (y2 <= py && y1 > py)) {
        intersections.add(x1 + (py - y1) / (y2 - y1) * (x2 - x1));
      }
    }
    intersections.sort();
    for (var i = 0; i + 1 < intersections.length; i += 2) {
      for (var px = intersections[i].ceil(); px <= intersections[i + 1].floor(); px++) {
        _setPixelBlended(image, px, py, color);
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Icon drawing
// ---------------------------------------------------------------------------

void _drawIcon(img.Image image, int size) {
  final cx = size ~/ 2;
  final cy = size ~/ 2;
  final r = size ~/ 2;

  // --- Background: deep burnt-orange → vivid amber radial gradient ---
  // Fill with the outer colour first, then paint gradient disc.
  img.fill(image, color: _hex(0xFF8B2500)); // darkest edge

  _drawRadialGradient(
    image,
    cx,
    (cy * 0.85).round(),
    (r * 1.5).round(),
    _hex(0xFFFF8F00), // vivid amber centre
    _hex(0xFF8B2500), // deep burnt-orange edge
  );

  // Subtle inner warmth highlight (top-left)
  _drawRadialGradient(
    image,
    (cx * 0.6).round(),
    (cy * 0.5).round(),
    (r * 0.7).round(),
    _withAlpha(_hex(0xFFFFCA28), 80), // golden shimmer
    _withAlpha(_hex(0xFFFF8F00), 0),
  );

  // --- Map pin mark (white) ---
  // The pin occupies roughly 55% of icon height, centred slightly above middle.
  final pinCy = (cy - r * 0.08).round(); // shift slightly upward
  final pinHeadR = (r * 0.34).round();   // disc head radius
  final pinHeadCy = (pinCy - r * 0.12).round(); // head centre (above visual centre)
  final pinTipY = (pinCy + r * 0.52).round();   // pointed tail tip

  final white = _hex(0xFFFFFBF0); // warm white

  // Shadow / depth under the pin
  _drawFilledCircle(
    image, cx + (r * 0.04).round(), pinHeadCy + (r * 0.04).round(),
    pinHeadR, _withAlpha(_hex(0xFF000000), 60),
  );

  // Pin head (disc)
  _drawFilledCircle(image, cx, pinHeadCy, pinHeadR, white);

  // Pin tail: isosceles triangle — shoulders sit at the circle equator
  // so head and tail form one seamless teardrop silhouette.
  final shoulderY = pinHeadCy + (pinHeadR * 0.20).round();
  final shoulderHalfW = (pinHeadR * 0.96).round();

  _drawFilledPolygon(
    image,
    [
      (cx - shoulderHalfW.toDouble(), shoulderY.toDouble()),
      (cx + shoulderHalfW.toDouble(), shoulderY.toDouble()),
      (cx.toDouble(), pinTipY.toDouble()),
    ],
    white,
  );

  // Hole inside the pin head (shows background through)
  final holeR = (pinHeadR * 0.42).round();
  _drawFilledCircle(image, cx, pinHeadCy, holeR, _hex(0xFFFF8F00));

  // Subtle inner shadow on hole edge
  _drawFilledCircle(
    image, cx, pinHeadCy, holeR,
    _withAlpha(_hex(0xFF8B2500), 60),
  );
  // Re-draw clean hole centre
  _drawFilledCircle(
    image, cx, pinHeadCy, (holeR * 0.78).round(),
    _hex(0xFFE65100),
  );
}
