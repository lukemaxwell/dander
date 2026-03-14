import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:dander/core/compass/compass_charges.dart';
import 'package:dander/core/compass/compass_charges_repository.dart';

void main() {
  group('CompassCharges', () {
    group('constants', () {
      test('maxCharges is 3', () {
        expect(CompassCharges.maxCharges, 3);
      });

      test('metersPerCharge is 500.0', () {
        expect(CompassCharges.metersPerCharge, 500.0);
      });
    });

    group('defaults', () {
      test('currentCharges defaults to 1 (lead-in charge)', () {
        const charges = CompassCharges();
        expect(charges.currentCharges, 1);
      });

      test('metersSinceLastCharge defaults to 0.0', () {
        const charges = CompassCharges();
        expect(charges.metersSinceLastCharge, 0.0);
      });
    });

    group('canSpend', () {
      test('returns false when currentCharges is 0', () {
        const charges = CompassCharges(currentCharges: 0);
        expect(charges.canSpend, isFalse);
      });

      test('returns true when currentCharges is 1', () {
        const charges = CompassCharges(currentCharges: 1);
        expect(charges.canSpend, isTrue);
      });

      test('returns true when currentCharges is maxCharges', () {
        const charges = CompassCharges(currentCharges: CompassCharges.maxCharges);
        expect(charges.canSpend, isTrue);
      });
    });

    group('earnFromDistance', () {
      test('earn exactly 1 charge from 500m with 0 remainder', () {
        const charges = CompassCharges(currentCharges: 0);
        final result = charges.earnFromDistance(500.0);
        expect(result.currentCharges, 1);
        expect(result.metersSinceLastCharge, 0.0);
      });

      test('earn 2 charges from 1100m with 100m remainder', () {
        const charges = CompassCharges(currentCharges: 0);
        final result = charges.earnFromDistance(1100.0);
        expect(result.currentCharges, 2);
        expect(result.metersSinceLastCharge, closeTo(100.0, 0.001));
      });

      test('earning beyond max 3 caps at 3', () {
        const charges = CompassCharges(currentCharges: 2);
        final result = charges.earnFromDistance(2000.0);
        expect(result.currentCharges, CompassCharges.maxCharges);
      });

      test('partial distance 499m earns 0 charges but tracks 499m remainder', () {
        const charges = CompassCharges(currentCharges: 0);
        final result = charges.earnFromDistance(499.0);
        expect(result.currentCharges, 0);
        expect(result.metersSinceLastCharge, closeTo(499.0, 0.001));
      });

      test('partial distances accumulate: 499m then 100m earns 1 charge with 99m remainder', () {
        const charges = CompassCharges(currentCharges: 0);
        final afterFirst = charges.earnFromDistance(499.0);
        expect(afterFirst.currentCharges, 0);
        expect(afterFirst.metersSinceLastCharge, closeTo(499.0, 0.001));

        final afterSecond = afterFirst.earnFromDistance(100.0);
        expect(afterSecond.currentCharges, 1);
        expect(afterSecond.metersSinceLastCharge, closeTo(99.0, 0.001));
      });

      test('earning 0 meters changes nothing', () {
        const charges = CompassCharges(currentCharges: 1, metersSinceLastCharge: 250.0);
        final result = charges.earnFromDistance(0.0);
        expect(result.currentCharges, 1);
        expect(result.metersSinceLastCharge, closeTo(250.0, 0.001));
      });

      test('accumulates partial meters when starting from existing remainder', () {
        const charges = CompassCharges(currentCharges: 0, metersSinceLastCharge: 300.0);
        final result = charges.earnFromDistance(300.0);
        expect(result.currentCharges, 1);
        expect(result.metersSinceLastCharge, closeTo(100.0, 0.001));
      });

      test('does not mutate original instance', () {
        const charges = CompassCharges(currentCharges: 0);
        charges.earnFromDistance(1000.0);
        expect(charges.currentCharges, 0);
        expect(charges.metersSinceLastCharge, 0.0);
      });

      test('caps at maxCharges when already at max, remainder still updates', () {
        const charges = CompassCharges(
          currentCharges: CompassCharges.maxCharges,
          metersSinceLastCharge: 0.0,
        );
        final result = charges.earnFromDistance(500.0);
        expect(result.currentCharges, CompassCharges.maxCharges);
      });
    });

    group('spend', () {
      test('reduces currentCharges by 1', () {
        const charges = CompassCharges(currentCharges: 2);
        final result = charges.spend();
        expect(result.currentCharges, 1);
      });

      test('reduces from 1 to 0', () {
        const charges = CompassCharges(currentCharges: 1);
        final result = charges.spend();
        expect(result.currentCharges, 0);
      });

      test('throws StateError when charges is 0', () {
        const charges = CompassCharges(currentCharges: 0);
        expect(() => charges.spend(), throwsStateError);
      });

      test('does not mutate original instance', () {
        const charges = CompassCharges(currentCharges: 3);
        charges.spend();
        expect(charges.currentCharges, 3);
      });

      test('preserves metersSinceLastCharge after spend', () {
        const charges = CompassCharges(currentCharges: 2, metersSinceLastCharge: 250.0);
        final result = charges.spend();
        expect(result.metersSinceLastCharge, closeTo(250.0, 0.001));
      });
    });

    group('JSON serialization', () {
      test('toJson contains expected keys', () {
        const charges = CompassCharges(currentCharges: 2, metersSinceLastCharge: 150.0);
        final json = charges.toJson();
        expect(json, contains('currentCharges'));
        expect(json, contains('metersSinceLastCharge'));
      });

      test('round-trip preserves currentCharges and metersSinceLastCharge', () {
        const charges = CompassCharges(currentCharges: 2, metersSinceLastCharge: 150.0);
        final json = charges.toJson();
        final restored = CompassCharges.fromJson(json);
        expect(restored.currentCharges, charges.currentCharges);
        expect(restored.metersSinceLastCharge, closeTo(charges.metersSinceLastCharge, 0.001));
      });

      test('round-trip with defaults (1 charge, 0.0 meters)', () {
        const charges = CompassCharges();
        final json = charges.toJson();
        final restored = CompassCharges.fromJson(json);
        expect(restored.currentCharges, 1);
        expect(restored.metersSinceLastCharge, 0.0);
      });

      test('round-trip with maxCharges', () {
        const charges = CompassCharges(currentCharges: CompassCharges.maxCharges);
        final json = charges.toJson();
        final restored = CompassCharges.fromJson(json);
        expect(restored.currentCharges, CompassCharges.maxCharges);
      });

      test('toJson encodes currentCharges as int', () {
        const charges = CompassCharges(currentCharges: 1);
        final json = charges.toJson();
        expect(json['currentCharges'], isA<int>());
      });

      test('toJson encodes metersSinceLastCharge as double', () {
        const charges = CompassCharges(metersSinceLastCharge: 123.45);
        final json = charges.toJson();
        expect(json['metersSinceLastCharge'], isA<double>());
      });
    });
  });

  group('HiveCompassChargesRepository', () {
    late Box<dynamic> box;
    late HiveCompassChargesRepository repo;

    setUp(() async {
      Hive.init(
        '/tmp/hive_compass_charges_test_${DateTime.now().millisecondsSinceEpoch}',
      );
      box = await Hive.openBox('compass_charges_test');
      repo = HiveCompassChargesRepository.withBox(box);
    });

    tearDown(() async {
      await box.close();
    });

    group('abstract interface', () {
      test('HiveCompassChargesRepository satisfies CompassChargesRepository contract', () {
        expect(repo, isA<CompassChargesRepository>());
      });
    });

    group('load', () {
      test('returns default CompassCharges when box is empty', () async {
        final loaded = await repo.load();
        expect(loaded.currentCharges, 1);
        expect(loaded.metersSinceLastCharge, 0.0);
      });
    });

    group('save and load round-trip', () {
      test('saves and loads charges with non-default values', () async {
        const charges = CompassCharges(currentCharges: 2, metersSinceLastCharge: 250.0);
        await repo.save(charges);

        final loaded = await repo.load();
        expect(loaded.currentCharges, 2);
        expect(loaded.metersSinceLastCharge, closeTo(250.0, 0.001));
      });

      test('saves and loads default charges', () async {
        const charges = CompassCharges();
        await repo.save(charges);

        final loaded = await repo.load();
        expect(loaded.currentCharges, 1);
        expect(loaded.metersSinceLastCharge, 0.0);
      });

      test('overwrites previous save with new values', () async {
        await repo.save(const CompassCharges(currentCharges: 1));
        await repo.save(const CompassCharges(currentCharges: 3, metersSinceLastCharge: 400.0));

        final loaded = await repo.load();
        expect(loaded.currentCharges, 3);
        expect(loaded.metersSinceLastCharge, closeTo(400.0, 0.001));
      });
    });
  });
}
