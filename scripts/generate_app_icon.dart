/// Generates a 1024x1024 app icon PNG at assets/icon/app_icon.png.
///
/// Usage: dart run scripts/generate_app_icon.dart
///
/// The icon draws the Dander compass/fog logo mark on a brand gradient
/// background using the `image` package (pure Dart, no dart:ui required).
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

img.ColorRgba8 _withAlpha(img.ColorRgba8 c, int alpha) {
  return img.ColorRgba8(c.r.toInt(), c.g.toInt(), c.b.toInt(), alpha);
}

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

void _drawCircleOutline(
  img.Image image,
  int cx,
  int cy,
  int radius,
  int strokeWidth,
  img.ColorRgba8 color,
) {
  final r2Outer = (radius + strokeWidth ~/ 2) * (radius + strokeWidth ~/ 2);
  final r2Inner = (radius - strokeWidth ~/ 2) * (radius - strokeWidth ~/ 2);
  for (var dy = -(radius + strokeWidth);
      dy <= radius + strokeWidth;
      dy++) {
    for (var dx = -(radius + strokeWidth);
        dx <= radius + strokeWidth;
        dx++) {
      final r2 = dx * dx + dy * dy;
      if (r2 <= r2Outer && r2 >= r2Inner) {
        _setPixelBlended(image, cx + dx, cy + dy, color);
      }
    }
  }
}

void _drawLine(
  img.Image image,
  double x1,
  double y1,
  double x2,
  double y2,
  int strokeWidth,
  img.ColorRgba8 color,
) {
  final dx = x2 - x1;
  final dy = y2 - y1;
  final len = math.sqrt(dx * dx + dy * dy);
  if (len == 0) return;
  final steps = (len * 2).ceil();
  for (var i = 0; i <= steps; i++) {
    final t = i / steps;
    final px = (x1 + dx * t).round();
    final py = (y1 + dy * t).round();
    final half = strokeWidth ~/ 2;
    for (var oy = -half; oy <= half; oy++) {
      for (var ox = -half; ox <= half; ox++) {
        _setPixelBlended(image, px + ox, py + oy, color);
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
  double minX = vertices[0].$1, maxX = vertices[0].$1;
  for (final v in vertices) {
    if (v.$2 < minY) minY = v.$2;
    if (v.$2 > maxY) maxY = v.$2;
    if (v.$1 < minX) minX = v.$1;
    if (v.$1 > maxX) maxX = v.$1;
  }
  for (var py = minY.floor(); py <= maxY.ceil(); py++) {
    final intersections = <double>[];
    final n = vertices.length;
    for (var i = 0; i < n; i++) {
      final (x1, y1) = vertices[i];
      final (x2, y2) = vertices[(i + 1) % n];
      if ((y1 <= py && y2 > py) || (y2 <= py && y1 > py)) {
        final x = x1 + (py - y1) / (y2 - y1) * (x2 - x1);
        intersections.add(x);
      }
    }
    intersections.sort();
    for (var i = 0; i + 1 < intersections.length; i += 2) {
      final startX = intersections[i].ceil();
      final endX = intersections[i + 1].floor();
      for (var px = startX; px <= endX; px++) {
        _setPixelBlended(image, px, py, color);
      }
    }
  }
}

void _drawDashedCircle(
  img.Image image,
  int cx,
  int cy,
  int radius,
  int dashes,
  int strokeWidth,
  img.ColorRgba8 color,
) {
  final dashAngle = 2 * math.pi / (dashes * 2);
  for (var i = 0; i < dashes * 2; i += 2) {
    final startAngle = i * dashAngle;
    final endAngle = startAngle + dashAngle;
    final steps = (radius * dashAngle).ceil().clamp(20, 200);
    for (var s = 0; s <= steps; s++) {
      final angle = startAngle + (endAngle - startAngle) * s / steps;
      final x = (cx + radius * math.cos(angle)).round();
      final y = (cy + radius * math.sin(angle)).round();
      final half = strokeWidth ~/ 2;
      for (var oy = -half; oy <= half; oy++) {
        for (var ox = -half; ox <= half; ox++) {
          _setPixelBlended(image, x + ox, y + oy, color);
        }
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
        final t = math.sqrt(dist2) / radius;
        final c = _blend(colorInner, colorOuter, t);
        _setPixelBlended(image, cx + dx, cy + dy, c);
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

  // Brand dark background
  img.fill(image, color: _hex(0xFF0D0D1A));

  // Radial gradient from slightly upper-left
  _drawRadialGradient(
    image,
    (cx * 0.85).round(),
    (cy * 0.65).round(),
    (r * 1.45).round(),
    _hex(0xFF1A1A2E),
    _hex(0xFF0D0D1A),
  );

  // Subtle purple glow in centre
  _drawRadialGradient(
    image,
    cx,
    cy,
    (r * 0.80).round(),
    _withAlpha(_hex(0xFF6E56CF), 90), // ~0.35 opacity
    _withAlpha(_hex(0xFF0D0D1A), 0),
  );

  // Fog ring (dashed)
  _drawDashedCircle(
    image,
    cx,
    cy,
    (r * 0.82).round(),
    20,
    (size * 0.003).round().clamp(2, 8),
    _withAlpha(_hex(0xFF4FC3F7), 102), // ~0.4 opacity
  );

  // Compass disc background
  _drawFilledCircle(image, cx, cy, (r * 0.68).round(), _hex(0xFF1E1E2E));

  // Subtle glow inside disc
  _drawRadialGradient(
    image,
    cx,
    (cy * 0.82).round(),
    (r * 0.68).round(),
    _withAlpha(_hex(0xFF6E56CF), 77), // ~0.3 opacity
    _withAlpha(_hex(0xFF0D0D1A), 0),
  );

  // Compass needle
  _drawCompassNeedle(image, cx, cy, (r * 0.50).round(), size);

  // Cardinal ticks
  _drawCardinalTicks(
    image,
    cx,
    cy,
    (r * 0.54).round(),
    (r * 0.64).round(),
    (size * 0.005).round().clamp(2, 6),
  );

  // Disc border ring
  _drawCircleOutline(
    image,
    cx,
    cy,
    (r * 0.68).round(),
    (size * 0.004).round().clamp(2, 5),
    _withAlpha(_hex(0xFF4FC3F7), 77),
  );

  // Centre pivot dot
  _drawFilledCircle(image, cx, cy, (r * 0.075).round(), _hex(0xFF4FC3F7));
  _drawFilledCircle(image, cx, cy, (r * 0.035).round(), _hex(0xFF1A1A2E));

  // Footprints
  _drawFootprints(image, cx, cy, r, size);
}

void _drawCompassNeedle(
  img.Image image,
  int cx,
  int cy,
  int length,
  int size,
) {
  // North (top) — blue/purple gradient simulated as two triangles
  final halfBase = (length * 0.14).round();

  // North half (bright cyan)
  _drawFilledPolygon(
    image,
    [
      (cx.toDouble(), cy - length.toDouble()),
      (cx + halfBase.toDouble(), cy.toDouble()),
      (cx - halfBase.toDouble(), cy.toDouble()),
    ],
    _hex(0xFF4FC3F7),
  );

  // Blend upper part toward purple
  for (var dy = -length; dy < 0; dy++) {
    final t = (-dy) / length.toDouble(); // 1 near tip, 0 at centre
    final col = _blend(_hex(0xFF4FC3F7), _hex(0xFF6E56CF), 1 - t);
    final xHalf = (halfBase * (-dy) / length).round();
    for (var dx = -xHalf; dx <= xHalf; dx++) {
      _setPixelBlended(image, cx + dx, cy + dy, col);
    }
  }

  // South half (dim white)
  _drawFilledPolygon(
    image,
    [
      (cx.toDouble(), cy + length.toDouble()),
      (cx + halfBase.toDouble(), cy.toDouble()),
      (cx - halfBase.toDouble(), cy.toDouble()),
    ],
    _withAlpha(_hex(0xFFE8EAF6), 64), // ~0.25 opacity
  );
}

void _drawCardinalTicks(
  img.Image image,
  int cx,
  int cy,
  int innerR,
  int outerR,
  int strokeWidth,
) {
  final angles = [
    -math.pi / 2, // North (top)
    0.0, // East
    math.pi / 2, // South
    math.pi, // West
  ];

  for (var i = 0; i < angles.length; i++) {
    final a = angles[i];
    final fromX = cx + innerR * math.cos(a);
    final fromY = cy + innerR * math.sin(a);
    final toX = cx + outerR * math.cos(a);
    final toY = cy + outerR * math.sin(a);

    final isNorth = i == 0;
    final color = isNorth
        ? _hex(0xFF4FC3F7)
        : _withAlpha(_hex(0xFFE8EAF6), 128);
    final sw = isNorth ? (strokeWidth * 2.5).round() : (strokeWidth * 1.5).round();

    _drawLine(image, fromX, fromY, toX, toY, sw, color);
  }
}

void _drawFootprints(img.Image image, int cx, int cy, int r, int size) {
  final color = _withAlpha(_hex(0xFF6E56CF), 178); // ~0.7 opacity

  void drawFootprint(double dx, double dy) {
    final w = (r * 0.09).round();
    final h = (r * 0.06).round();
    _drawFilledCircle(image, dx.round(), dy.round(), (w + h) ~/ 2, color);
    // approximate oval by drawing an ellipse
    for (var oy = -h; oy <= h; oy++) {
      for (var ox = -w; ox <= w; ox++) {
        final inside =
            (ox * ox) / (w * w + 1.0) + (oy * oy) / (h * h + 1.0) <= 1.0;
        if (inside) {
          _setPixelBlended(image, dx.round() + ox, dy.round() + oy, color);
        }
      }
    }
  }

  drawFootprint(cx - r * 0.22, cy + r * 0.42);
  drawFootprint(cx + r * 0.22, cy + r * 0.58);
}
