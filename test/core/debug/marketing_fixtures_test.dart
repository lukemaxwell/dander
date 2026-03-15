import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/debug/fixtures/mid_progress_fixture.dart';
import 'package:dander/core/debug/fixtures/high_payoff_fixture.dart';
import 'package:dander/core/zone/mystery_poi.dart';

void main() {
  group('MidProgressFixture', () {
    const fixture = MidProgressFixture();

    test('has correct name', () {
      expect(fixture.name, equals('mid_progress'));
    });

    test('suppresses onboarding', () {
      expect(fixture.suppressOnboarding, isTrue);
    });

    test('has a seed position in Greenwich area', () {
      expect(fixture.seedPosition, isNotNull);
      expect(fixture.seedPosition!.latitude, closeTo(51.477, 0.01));
    });

    test('has walked paths with interesting shape (not a straight line)', () {
      expect(fixture.walkedPaths, isNotEmpty);
      final path = fixture.walkedPaths.first;
      expect(path.length, greaterThan(5));
    });

    test('has at least 1 revealed POI', () {
      final revealed = MidProgressFixture.mysteryPois
          .where((p) => p.state == PoiState.revealed)
          .toList();
      expect(revealed.length, greaterThanOrEqualTo(1));
      for (final poi in revealed) {
        expect(poi.name, isNotNull);
      }
    });

    test('has unrevealed POIs for ? markers', () {
      final unrevealed = MidProgressFixture.mysteryPois
          .where((p) => p.state == PoiState.unrevealed)
          .toList();
      expect(unrevealed.length, greaterThanOrEqualTo(2));
    });

    test('zone has moderate XP', () {
      expect(MidProgressFixture.zone.xp, greaterThan(100));
      expect(MidProgressFixture.zone.xp, lessThan(2000));
    });
  });

  group('HighPayoffFixture', () {
    const fixture = HighPayoffFixture();

    test('has correct name', () {
      expect(fixture.name, equals('high_payoff'));
    });

    test('suppresses onboarding', () {
      expect(fixture.suppressOnboarding, isTrue);
    });

    test('has a seed position in Greenwich area', () {
      expect(fixture.seedPosition, isNotNull);
      expect(fixture.seedPosition!.latitude, closeTo(51.477, 0.01));
    });

    test('has multiple walked paths or a longer route', () {
      final totalPoints = fixture.walkedPaths
          .fold<int>(0, (sum, path) => sum + path.length);
      expect(totalPoints, greaterThan(15));
    });

    test('has more revealed POIs than mid_progress', () {
      final midRevealed = MidProgressFixture.mysteryPois
          .where((p) => p.state == PoiState.revealed)
          .length;
      final highRevealed = HighPayoffFixture.mysteryPois
          .where((p) => p.state == PoiState.revealed)
          .length;
      expect(highRevealed, greaterThan(midRevealed));
    });

    test('has more total POIs than mid_progress', () {
      expect(
        HighPayoffFixture.mysteryPois.length,
        greaterThan(MidProgressFixture.mysteryPois.length),
      );
    });

    test('zone has higher XP than mid_progress', () {
      expect(
        HighPayoffFixture.zone.xp,
        greaterThan(MidProgressFixture.zone.xp),
      );
    });

    test('has multiple discoveries with names', () {
      final revealed = HighPayoffFixture.mysteryPois
          .where((p) => p.state == PoiState.revealed)
          .toList();
      expect(revealed.length, greaterThanOrEqualTo(3));
      for (final poi in revealed) {
        expect(poi.name, isNotNull);
        expect(poi.name, isNotEmpty);
      }
    });
  });
}
