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
    // Create a standalone pipeline to render without a display.
    final pipelineOwner = PipelineOwner();

    // Fix (issue 3): `views.first` throws a StateError when the dispatcher has
    // no views (e.g. during cold-start or in headless environments). Use
    // `implicitView` which is guaranteed non-null after binding initialisation
    // and fall back to `views.first` only as a last resort.
    final flutterView =
        ui.PlatformDispatcher.instance.implicitView ??
        WidgetsBinding.instance.platformDispatcher.views.first;

    final renderView = RenderView(
      view: flutterView,
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
        repaintKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;

    // Fix (issue 1): `toImage()` returns a dart:ui Image backed by a GPU
    // texture. It MUST be disposed after use to prevent GPU memory leaks.
    // The try/finally guarantees disposal even when `toByteData` throws.
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final Uint8List bytes;
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw StateError(
          'Failed to capture widget as image: toByteData returned null',
        );
      }
      bytes = byteData.buffer.asUint8List();
    } finally {
      // Always release the GPU texture regardless of outcome.
      image.dispose();
    }

    // Fix (issue 2): Detach the offscreen render tree after capture so the
    // BuildOwner does not retain element references, preventing memory leaks.
    // Steps:
    //   1. finalizeTree() unmounts all elements still in the inactive set.
    //   2. Nulling rootNode detaches the RenderView from the PipelineOwner.
    //   3. renderView.dispose() releases native resources held by the view.
    buildOwner.finalizeTree();
    pipelineOwner.rootNode = null;
    renderView.dispose();

    return bytes;
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
