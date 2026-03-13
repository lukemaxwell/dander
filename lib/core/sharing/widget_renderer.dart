import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Renders a widget offscreen and returns PNG bytes.
///
/// Wraps the widget in a [RepaintBoundary] inside an offscreen widget tree,
/// then uses [RenderRepaintBoundary.toImage] to capture a PNG.
///
/// Note: This renderer is used in production. Tests use [ShareService] mocks
/// so this class is not exercised in unit tests.
class WidgetRenderer {
  WidgetRenderer._();

  /// Renders [widget] at [size] with the given [pixelRatio] and returns
  /// PNG-encoded [Uint8List].
  ///
  /// Must be called after the Flutter binding is initialised.
  static Future<Uint8List> render(
    Widget widget,
    Size size, {
    double pixelRatio = 3.0,
  }) async {
    final repaintKey = GlobalKey();

    // Build the widget tree into a standalone offscreen view using a
    // RenderView attached to a standalone PipelineOwner.
    final view = OffscreenView(
      repaintKey: repaintKey,
      size: size,
      pixelRatio: pixelRatio,
      child: widget,
    );

    // Use a temporary overlay entry approach with runApp alternative.
    // For test/production we use the global FlutterView approach below.
    return _renderViaRepaintBoundary(repaintKey, view, size, pixelRatio);
  }

  static Future<Uint8List> _renderViaRepaintBoundary(
    GlobalKey repaintKey,
    Widget view,
    Size size,
    double pixelRatio,
  ) async {
    // Create a standalone pipeline to render without a display
    final pipelineOwner = PipelineOwner();

    final renderView = RenderView(
      view: WidgetsBinding.instance.platformDispatcher.views.first,
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints.tight(size),
        devicePixelRatio: pixelRatio,
      ),
    );

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final buildOwner = BuildOwner(focusManager: FocusManager());
    final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: renderView,
      child: RepaintBoundary(
        key: repaintKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: Colors.transparent,
            body: SizedBox(
              width: size.width,
              height: size.height,
              child: view,
            ),
          ),
        ),
      ),
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();

    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    final boundary =
        repaintKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}

/// Wrapper widget used during offscreen rendering.
class OffscreenView extends StatelessWidget {
  const OffscreenView({
    super.key,
    required this.repaintKey,
    required this.size,
    required this.pixelRatio,
    required this.child,
  });

  final GlobalKey repaintKey;
  final Size size;
  final double pixelRatio;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size.width, height: size.height, child: child);
  }
}
