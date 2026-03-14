import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/location/walk_session.dart';
import 'package:dander/features/walk/domain/models/weekly_summary.dart';

void main() {
  group('WeeklySummary', () {
    test('creates from empty walk list', () {
      final summary = WeeklySummary.fromWalks(
        walks: const [],
        weekStart: DateTime(2026, 3, 9), // Monday
        fogClearedPercent: 5.0,
      );

      expect(summary.totalWalks, 0);
      expect(summary.totalDistanceMetres, 0);
      expect(summary.totalDuration, Duration.zero);
      expect(summary.totalDiscoveries, 0);
    });

    test('aggregates distance from multiple walks', () {
      final walks = [
        _makeWalk(
          id: 'w1',
          start: DateTime(2026, 3, 10, 8, 0),
          end: DateTime(2026, 3, 10, 8, 30),
          points: [
            const LatLng(51.5, -0.1),
            const LatLng(51.501, -0.1), // ~111m north
          ],
        ),
        _makeWalk(
          id: 'w2',
          start: DateTime(2026, 3, 11, 9, 0),
          end: DateTime(2026, 3, 11, 9, 15),
          points: [
            const LatLng(51.5, -0.1),
            const LatLng(51.502, -0.1), // ~222m north
          ],
        ),
      ];

      final summary = WeeklySummary.fromWalks(
        walks: walks,
        weekStart: DateTime(2026, 3, 9),
        fogClearedPercent: 5.0,
      );

      expect(summary.totalWalks, 2);
      expect(summary.totalDistanceMetres, greaterThan(200));
    });

    test('aggregates duration from multiple walks', () {
      final walks = [
        _makeWalk(
          id: 'w1',
          start: DateTime(2026, 3, 10, 8, 0),
          end: DateTime(2026, 3, 10, 8, 30),
          points: [const LatLng(51.5, -0.1)],
        ),
        _makeWalk(
          id: 'w2',
          start: DateTime(2026, 3, 11, 9, 0),
          end: DateTime(2026, 3, 11, 9, 45),
          points: [const LatLng(51.5, -0.1)],
        ),
      ];

      final summary = WeeklySummary.fromWalks(
        walks: walks,
        weekStart: DateTime(2026, 3, 9),
        fogClearedPercent: 5.0,
      );

      expect(summary.totalDuration, const Duration(minutes: 75));
    });

    test('weekStart is the Monday of the week', () {
      final summary = WeeklySummary.fromWalks(
        walks: const [],
        weekStart: DateTime(2026, 3, 9),
        fogClearedPercent: 2.0,
      );

      expect(summary.weekStart.weekday, DateTime.monday);
    });

    test('totalDistanceKm converts correctly', () {
      final summary = WeeklySummary(
        weekStart: DateTime(2026, 3, 9),
        totalWalks: 1,
        totalDistanceMetres: 2500,
        totalDuration: const Duration(minutes: 30),
        totalDiscoveries: 0,
        fogClearedPercent: 1.0,
        activeDays: 1,
        currentStreak: 1,
      );

      expect(summary.totalDistanceKm, closeTo(2.5, 0.01));
    });

    test('activeDays counts unique walk days', () {
      final walks = [
        _makeWalk(
          id: 'w1',
          start: DateTime(2026, 3, 10, 8, 0),
          end: DateTime(2026, 3, 10, 8, 30),
          points: [const LatLng(51.5, -0.1)],
        ),
        _makeWalk(
          id: 'w2',
          start: DateTime(2026, 3, 10, 14, 0), // Same day
          end: DateTime(2026, 3, 10, 14, 30),
          points: [const LatLng(51.5, -0.1)],
        ),
        _makeWalk(
          id: 'w3',
          start: DateTime(2026, 3, 12, 9, 0), // Different day
          end: DateTime(2026, 3, 12, 9, 30),
          points: [const LatLng(51.5, -0.1)],
        ),
      ];

      final summary = WeeklySummary.fromWalks(
        walks: walks,
        weekStart: DateTime(2026, 3, 9),
        fogClearedPercent: 5.0,
      );

      expect(summary.activeDays, 2);
    });

    test('estimatedSteps sums from walk sessions', () {
      final walks = [
        _makeWalk(
          id: 'w1',
          start: DateTime(2026, 3, 10, 8, 0),
          end: DateTime(2026, 3, 10, 8, 30),
          points: [
            const LatLng(51.5, -0.1),
            const LatLng(51.501, -0.1),
          ],
        ),
      ];

      final summary = WeeklySummary.fromWalks(
        walks: walks,
        weekStart: DateTime(2026, 3, 9),
        fogClearedPercent: 5.0,
      );

      expect(summary.estimatedSteps, greaterThan(0));
    });
  });
}

WalkSession _makeWalk({
  required String id,
  required DateTime start,
  required DateTime end,
  required List<LatLng> points,
}) {
  var session = WalkSession.start(id: id, startTime: start);
  for (final point in points) {
    session = session.addPoint(
      WalkPoint(position: point, timestamp: start),
    );
  }
  return session.completeAt(end);
}
