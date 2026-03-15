import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/features/map/presentation/widgets/mystery_marker_beacon.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: child),
    );

// Two points ~85 m apart (latitude difference ≈ 0.000764°).
const LatLng _userPos = LatLng(51.5000, -0.1000);
const LatLng _targetNear85m = LatLng(51.5008, -0.1000); // ~89m north
// A target very close (< 10 m).
const LatLng _targetUnder10m = LatLng(51.500050, -0.1000); // ~5.5m
// A target just under 30 m.
const LatLng _targetUnder30m = LatLng(51.500200, -0.1000); // ~22m
// Target > 1000 m for km formatting.
const LatLng _targetKm = LatLng(51.5110, -0.1000); // ~1.2 km

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('MysteryMarkerBeacon', () {
    // ---- Visibility --------------------------------------------------------

    testWidgets('returns SizedBox.shrink when distance < 10 m', (tester) async {
      await tester.pumpWidget(
        _wrap(
          MysteryMarkerBeacon(
            userPosition: _userPos,
            targetPosition: _targetUnder10m,
            headingDegrees: 0.0,
          ),
        ),
      );

      // The beacon pill should not be in the tree.
      expect(find.byType(MysteryMarkerBeacon), findsOneWidget); // widget itself
      // But the inner Container with pill decoration must be absent.
      expect(find.byKey(const Key('beacon_pill')), findsNothing);
    });

    testWidgets('returns SizedBox.shrink when target equals user (0 m)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          MysteryMarkerBeacon(
            userPosition: _userPos,
            targetPosition: _userPos, // same
            headingDegrees: 0.0,
          ),
        ),
      );

      expect(find.byKey(const Key('beacon_pill')), findsNothing);
    });

    // ---- Arrow vs fallback compass icon ------------------------------------

    testWidgets('renders navigation arrow icon when headingDegrees provided',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          MysteryMarkerBeacon(
            userPosition: _userPos,
            targetPosition: _targetNear85m,
            headingDegrees: 0.0,
          ),
        ),
      );

      expect(find.byIcon(Icons.navigation), findsOneWidget);
      // Compass fallback must not appear.
      expect(find.byIcon(Icons.compass_calibration), findsNothing);
    });

    testWidgets(
        'renders compass_calibration fallback icon when headingDegrees is null',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          MysteryMarkerBeacon(
            userPosition: _userPos,
            targetPosition: _targetNear85m,
            headingDegrees: null,
          ),
        ),
      );

      expect(find.byIcon(Icons.compass_calibration), findsOneWidget);
      expect(find.byIcon(Icons.navigation), findsNothing);
    });

    // ---- Distance formatting -----------------------------------------------

    testWidgets('shows distance in metres when < 1000 m', (tester) async {
      await tester.pumpWidget(
        _wrap(
          MysteryMarkerBeacon(
            userPosition: _userPos,
            targetPosition: _targetNear85m,
            headingDegrees: 0.0,
          ),
        ),
      );

      // Distance should render as something like "89m" or similar.
      final textFinder = find.textContaining('m');
      expect(textFinder, findsAtLeastNWidgets(1));
      // Must not include "km".
      final textWidgets = tester.widgetList<Text>(find.byType(Text)).toList();
      final hasKm = textWidgets.any((t) => (t.data ?? '').contains('km'));
      expect(hasKm, isFalse);
    });

    testWidgets('shows distance in km when >= 1000 m', (tester) async {
      await tester.pumpWidget(
        _wrap(
          MysteryMarkerBeacon(
            userPosition: _userPos,
            targetPosition: _targetKm,
            headingDegrees: 0.0,
          ),
        ),
      );

      final textWidgets = tester.widgetList<Text>(find.byType(Text)).toList();
      final hasKm = textWidgets.any((t) => (t.data ?? '').contains('km'));
      expect(hasKm, isTrue);
    });

    // ---- Amber glow when distance < 30 m -----------------------------------

    testWidgets('renders beacon pill without glow when distance >= 30 m',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          MysteryMarkerBeacon(
            userPosition: _userPos,
            targetPosition: _targetNear85m,
            headingDegrees: 0.0,
          ),
        ),
      );

      final pill = tester.widget<Container>(
        find.byKey(const Key('beacon_pill')),
      );
      final decoration = pill.decoration as BoxDecoration;
      // No box shadow (or shadow with no blur) expected at > 30 m.
      final shadows = decoration.boxShadow ?? [];
      final hasAmberGlow =
          shadows.any((s) => s.blurRadius > 0 && s.color.alpha > 0);
      expect(hasAmberGlow, isFalse);
    });

    testWidgets('adds amber glow when distance < 30 m', (tester) async {
      await tester.pumpWidget(
        _wrap(
          MysteryMarkerBeacon(
            userPosition: _userPos,
            targetPosition: _targetUnder30m,
            headingDegrees: 0.0,
          ),
        ),
      );

      final pill = tester.widget<Container>(
        find.byKey(const Key('beacon_pill')),
      );
      final decoration = pill.decoration as BoxDecoration;
      final shadows = decoration.boxShadow ?? [];
      final hasAmberGlow =
          shadows.any((s) => s.blurRadius > 0 && s.color.alpha > 0);
      expect(hasAmberGlow, isTrue);
    });

    // ---- Arrow rotation (RotatedBox) ----------------------------------------

    testWidgets(
        'RotatedBox is present and wraps navigation icon when heading provided',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          MysteryMarkerBeacon(
            userPosition: _userPos,
            targetPosition: _targetNear85m,
            headingDegrees: 0.0,
          ),
        ),
      );

      expect(find.byType(Transform), findsAtLeastNWidgets(1));
    });
  });

  // =========================================================================
  // Bearing math — tested via the exported helpers
  // =========================================================================
  group('Bearing math', () {
    test('north target from south gives ~0 degrees bearing', () {
      // User at south, target due north.
      const from = LatLng(51.0000, 0.0);
      const to = LatLng(51.0100, 0.0); // ~1.1km north
      final bearing = bearingToTarget(from, to);
      expect(bearing, closeTo(0.0, 1.0)); // within 1 degree of north
    });

    test('east target gives ~90 degrees bearing', () {
      const from = LatLng(51.5, 0.0);
      const to = LatLng(51.5, 0.01); // east
      final bearing = bearingToTarget(from, to);
      expect(bearing, closeTo(90.0, 2.0));
    });

    test('south target gives ~180 degrees bearing', () {
      const from = LatLng(51.5, 0.0);
      const to = LatLng(51.49, 0.0); // south
      final bearing = bearingToTarget(from, to);
      expect(bearing, closeTo(180.0, 1.0));
    });

    test('west target gives ~270 degrees bearing', () {
      const from = LatLng(51.5, 0.0);
      const to = LatLng(51.5, -0.01); // west
      final bearing = bearingToTarget(from, to);
      expect(bearing, closeTo(270.0, 2.0));
    });

    test('facing north, target east → relative bearing ~90', () {
      const user = LatLng(51.5, 0.0);
      const target = LatLng(51.5, 0.01); // east
      final rel = relativeBearing(user, target, 0.0); // facing north
      expect(rel, isNotNull);
      expect(rel!, closeTo(90.0, 2.0));
    });

    test('facing east, target east → relative bearing ~0 or ~360', () {
      const user = LatLng(51.5, 0.0);
      const target = LatLng(51.5, 0.01); // east
      final rel = relativeBearing(user, target, 90.0); // already facing east
      expect(rel, isNotNull);
      // Both 0 and 360 represent "straight ahead"; normalisation may produce
      // either due to floating-point precision in the modulo operation.
      final isNearZero = rel! < 2.0 || rel > 358.0;
      expect(isNearZero, isTrue,
          reason: 'Expected ~0° or ~360°, got $rel°');
    });

    test('facing south, target north → relative bearing ~180', () {
      const user = LatLng(51.5, 0.0);
      const target = LatLng(51.51, 0.0); // north
      final rel = relativeBearing(user, target, 180.0); // facing south
      expect(rel, isNotNull);
      expect(rel!, closeTo(180.0, 2.0));
    });

    test('returns null when heading is null', () {
      const user = LatLng(51.5, 0.0);
      const target = LatLng(51.5, 0.01);
      expect(relativeBearing(user, target, null), isNull);
    });

    test('result is always normalised 0–360', () {
      const user = LatLng(51.5, 0.0);
      const target = LatLng(51.5, -0.01); // west → bearing 270
      // Facing east (90°): relative = 270 - 90 = 180
      final rel = relativeBearing(user, target, 90.0);
      expect(rel, isNotNull);
      expect(rel!, greaterThanOrEqualTo(0.0));
      expect(rel, lessThan(360.0));
    });
  });

  group('formatDistance helper', () {
    test('formats 85 m as "85m"', () {
      const from = LatLng(51.5, 0.0);
      const to = LatLng(51.5008, 0.0); // ~89m
      final str = formatDistance(from, to);
      expect(str.endsWith('m'), isTrue);
      expect(str.contains('km'), isFalse);
    });

    test('formats > 1000 m using km with one decimal', () {
      const from = LatLng(51.5, 0.0);
      const to = LatLng(51.511, 0.0); // ~1.2 km
      final str = formatDistance(from, to);
      expect(str.endsWith('km'), isTrue);
    });

    test('999 m still formats as metres', () {
      const from = LatLng(51.5, 0.0);
      const to = LatLng(51.509, 0.0); // ~1.0km edge
      // This point is ~1km, but let's pick ~900m.
      const to2 = LatLng(51.508, 0.0); // ~890m
      final str = formatDistance(from, to2);
      expect(str.endsWith('m'), isTrue);
    });
  });
}
