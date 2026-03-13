import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' show LatLngBounds;
import 'package:latlong2/latlong.dart';

import '../../../../core/fog/fog_grid.dart';
import '../../../../core/fog/fog_painter.dart';

/// A widget that renders the fog-of-war overlay over the visible map area.
///
/// Listens to [fogGridNotifier] for reactive grid updates and, when
/// [locationStream] is provided, automatically expands explored areas as new
/// positions arrive.
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
  });

  final ValueNotifier<FogGrid> fogGridNotifier;
  final LatLngBounds bounds;
  final Stream<LatLng>? locationStream;
  final double exploreRadius;
  final VoidCallback? onFogExpanded;

  @override
  State<FogLayer> createState() => _FogLayerState();
}

class _FogLayerState extends State<FogLayer> {
  StreamSubscription<LatLng>? _locationSub;

  @override
  void initState() {
    super.initState();
    _subscribeToLocation();
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
              painter: FogPainter(fogGrid: grid, viewport: viewport),
              child: const SizedBox.expand(),
            );
          },
        );
      },
    );
  }
}
