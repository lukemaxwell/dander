import 'package:flutter/material.dart';
import 'package:dander/core/theme/app_theme.dart';

/// Overlays a linear gradient on top of [child].
///
/// Typically used on the map screen to add a bottom-fade scrim so the
/// walk control panel is readable against the map tiles.
class GradientOverlay extends StatelessWidget {
  const GradientOverlay({
    super.key,
    required this.child,
    this.begin = Alignment.topCenter,
    this.end = Alignment.bottomCenter,
    this.colors,
    this.stops,
  });

  final Widget child;

  /// Gradient start alignment.
  final Alignment begin;

  /// Gradient end alignment.
  final Alignment end;

  /// Custom gradient colours. Defaults to transparent→surface.
  final List<Color>? colors;

  /// Custom gradient stops.
  final List<double>? stops;

  @override
  Widget build(BuildContext context) {
    final resolvedColors = colors ??
        [
          Colors.transparent,
          DanderColors.surface.withValues(alpha: 0.80),
        ];

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: begin,
                  end: end,
                  colors: resolvedColors,
                  stops: stops,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
