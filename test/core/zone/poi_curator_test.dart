import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/zone/poi_curator.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Builds a [Discovery] with sensible defaults for tests.
Discovery makeDiscovery({
  String id = 'node/1',
  String name = 'Test Place',
  String category = 'memorial',
  RarityTier rarity = RarityTier.common,
  double lat = 51.5074,
  double lng = -0.1278,
  Map<String, String> osmTags = const {},
}) =>
    Discovery(
      id: id,
      name: name,
      category: category,
      rarity: rarity,
      position: LatLng(lat, lng),
      osmTags: osmTags,
      discoveredAt: null,
    );

/// Creates [count] discoveries spread far enough apart (>100m) to all survive
/// the spacing filter.  Lat offset of 0.001° ≈ 111 m.
List<Discovery> makeSpreadDiscoveries({
  required int count,
  String namePrefix = 'Place',
  String category = 'memorial',
  RarityTier rarity = RarityTier.common,
  Map<String, String> osmTags = const {},
  double baseLat = 51.5,
  double baseLng = -0.1,
}) {
  return List.generate(
    count,
    (i) => makeDiscovery(
      id: 'node/$i',
      name: '$namePrefix $i',
      category: category,
      rarity: rarity,
      lat: baseLat + i * 0.002, // ~222 m apart
      lng: baseLng,
      osmTags: osmTags,
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('PoiCurator.curate()', () {
    // -----------------------------------------------------------------------
    // Empty / trivial inputs
    // -----------------------------------------------------------------------

    test('empty input returns empty output', () {
      expect(PoiCurator.curate([]), isEmpty);
    });

    test('all unnamed POIs returns empty list', () {
      final raw = List.generate(
        10,
        (i) => makeDiscovery(id: 'node/$i', name: ''),
      );
      expect(PoiCurator.curate(raw), isEmpty);
    });

    test('blank-whitespace names are rejected', () {
      final raw = [
        makeDiscovery(id: 'node/1', name: '   '),
        makeDiscovery(id: 'node/2', name: '\t'),
      ];
      expect(PoiCurator.curate(raw), isEmpty);
    });

    // -----------------------------------------------------------------------
    // Budget cap
    // -----------------------------------------------------------------------

    test('50+ diverse discoveries are capped at ≤20 by default', () {
      final raw = makeSpreadDiscoveries(count: 60);
      final result = PoiCurator.curate(raw);
      expect(result.length, lessThanOrEqualTo(20));
    });

    test('custom budget of 5 returns ≤5 results', () {
      final raw = makeSpreadDiscoveries(count: 30);
      final result = PoiCurator.curate(raw, budget: 5);
      expect(result.length, lessThanOrEqualTo(5));
    });

    test('fewer than 20 named, well-spaced POIs all survive', () {
      // Use distinct categories to avoid the per-category cap of 3.
      final categories = ['memorial', 'monument', 'park', 'museum', 'library'];
      final raw = List.generate(8, (i) => makeDiscovery(
        id: 'node/$i',
        name: 'Place $i',
        category: categories[i % categories.length],
        lat: 51.5 + i * 0.002,
      ));
      final result = PoiCurator.curate(raw);
      expect(result.length, equals(8));
    });

    // -----------------------------------------------------------------------
    // Quality scoring
    // -----------------------------------------------------------------------

    test('quality score: wikipedia tag gives +3', () {
      final withWiki = makeDiscovery(
        id: 'node/1',
        name: 'Historic Pub',
        osmTags: const {'wikipedia': 'en:Historic_Pub'},
      );
      final plain = makeDiscovery(
        id: 'node/2',
        name: 'Plain Pub',
        lat: 51.51,
        osmTags: const {},
      );
      // Use budget=1 — higher scored POI should win.
      final result = PoiCurator.curate([plain, withWiki], budget: 1);
      expect(result.single.id, equals('node/1'));
    });

    test('wikidata tag also grants the +3 wiki bonus', () {
      final withWikidata = makeDiscovery(
        id: 'node/1',
        name: 'Wikidata Place',
        osmTags: const {'wikidata': 'Q12345'},
      );
      final plain = makeDiscovery(
        id: 'node/2',
        name: 'Plain Place',
        lat: 51.51,
        osmTags: const {},
      );
      final result = PoiCurator.curate([plain, withWikidata], budget: 1);
      expect(result.single.id, equals('node/1'));
    });

    test('website tag gives +2', () {
      final withWebsite = makeDiscovery(
        id: 'node/1',
        name: 'Web Place',
        osmTags: const {'website': 'https://example.com'},
      );
      final plain = makeDiscovery(
        id: 'node/2',
        name: 'Plain Place',
        lat: 51.51,
        osmTags: const {},
      );
      final result = PoiCurator.curate([plain, withWebsite], budget: 1);
      expect(result.single.id, equals('node/1'));
    });

    test('brand tag gives -2 penalty', () {
      final branded = makeDiscovery(
        id: 'node/1',
        name: 'Starbucks',
        osmTags: const {'brand': 'Starbucks'},
      );
      final independent = makeDiscovery(
        id: 'node/2',
        name: 'Local Cafe',
        lat: 51.51,
        osmTags: const {},
      );
      final result = PoiCurator.curate([branded, independent], budget: 1);
      expect(result.single.id, equals('node/2'));
    });

    test('brand-tagged POIs score lower than independents', () {
      final branded = makeDiscovery(
        id: 'node/branded',
        name: 'Costa Coffee',
        osmTags: const {'brand': 'Costa', 'website': 'https://costa.co.uk'},
      );
      // Score: +2 (website) - 2 (brand) = 0
      final independent = makeDiscovery(
        id: 'node/indie',
        name: 'Corner Cafe',
        lat: 51.51,
        osmTags: const {'opening_hours': 'Mo-Su 08:00-18:00'},
      );
      // Score: +1 (opening_hours) = 1
      final result = PoiCurator.curate([branded, independent], budget: 1);
      expect(result.single.id, equals('node/indie'));
    });

    test('quality score calculation is correct for a known tag combination', () {
      // wikipedia (+3), website (+2), opening_hours (+1), phone (+1),
      // 6 tags > 5 (+1), brand (-2) → total = 6
      final poi = makeDiscovery(
        id: 'node/1',
        name: 'Complex Place',
        osmTags: const {
          'wikipedia': 'en:Something',
          'website': 'https://example.com',
          'opening_hours': 'Mo-Su 09:00-17:00',
          'phone': '+44 20 1234 5678',
          'brand': 'SomeBrand',
          'amenity': 'cafe',
        },
      );
      // Score = 3 + 2 + 1 + 1 + 1 - 2 = 6
      expect(PoiCurator.scoreOf(poi), equals(6));
    });

    test('contact:website counts for the +2 website bonus', () {
      final poi = makeDiscovery(
        id: 'node/1',
        name: 'Place',
        osmTags: const {'contact:website': 'https://example.com'},
      );
      expect(PoiCurator.scoreOf(poi), equals(2));
    });

    test('contact:phone counts for the +1 phone bonus', () {
      final poi = makeDiscovery(
        id: 'node/1',
        name: 'Place',
        osmTags: const {'contact:phone': '+44 20 1234'},
      );
      expect(PoiCurator.scoreOf(poi), equals(1));
    });

    test('tag count > 5 gives +1 bonus', () {
      final poi = makeDiscovery(
        id: 'node/1',
        name: 'Place',
        osmTags: const {
          'a': '1',
          'b': '2',
          'c': '3',
          'd': '4',
          'e': '5',
          'f': '6',
        },
      );
      expect(PoiCurator.scoreOf(poi), equals(1));
    });

    // -----------------------------------------------------------------------
    // Tier budget allocation
    // -----------------------------------------------------------------------

    test('rare POIs get slots before common ones', () {
      // 20 rare + 20 common, all well-spaced. Rare tier has priority so
      // the result must contain more rare than common discoveries.
      final rare = makeSpreadDiscoveries(
        count: 20,
        namePrefix: 'Rare',
        rarity: RarityTier.rare,
      );
      final common = makeSpreadDiscoveries(
        count: 20,
        namePrefix: 'Common',
        rarity: RarityTier.common,
        baseLat: 54.0, // far from rare group to avoid spacing conflicts
      );
      final result = PoiCurator.curate([...common, ...rare]);
      final rareCount = result.where((d) => d.rarity == RarityTier.rare).length;
      final commonCount = result.where((d) => d.rarity == RarityTier.common).length;
      expect(rareCount, greaterThan(commonCount),
          reason: 'Rare tier should claim proportionally more slots than common');
    });

    test('tier overflow rolls remaining slots to next tier down', () {
      // Only 1 rare available; budget=5; remaining slots should fill from common.
      // Use diverse categories to avoid per-category cap.
      final categories = ['park', 'museum', 'library', 'viewpoint', 'artwork'];
      final rare = [
        makeDiscovery(
          id: 'node/rare/0',
          name: 'Rare Place 0',
          category: 'monument',
          rarity: RarityTier.rare,
          lat: 51.5,
        ),
      ];
      final common = List.generate(8, (i) => makeDiscovery(
        id: 'node/common/$i',
        name: 'Common Place $i',
        category: categories[i % categories.length],
        rarity: RarityTier.common,
        lat: 52.5 + i * 0.002,
      ));
      final result = PoiCurator.curate([...rare, ...common], budget: 5);
      expect(result.length, equals(5));
      expect(result.where((d) => d.rarity == RarityTier.rare).length, equals(1));
      expect(result.where((d) => d.rarity == RarityTier.common).length, equals(4));
    });

    // -----------------------------------------------------------------------
    // Category diversity cap
    // -----------------------------------------------------------------------

    test('10 memorials in input → at most 3 in output', () {
      final memorials = makeSpreadDiscoveries(
        count: 10,
        namePrefix: 'Memorial',
        category: 'memorial',
      );
      final result = PoiCurator.curate(memorials);
      final memorialCount = result.where((d) => d.category == 'memorial').length;
      expect(memorialCount, lessThanOrEqualTo(3));
    });

    test('category cap works across mixed categories', () {
      final monuments = makeSpreadDiscoveries(
        count: 5,
        namePrefix: 'Monument',
        category: 'monument',
        baseLat: 51.5,
      );
      final artworks = makeSpreadDiscoveries(
        count: 5,
        namePrefix: 'Artwork',
        category: 'artwork',
        baseLat: 52.5,
      );
      final parks = makeSpreadDiscoveries(
        count: 5,
        namePrefix: 'Park',
        category: 'park',
        baseLat: 53.5,
      );
      final result = PoiCurator.curate([...monuments, ...artworks, ...parks]);

      for (final cat in ['monument', 'artwork', 'park']) {
        final count = result.where((d) => d.category == cat).length;
        expect(count, lessThanOrEqualTo(3),
            reason: 'Category "$cat" should have ≤3 representatives');
      }
    });

    // -----------------------------------------------------------------------
    // Minimum spacing
    // -----------------------------------------------------------------------

    test('two POIs 50m apart → only one survives spacing filter', () {
      // 0.0005° lat ≈ 55 m — within 100 m threshold.
      final a = makeDiscovery(id: 'node/a', name: 'Place A', lat: 51.5, lng: -0.1);
      final b = makeDiscovery(id: 'node/b', name: 'Place B', lat: 51.5005, lng: -0.1);
      final result = PoiCurator.curate([a, b]);
      expect(result.length, equals(1));
    });

    test('spacing filter keeps higher-scored POI of a close pair', () {
      final lowScore = makeDiscovery(
        id: 'node/low',
        name: 'Plain Place',
        lat: 51.5,
        lng: -0.1,
        osmTags: const {},
      );
      final highScore = makeDiscovery(
        id: 'node/high',
        name: 'Wikipedia Place',
        lat: 51.5005, // ~55 m away
        lng: -0.1,
        osmTags: const {'wikipedia': 'en:Something'},
      );
      final result = PoiCurator.curate([lowScore, highScore]);
      expect(result.single.id, equals('node/high'));
    });

    test('two POIs 200m apart both survive spacing filter', () {
      // 0.002° lat ≈ 222 m — beyond 100 m threshold.
      final a = makeDiscovery(id: 'node/a', name: 'Place A', lat: 51.5, lng: -0.1);
      final b = makeDiscovery(id: 'node/b', name: 'Place B', lat: 51.502, lng: -0.1);
      final result = PoiCurator.curate([a, b]);
      expect(result.length, equals(2));
    });

    // -----------------------------------------------------------------------
    // Allowlist filter
    // -----------------------------------------------------------------------

    test('non-allowlisted categories are filtered out', () {
      final cafe = makeDiscovery(id: 'node/1', name: 'Starbucks', category: 'cafe');
      final pub = makeDiscovery(id: 'node/2', name: 'The Crown', category: 'pub', lat: 51.51);
      final memorial = makeDiscovery(id: 'node/3', name: 'War Memorial', category: 'memorial', lat: 51.52);
      final result = PoiCurator.curate([cafe, pub, memorial]);
      expect(result.length, equals(1));
      expect(result.first.category, equals('memorial'));
    });

    test('business POIs (brand tag) are excluded', () {
      final branded = makeDiscovery(
        id: 'node/1',
        name: 'Costa Coffee',
        category: 'memorial', // even with allowlisted category
        osmTags: const {'brand': 'Costa'},
      );
      final normal = makeDiscovery(
        id: 'node/2',
        name: 'War Memorial',
        category: 'memorial',
        lat: 51.51,
      );
      final result = PoiCurator.curate([branded, normal]);
      expect(result.length, equals(1));
      expect(result.first.id, equals('node/2'));
    });

    // -----------------------------------------------------------------------
    // Garden noise filter
    // -----------------------------------------------------------------------

    test('garden without wikipedia/wikidata is filtered out', () {
      final garden = makeDiscovery(
        id: 'node/1',
        name: 'Residential Garden',
        category: 'garden',
      );
      final result = PoiCurator.curate([garden]);
      expect(result, isEmpty);
    });

    test('garden with wikipedia tag survives', () {
      final garden = makeDiscovery(
        id: 'node/1',
        name: 'Kew Gardens',
        category: 'garden',
        osmTags: const {'wikipedia': 'en:Kew_Gardens'},
      );
      final result = PoiCurator.curate([garden]);
      expect(result.length, equals(1));
      expect(result.first.name, equals('Kew Gardens'));
    });

    test('garden with wikidata tag survives', () {
      final garden = makeDiscovery(
        id: 'node/1',
        name: 'Botanical Garden',
        category: 'garden',
        osmTags: const {'wikidata': 'Q12345'},
      );
      final result = PoiCurator.curate([garden]);
      expect(result.length, equals(1));
    });

    test('non-garden categories are not affected by garden filter', () {
      final park = makeDiscovery(
        id: 'node/1',
        name: 'Victoria Park',
        category: 'park',
      );
      final result = PoiCurator.curate([park]);
      expect(result.length, equals(1));
    });

    // -----------------------------------------------------------------------
    // Place of worship higher cap
    // -----------------------------------------------------------------------

    test('place_of_worship allows up to 5 (not default 3)', () {
      final churches = makeSpreadDiscoveries(
        count: 8,
        namePrefix: 'Church',
        category: 'place_of_worship',
      );
      final result = PoiCurator.curate(churches);
      final worshipCount = result.where((d) => d.category == 'place_of_worship').length;
      expect(worshipCount, lessThanOrEqualTo(5));
      expect(worshipCount, greaterThan(3),
          reason: 'place_of_worship should allow more than the default 3 cap');
    });
  });
}
