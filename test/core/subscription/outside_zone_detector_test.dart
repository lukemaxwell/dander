import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/subscription/outside_zone_detector.dart';
import 'package:dander/core/zone/zone.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Zone makeZone({
  String id = 'zone_1',
  double centreLat = 51.5074,
  double centreLng = -0.1278,
  int xp = 0,
}) =>
    Zone(
      id: id,
      name: 'Test Zone',
      centre: LatLng(centreLat, centreLng),
      createdAt: DateTime(2026, 1, 1),
      xp: xp,
    );

// A location clearly INSIDE London zone centre (same spot)
const LatLng kInsideLondon = LatLng(51.5074, -0.1278);

// A location ~44m north of the London zone centre.
// Zone at xp=0 already has radiusMeters=500, so this is always inside.
const LatLng kNearLondon = LatLng(51.5078, -0.1278); // ~44m north

// A location clearly outside all zones (Tokyo)
const LatLng kTokyo = LatLng(35.6762, 139.6503);

void main() {
  group('OutsideZoneDetector.isOutside', () {
    test('returns false when location is inside a zone', () {
      // Zone at xp=0 has radiusMeters=500; kNearLondon is ~44m away — inside.
      final zone = makeZone(xp: 0);
      final result = OutsideZoneDetector.isOutside(kNearLondon, [zone]);
      expect(result, isFalse);
    });

    test('returns false when location is exactly at zone centre', () {
      final zone = makeZone();
      final result = OutsideZoneDetector.isOutside(kInsideLondon, [zone]);
      expect(result, isFalse);
    });

    test('returns true when location is outside all zones', () {
      final zone = makeZone(); // London zone, radius ~50m at xp=0
      final result = OutsideZoneDetector.isOutside(kTokyo, [zone]);
      expect(result, isTrue);
    });

    test('returns false when zones list is empty', () {
      final result = OutsideZoneDetector.isOutside(kTokyo, const []);
      expect(result, isFalse);
    });

    test('returns false when location is inside one of multiple zones', () {
      final londonZone = makeZone(id: 'london', xp: 0); // 500m radius
      final tokyoZone = makeZone(
        id: 'tokyo',
        centreLat: 35.6762,
        centreLng: 139.6503,
      );
      // kNearLondon is inside londonZone
      final result = OutsideZoneDetector.isOutside(
        kNearLondon,
        [londonZone, tokyoZone],
      );
      expect(result, isFalse);
    });

    test('returns true when location is outside all of multiple zones', () {
      final londonZone = makeZone(id: 'london', xp: 0);
      final parisZone = makeZone(
        id: 'paris',
        centreLat: 48.8566,
        centreLng: 2.3522,
      );
      // Tokyo is far from both London and Paris
      final result = OutsideZoneDetector.isOutside(
        kTokyo,
        [londonZone, parisZone],
      );
      expect(result, isTrue);
    });

    test('location very far outside a single zone returns true', () {
      final zone = makeZone(xp: 0); // 50m radius
      // Barcelona is ~1000km from London
      const barcelona = LatLng(41.3851, 2.1734);
      final result = OutsideZoneDetector.isOutside(barcelona, [zone]);
      expect(result, isTrue);
    });
  });
}
