import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' show LatLngBounds;
import 'package:latlong2/latlong.dart';

import '../../../../core/fog/fog_grid.dart';
import '../../../../core/fog/fog_painter.dart';
import '../../../../core/motion/dander_motion.dart';

/// A widget that renders the fog-of-war overlay over the visible map area.
///
/// Listens to [fogGridNotifier] for reactive grid updates and, when
/// [locationStream] is provided, automatically expands explored areas as new
/// positions arrive.
///
/// When [mysteryPois] is non-empty, pulsing markers are drawn in fogged cells
/// to hint at nearby undiscovered POIs. Markers disappear when the surrounding
/// fog is cleared.
///
/// Place this inside [FlutterMap.children] wrapped in a [Builder] so that
/// [bounds] can be sourced from [MapCamera.of(context).visibleBounds] — this
/// keeps the fog perfectly in sync with the map tiles on every render frame.
class FogLayer extends StatefulWidget {
  const FogLayer({
    super.key,
    required this.fogGridNotifier,
    required this.bounds,
    this.locationStream,
    this.exploreRadius = 50.0,
    this.onFogExpanded,
    this.mysteryPois = const [],
  });

  final ValueNotifier<FogGrid> fogGridNotifier;
  final LatLngBounds bounds;
  final Stream<LatLng>? locationStream;
  final double exploreRadius;
  final VoidCallback? onFogExpanded;

  /// Positions of undiscovered POIs — rendered as pulsing fog markers.
  final List<LatLng> mysteryPois;

  @override
  State<FogLayer> createState() => _FogLayerState();
}

class _FogLayerState extends State<FogLayer> with TickerProviderStateMixin {
  StreamSubscription<LatLng>? _locationSub;

  /// Drives the mystery-marker pulse (1.5 s reverse-loop).
  late final AnimationController _pulseController;

  /// Drives the fog boundary shimmer sweep (4 s forward-loop).
  late final AnimationController _shimmerController;

  late final Animation<double> _pulseAnim;
  late final Animation<double> _shimmerAnim;

  bool _reduced = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _pulseAnim = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);
    _shimmerAnim = _shimmerController;

    _subscribeToLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = DanderMotion.isReduced(context);
    if (reduced == _reduced) return;
    _reduced = reduced;
    if (_reduced) {
      _pulseController.stop();
      _shimmerController.stop();
    } else {
      _pulseController.repeat(reverse: true);
      _shimmerController.repeat();
    }
  }

  @override
  void didUpdateWidget(FogLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.locationStream, oldWidget.locationStream)) {
      _locationSub?.cancel();
      _subscribeToLocation();
    }
  }

  void _subscribeToLocation() {
    final stream = widget.locationStream;
    if (stream == null) return;
    _locationSub = stream.listen(_onLocationUpdate);
  }

  void _onLocationUpdate(LatLng position) {
    final current = widget.fogGridNotifier.value;

    final updated = FogGrid(
      origin: current.origin,
      cellSizeMeters: current.cellSizeMeters,
    );

    for (final cell in current.exploredCells) {
      updated.addCell(cell);
    }

    updated.markExplored(position, widget.exploreRadius);

    final expanded = updated.exploredCount > current.exploredCount;
    widget.fogGridNotifier.value = updated;

    if (expanded) widget.onFogExpanded?.call();
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnim, _shimmerAnim]),
      builder: (context, _) {
        return ValueListenableBuilder<FogGrid>(
          valueListenable: widget.fogGridNotifier,
          builder: (context, grid, __) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final viewport = FogViewport(
                  bounds: widget.bounds,
                  canvasSize: Size(
                    constraints.maxWidth.isFinite ? constraints.maxWidth : 1.0,
                    constraints.maxHeight.isFinite ? constraints.maxHeight : 1.0,
                  ),
                );
                return CustomPaint(
                  painter: FogPainter(
                    fogGrid: grid,
                    viewport: viewport,
                    mysteryPois: widget.mysteryPois,
                    pulseValue: _pulseAnim.value,
                    shimmerValue: _shimmerAnim.value,
                    reducedMotion: _reduced,
                  ),
                  child: const SizedBox.expand(),
                );
              },
            );
          },
        );
      },
    );
  }
}
