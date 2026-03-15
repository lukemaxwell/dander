import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/analytics/analytics_event.dart';
import 'package:dander/core/analytics/analytics_service.dart';
import 'package:dander/core/zone/zone.dart';
import 'package:dander/core/sharing/share_service.dart';
import 'package:dander/features/sharing/presentation/widgets/turf_share_card.dart';
import 'package:dander/features/sharing/presentation/widgets/turf_share_preview_sheet.dart';

// ---------------------------------------------------------------------------
// Fake ShareService — hand-rolled to avoid mocktail dependency issues
// ---------------------------------------------------------------------------

class _FakeShareService implements ShareService {
  Uint8List? capturedBytes;
  String? capturedSubject;
  bool shouldThrow = false;

  @override
  Future<Uint8List> captureWidget(
    Widget widget, {
    Size size = const Size(1080, 1080),
    double pixelRatio = 3.0,
  }) async {
    if (shouldThrow) throw Exception('capture failed');
    capturedBytes = Uint8List(4);
    return capturedBytes!;
  }

  @override
  Future<void> shareImage(Uint8List imageBytes, {String? subject}) async {
    capturedSubject = subject;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Zone _makeZone({
  String id = 'zone-1',
  String name = 'Hackney',
  int xp = 300,
}) {
  return Zone(
    id: id,
    name: name,
    centre: const LatLng(51.5, -0.08),
    xp: xp,
    createdAt: DateTime(2024, 1, 1),
  );
}

/// Wraps the sheet in a MaterialApp that overrides MediaQuery to disable
/// animations, preventing pending timer failures in widget tests.
Widget _wrap(Widget child) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    builder: (context, navigator) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: navigator ?? const SizedBox.shrink(),
      );
    },
    home: Scaffold(body: child),
  );
}

Future<void> _pumpSheet(
  WidgetTester tester, {
  Zone? zone,
  int streetCount = 42,
  double explorationPct = 0.67,
  _FakeShareService? shareService,
  InMemoryAnalyticsService? analyticsService,
}) async {
  final z = zone ?? _makeZone();
  final svc = shareService ?? _FakeShareService();
  final analytics = analyticsService ?? InMemoryAnalyticsService();

  await tester.pumpWidget(
    _wrap(
      TurfSharePreviewSheet(
        zone: z,
        streetCount: streetCount,
        explorationPct: explorationPct,
        shareService: svc,
        analyticsService: analytics,
      ),
    ),
  );
  // Settle initial build (no animations due to disableAnimations: true).
  await tester.pump();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('TurfSharePreviewSheet', () {
    testWidgets('renders zone name in header', (tester) async {
      await _pumpSheet(tester, zone: _makeZone(name: 'Shoreditch'));

      // The header Text widget with the zone name should appear.
      expect(find.text('Shoreditch'), findsWidgets);
    });

    testWidgets('renders YOUR TURF micro-label', (tester) async {
      await _pumpSheet(tester);

      expect(find.text('YOUR TURF'), findsOneWidget);
    });

    testWidgets('caption field pre-filled with zone name and percentage',
        (tester) async {
      await _pumpSheet(
        tester,
        zone: _makeZone(name: 'Hackney'),
        explorationPct: 0.67,
      );

      // Caption should contain both the rounded percentage and zone name.
      final captionField = find.byType(TextField);
      expect(captionField, findsOneWidget);

      final textField = tester.widget<TextField>(captionField);
      final text = textField.controller?.text ?? '';
      expect(text, contains('67%'));
      expect(text, contains('Hackney'));
    });

    testWidgets('caption rounds correctly at 0%', (tester) async {
      await _pumpSheet(
        tester,
        zone: _makeZone(name: 'Dalston'),
        explorationPct: 0.0,
      );

      final textField =
          tester.widget<TextField>(find.byType(TextField));
      final text = textField.controller?.text ?? '';
      expect(text, contains('0%'));
      expect(text, contains('Dalston'));
    });

    testWidgets('caption rounds correctly at 100%', (tester) async {
      await _pumpSheet(
        tester,
        zone: _makeZone(name: 'Camden'),
        explorationPct: 1.0,
      );

      final textField =
          tester.widget<TextField>(find.byType(TextField));
      final text = textField.controller?.text ?? '';
      expect(text, contains('100%'));
      expect(text, contains('Camden'));
    });

    testWidgets('Share your turf button is present', (tester) async {
      await _pumpSheet(tester);

      expect(find.text('Share your turf →'), findsOneWidget);
    });

    testWidgets('Save to Photos button is present', (tester) async {
      await _pumpSheet(tester);

      expect(find.text('Save to Photos'), findsOneWidget);
    });

    testWidgets('tapping share calls captureWidget and shareImage',
        (tester) async {
      final svc = _FakeShareService();
      final analytics = InMemoryAnalyticsService();

      await _pumpSheet(
        tester,
        shareService: svc,
        analyticsService: analytics,
      );

      // Button may be below the fold — scroll it into view before tapping.
      await tester.ensureVisible(find.text('Share your turf →'));
      await tester.pump();
      await tester.tap(find.text('Share your turf →'));
      // First pump: starts async
      await tester.pump();
      // Second pump: completes futures
      await tester.pump();

      expect(svc.capturedBytes, isNotNull);
      expect(svc.capturedSubject, isNotNull);
    });

    testWidgets('tapping share fires ZoneTurfShared analytics event',
        (tester) async {
      final svc = _FakeShareService();
      final analytics = InMemoryAnalyticsService();

      await _pumpSheet(
        tester,
        zone: _makeZone(name: 'Hackney', xp: 300),
        streetCount: 42,
        explorationPct: 0.67,
        shareService: svc,
        analyticsService: analytics,
      );

      await tester.ensureVisible(find.text('Share your turf →'));
      await tester.pump();
      await tester.tap(find.text('Share your turf →'));
      await tester.pump();
      await tester.pump();

      final turfEvents = analytics.events.whereType<ZoneTurfShared>().toList();
      expect(turfEvents, hasLength(1));
      expect(turfEvents.first.zoneName, equals('Hackney'));
      expect(turfEvents.first.streetCount, equals(42));
    });

    testWidgets('captureWidget throws — error snackbar shown', (tester) async {
      final svc = _FakeShareService()..shouldThrow = true;

      await _pumpSheet(tester, shareService: svc);

      await tester.ensureVisible(find.text('Share your turf →'));
      await tester.pump();
      await tester.tap(find.text('Share your turf →'));
      await tester.pump();
      await tester.pump();

      expect(
        find.text("Couldn't create share image. Try again."),
        findsOneWidget,
      );
    });

    testWidgets(
        'share in progress — ElevatedButton shows CircularProgressIndicator',
        (tester) async {
      // Use a service that hangs indefinitely so _sharingInProgress stays true.
      final hangingSvc = _HangingShareService();
      final analytics = InMemoryAnalyticsService();

      await tester.pumpWidget(
        _wrap(
          TurfSharePreviewSheet(
            zone: _makeZone(),
            streetCount: 10,
            explorationPct: 0.5,
            shareService: hangingSvc,
            analyticsService: analytics,
          ),
        ),
      );
      await tester.pump();

      // Tap share button to trigger _sharingInProgress = true.
      await tester.ensureVisible(find.text('Share your turf →'));
      await tester.pump();
      await tester.tap(find.text('Share your turf →'));
      // One pump: setState(_sharingInProgress = true) fires, rebuilds with spinner.
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('TurfShareCard is present in widget tree', (tester) async {
      await _pumpSheet(tester);

      expect(find.byType(TurfShareCard), findsOneWidget);
    });
  });
}

// ---------------------------------------------------------------------------
// Helper: a ShareService that never completes (for testing in-progress state).
// ---------------------------------------------------------------------------

class _HangingShareService implements ShareService {
  @override
  Future<Uint8List> captureWidget(
    Widget widget, {
    Size size = const Size(1080, 1080),
    double pixelRatio = 3.0,
  }) {
    // Never completes — keeps _sharingInProgress = true.
    return Completer<Uint8List>().future;
  }

  @override
  Future<void> shareImage(Uint8List imageBytes, {String? subject}) async {}
}
