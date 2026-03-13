import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' show LatLngBounds;
import 'package:latlong2/latlong.dart';

import '../../../../core/fog/fog_grid.dart';
import '../../../../core/fog/fog_painter.dart';
import '../../../../core/fog/fog_texture_generator.dart';
import '../../../../core/theme/app_theme.dart';

/// A widget that renders the fog-of-war overlay over the visible map area.
///
/// It listens to [fogGridNotifier] for reactive grid updates and, when
/// [locationStream] is provided, automatically expands explored areas as new
/// positions arrive.
class FogLayer extends StatefulWidget {
  const FogLayer({
    super.key,
    required this.fogGridNotifier,
    required this.bounds,
    this.locationStream,
    this.exploreRadius = 50.0,
    this.onFogExpanded,
  });

  /// Holds the current [FogGrid] and notifies listeners when it changes.
  final ValueNotifier<FogGrid> fogGridNotifier;

  /// The geographic bounds currently visible on screen.
  final LatLngBounds bounds;

  /// Optional stream of GPS positions that drives automatic exploration.
  final Stream<LatLng>? locationStream;

  /// Radius in meters cleared around each received GPS position.
  final double exploreRadius;

  /// Called when new fog cells are revealed (i.e. territory expanded).
  final VoidCallback? onFogExpanded;

  @override
  State<FogLayer> createState() => _FogLayerState();
}

class _FogLayerState extends State<FogLayer> {
  StreamSubscription<LatLng>? _locationSub;
  ui.Image? _fogTexture;

  /// Default glow: amber at ~18% opacity.
  static const Color _glowColor = Color(0x2EFF8F00);
  static const double _glowSigma = 16.0;

  @override
  void initState() {
    super.initState();
    _subscribeToLocation();
    _generateTexture();
  }

  Future<void> _generateTexture() async {
    final image = await FogTextureGenerator.generate();
    if (mounted) {
      setState(() => _fogTexture = image);
    } else {
      image.dispose();
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

  /// Merges a new position into the fog grid immutably.
  ///
  /// Creates a new [FogGrid] containing all previously explored cells plus the
  /// newly cleared circle, then updates the notifier so listeners rebuild.
  void _onLocationUpdate(LatLng position) {
    final current = widget.fogGridNotifier.value;

    final updated = FogGrid(
      origin: current.origin,
      cellSizeMeters: current.cellSizeMeters,
    );

    // Re-add all existing explored cells efficiently by directly inserting
    // their coordinates — no round-trip through lat/lng needed.
    _copyExploredCells(current, updated);

    // Punch the new circle.
    updated.markExplored(position, widget.exploreRadius);

    // Detect if new cells were actually revealed.
    final expanded = updated.exploredCount > current.exploredCount;

    widget.fogGridNotifier.value = updated;

    if (expanded) {
      widget.onFogExpanded?.call();
    }
  }

  /// Copies explored cells from [src] into [dst] by replaying them.
  ///
  /// Uses the internal [FogGrid.addCell] escape-hatch so we avoid O(n) geo
  /// math.  Falls back to serialisation-based copy if that is unavailable.
  void _copyExploredCells(FogGrid src, FogGrid dst) {
    final bytes = src.toBytes();
    if (bytes.isEmpty) return;

    // Use the public factory to restore the explored set in dst.
    final restored = FogGrid.fromBytes(
      bytes,
      origin: src.origin,
      cellSizeMeters: src.cellSizeMeters,
    );
    // Merge explored cells into dst.
    for (final cell in restored.exploredCells) {
      dst.addCell(cell);
    }
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _fogTexture?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<FogGrid>(
      valueListenable: widget.fogGridNotifier,
      builder: (context, grid, _) {
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
                fogTexture: _fogTexture,
                glowColor: _glowColor,
                glowSigma: _glowSigma,
              ),
              child: const SizedBox.expand(),
            );
          },
        );
      },
    );
  }
}
