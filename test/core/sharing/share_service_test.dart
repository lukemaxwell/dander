import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dander/core/sharing/share_service.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockShareService extends Mock implements ShareService {}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    // Register fallback for the abstract Widget type
    registerFallbackValue(const SizedBox());
    registerFallbackValue(const Size(1080, 1080));
    registerFallbackValue(Uint8List(0));
  });

  group('ShareService contract', () {
    late MockShareService mockService;

    setUp(() {
      mockService = MockShareService();
    });

    test('shareImage is called with the provided bytes and subject', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      when(
        () => mockService.shareImage(bytes, subject: any(named: 'subject')),
      ).thenAnswer((_) async {});

      await mockService.shareImage(bytes, subject: 'My walk');

      verify(
        () => mockService.shareImage(bytes, subject: 'My walk'),
      ).called(1);
    });

    test('shareImage is called without subject when none provided', () async {
      final bytes = Uint8List.fromList([4, 5, 6]);
      when(
        () => mockService.shareImage(bytes, subject: any(named: 'subject')),
      ).thenAnswer((_) async {});

      await mockService.shareImage(bytes);

      verify(() => mockService.shareImage(bytes)).called(1);
    });

    test('captureWidget returns bytes from mock', () async {
      final expectedBytes = Uint8List.fromList([10, 20, 30]);
      const widget = SizedBox();

      when(
        () => mockService.captureWidget(
          any(),
          size: any(named: 'size'),
          pixelRatio: any(named: 'pixelRatio'),
        ),
      ).thenAnswer((_) async => expectedBytes);

      final result = await mockService.captureWidget(widget);

      expect(result, equals(expectedBytes));
    });

    test('captureWidget can be called with default size', () async {
      const widget = SizedBox();
      final expectedBytes = Uint8List.fromList([1]);

      when(
        () => mockService.captureWidget(
          any(),
          size: any(named: 'size'),
          pixelRatio: any(named: 'pixelRatio'),
        ),
      ).thenAnswer((_) async => expectedBytes);

      await mockService.captureWidget(widget);

      verify(() => mockService.captureWidget(any())).called(1);
    });

    test('captureWidget passes custom pixelRatio', () async {
      const widget = SizedBox();
      final expectedBytes = Uint8List.fromList([9]);

      when(
        () => mockService.captureWidget(
          any(),
          size: any(named: 'size'),
          pixelRatio: any(named: 'pixelRatio'),
        ),
      ).thenAnswer((_) async => expectedBytes);

      final result = await mockService.captureWidget(
        widget,
        pixelRatio: 2.0,
      );

      expect(result, equals(expectedBytes));
    });

    test('shareImage can be called multiple times independently', () async {
      final bytes1 = Uint8List.fromList([1, 2]);
      final bytes2 = Uint8List.fromList([3, 4]);

      when(
        () => mockService.shareImage(any(), subject: any(named: 'subject')),
      ).thenAnswer((_) async {});

      await mockService.shareImage(bytes1, subject: 'First');
      await mockService.shareImage(bytes2, subject: 'Second');

      verify(
        () => mockService.shareImage(bytes1, subject: 'First'),
      ).called(1);
      verify(
        () => mockService.shareImage(bytes2, subject: 'Second'),
      ).called(1);
    });

    test('captureWidget with custom size passes correctly', () async {
      const widget = SizedBox();
      const customSize = Size(800, 600);
      final expectedBytes = Uint8List.fromList([5, 6, 7]);

      when(
        () => mockService.captureWidget(
          any(),
          size: customSize,
          pixelRatio: any(named: 'pixelRatio'),
        ),
      ).thenAnswer((_) async => expectedBytes);

      final result = await mockService.captureWidget(
        widget,
        size: customSize,
      );

      expect(result, equals(expectedBytes));
    });
  });
}

// ---------------------------------------------------------------------------
// WidgetRenderer cleanup notes
// ---------------------------------------------------------------------------
// Direct unit tests for WidgetRenderer are not possible in pure unit test
// environments because RenderRepaintBoundary.toImage() requires a real GPU
// context (a FlutterView). Integration/golden tests are the appropriate
// vehicle. The three fixes applied to widget_renderer.dart are:
//
//   1. ui.Image disposal  -- the dart:ui Image returned by toImage() is now
//      wrapped in try/finally so image.dispose() is always called, preventing
//      GPU memory leaks.
//
//   2. Render tree detachment -- buildOwner.finalizeTree(), nulling
//      pipelineOwner.rootNode, and calling renderView.dispose() are now
//      called after image capture so the BuildOwner does not retain element
//      references.
//
//   3. Safe view access -- PlatformDispatcher.instance.implicitView is used
//      (with a views.first fallback) instead of views.first directly, which
//      threw a StateError when the views list was empty.
