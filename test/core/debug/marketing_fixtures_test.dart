import 'package:flutter_test/flutter_test.dart';

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

    test('has multiple walked paths for good fog coverage', () {
      expect(fixture.walkedPaths.length, greaterThanOrEqualTo(2));
      final totalPoints = fixture.walkedPaths
          .fold<int>(0, (sum, path) => sum + path.length);
      expect(totalPoints, greaterThan(30));
    });

    test('has at least 2 revealed POIs with names', () {
      final revealed = MidProgressFixture.mysteryPois
          .where((p) => p.state == PoiState.revealed)
          .toList();
      expect(revealed.length, greaterThanOrEqualTo(2));
      for (final poi in revealed) {
        expect(poi.name, isNotNull);
      }
    });

    test('has at least 3 hinted POIs (visible ? markers)', () {
      final hinted = MidProgressFixture.mysteryPois
          .where((p) => p.state == PoiState.hinted)
          .toList();
      expect(hinted.length, greaterThanOrEqualTo(3));
    });

    test('has Discovery entries matching revealed POIs', () {
      final revealed = MidProgressFixture.mysteryPois
          .where((p) => p.state == PoiState.revealed)
          .toList();
      expect(
        MidProgressFixture.discoveries.length,
        equals(revealed.length),
      );
      for (final d in MidProgressFixture.discoveries) {
        expect(d.discoveredAt, isNotNull);
      }
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

    test('has multiple walked paths for wide fog coverage', () {
      expect(fixture.walkedPaths.length, greaterThanOrEqualTo(3));
      final totalPoints = fixture.walkedPaths
          .fold<int>(0, (sum, path) => sum + path.length);
      expect(totalPoints, greaterThan(50));
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

    test('has Discovery entries matching revealed POIs', () {
      final revealed = HighPayoffFixture.mysteryPois
          .where((p) => p.state == PoiState.revealed)
          .toList();
      expect(
        HighPayoffFixture.discoveries.length,
        equals(revealed.length),
      );
      for (final d in HighPayoffFixture.discoveries) {
        expect(d.discoveredAt, isNotNull);
        expect(d.name, isNotEmpty);
      }
    });

    test('has at least 4 hinted POIs (visible ? markers)', () {
      final hinted = HighPayoffFixture.mysteryPois
          .where((p) => p.state == PoiState.hinted)
          .toList();
      expect(hinted.length, greaterThanOrEqualTo(4));
    });
  });
}
