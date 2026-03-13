import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

import 'widget_renderer.dart';

/// Abstract interface for sharing images, enabling easy mocking in tests.
abstract class ShareService {
  /// Shares [imageBytes] as a PNG via the native share sheet.
  ///
  /// Optional [subject] is used as the share subject on platforms that
  /// support it (e.g. email).
  Future<void> shareImage(Uint8List imageBytes, {String? subject});

  /// Renders [widget] offscreen at [size] and returns PNG bytes.
  ///
  /// [pixelRatio] controls output resolution (default 3.0 = 3x for retina).
  Future<Uint8List> captureWidget(
    Widget widget, {
    Size size = const Size(1080, 1080),
    double pixelRatio = 3.0,
  });
}

/// Production implementation using share_plus and RepaintBoundary
/// offscreen rendering.
class SharePlusService implements ShareService {
  @override
  Future<void> shareImage(Uint8List imageBytes, {String? subject}) async {
    final xFile = XFile.fromData(
      imageBytes,
      name: 'dander-share.png',
      mimeType: 'image/png',
    );
    await Share.shareXFiles([xFile], subject: subject);
  }

  @override
  Future<Uint8List> captureWidget(
    Widget widget, {
    Size size = const Size(1080, 1080),
    double pixelRatio = 3.0,
  }) {
    return WidgetRenderer.render(widget, size, pixelRatio: pixelRatio);
  }
}
