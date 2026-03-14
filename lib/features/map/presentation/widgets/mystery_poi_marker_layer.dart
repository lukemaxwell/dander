import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:dander/core/theme/app_theme.dart';
import 'package:dander/core/theme/category_pin_config.dart';
import 'package:dander/core/zone/mystery_poi.dart';

/// A map layer that renders mystery POI markers over the FlutterMap canvas.
///
/// Three rendering modes driven by [PoiState]:
/// - [PoiState.unrevealed]: NOT rendered — no marker at all.
/// - [PoiState.hinted]: Amber pulsing "?" circle.
/// - [PoiState.revealed]: Category-coloured pin using
///   [CategoryPinConfig.forCategory].
///
/// Place this inside a [Builder] within [FlutterMap.children], where
/// [MapCamera.of(context)] is accessible — identical to the pattern used in
/// [FogLayer] and the location dot in [MapScreen].
///
/// Example:
/// ```dart
/// Builder(builder: (context) {
///   final camera = MapCamera.of(context);
///   return MysteryPoiMarkerLayer(pois: pois, camera: camera);
/// })
/// ```
class MysteryPoiMarkerLayer extends StatefulWidget {
  const MysteryPoiMarkerLayer({
    super.key,
    required this.pois,
    required this.camera,
    this.onRevealedTap,
  });

  /// The list of mystery POIs to render.  May be empty.
  final List<MysteryPoi> pois;

  /// The current [MapCamera] used to project [LatLng] → screen offsets.
  final MapCamera camera;

  /// Called when a revealed POI marker is tapped.
  final void Function(MysteryPoi poi)? onRevealedTap;

  @override
  State<MysteryPoiMarkerLayer> createState() => _MysteryPoiMarkerLayerState();
}

class _MysteryPoiMarkerLayerState extends State<MysteryPoiMarkerLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filter to only pois that need a visible marker.
    final visiblePois = widget.pois
        .where((p) => p.state != PoiState.unrevealed)
        .toList(growable: false);

    if (visiblePois.isEmpty) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, _) {
        return Stack(
          children: visiblePois.map(_buildMarker).toList(),
        );
      },
    );
  }

  Widget _buildMarker(MysteryPoi poi) {
    final screenPoint = widget.camera.getOffsetFromOrigin(poi.position);

    if (poi.isRevealed) {
      return _RevealedMarker(
        key: ValueKey('poi_revealed_${poi.id}'),
        screenPoint: screenPoint,
        category: poi.category,
        onTap: widget.onRevealedTap != null
            ? () => widget.onRevealedTap!(poi)
            : null,
      );
    }

    // Hinted state.
    return _HintedMarker(
      key: ValueKey('poi_hinted_${poi.id}'),
      screenPoint: screenPoint,
      pulseProgress: _pulseAnimation.value,
    );
  }
}

// ---------------------------------------------------------------------------
// Revealed marker — category-coloured pin with icon
// ---------------------------------------------------------------------------

class _RevealedMarker extends StatelessWidget {
  const _RevealedMarker({
    super.key,
    required this.screenPoint,
    required this.category,
    this.onTap,
  });

  final Offset screenPoint;
  final String category;
  final VoidCallback? onTap;

  static const double _size = 44.0;
  static const double _bgSize = 36.0;
  static const double _iconSize = 22.0;

  @override
  Widget build(BuildContext context) {
    final config = CategoryPinConfig.forCategory(category);

    return Positioned(
      left: screenPoint.dx - _size / 2,
      top: screenPoint.dy - _size / 2,
      width: _size,
      height: _size,
      child: GestureDetector(
        onTap: onTap,
        child: Center(
          child: Container(
            width: _bgSize,
            height: _bgSize,
            decoration: BoxDecoration(
              color: config.color.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              border: Border.all(
                color: DanderColors.onSurface.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Icon(
                config.icon,
                color: DanderColors.onSurface,
                size: _iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hinted marker — pulsing amber "?" circle
// ---------------------------------------------------------------------------

class _HintedMarker extends StatelessWidget {
  const _HintedMarker({
    super.key,
    required this.screenPoint,
    required this.pulseProgress,
  });

  final Offset screenPoint;
  final double pulseProgress;

  static const double _size = 48.0;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: screenPoint.dx - _size / 2,
      top: screenPoint.dy - _size / 2,
      width: _size,
      height: _size,
      child: CustomPaint(
        painter: MysteryPoiMarkerPainter(
          pois: const [],
          pulseProgress: pulseProgress,
          isSingleMarker: true,
        ),
        child: const Center(
          child: Text(
            '?',
            style: TextStyle(
              color: DanderColors.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painter (also exported for unit testing of shouldRepaint logic)
// ---------------------------------------------------------------------------

/// Custom painter for the pulsing mystery-POI circle.
///
/// When [isSingleMarker] is `true` (used by [_HintedMarker]) it draws a
/// single circle centred in the canvas.  When `false` it is used in tests
/// for [shouldRepaint] verification only; no drawing occurs.
class MysteryPoiMarkerPainter extends CustomPainter {
  const MysteryPoiMarkerPainter({
    required this.pois,
    required this.pulseProgress,
    this.isSingleMarker = false,
  });

  final List<MysteryPoi> pois;
  final double pulseProgress;
  final bool isSingleMarker;

  @override
  void paint(Canvas canvas, Size size) {
    if (!isSingleMarker) return;

    final center = Offset(size.width / 2, size.height / 2);

    // Pulsing halo ring.
    final haloRadius = 12.0 + pulseProgress * 8.0;
    final haloOpacity = (1.0 - pulseProgress).clamp(0.0, 1.0);
    canvas.drawCircle(
      center,
      haloRadius,
      Paint()
        ..color = DanderColors.secondary.withValues(alpha: haloOpacity * 0.5)
        ..style = PaintingStyle.fill,
    );

    // Solid amber fill circle.
    canvas.drawCircle(
      center,
      12,
      Paint()
        ..color = DanderColors.secondary.withValues(alpha: 0.9)
        ..style = PaintingStyle.fill,
    );

    // White border ring.
    canvas.drawCircle(
      center,
      12,
      Paint()
        ..color = DanderColors.onSurface.withValues(alpha: 0.8)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(MysteryPoiMarkerPainter old) {
    return old.pois != pois || old.pulseProgress != pulseProgress;
  }
}
