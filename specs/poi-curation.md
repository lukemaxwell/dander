# SPEC: POI Curation System

## Goal
Curate Overpass API results into a small, high-quality set of genuinely interesting discoveries per zone — making each find feel like a surprise rather than a census of every amenity.

## Non-goals
- Changing the Overpass query itself (we still fetch broadly, then filter locally)
- Server-side curation or any backend service
- User-facing configuration of curation parameters
- Changing the existing `RarityClassifier` tier structure beyond adding `legendary`

## Users / scenario
A walker exploring their zone. They see "18 discoveries waiting" instead of "162". Each discovery they find feels intentional — a hidden pub, a viewpoint they didn't know existed, a piece of street art. Common chain shops and unnamed nodes are filtered out. Finding a rare/legendary POI feels special because there are only 1-2 per zone.

## Requirements (must)
- [ ] **Quality filter**: Reject POIs without a name (unnamed OSM nodes are not interesting)
- [ ] **Quality scoring**: Score remaining POIs by richness of OSM metadata (wikipedia, website, opening_hours, tag count)
- [ ] **Category diversity cap**: Max 3 POIs per category per zone — forces variety
- [ ] **Minimum spacing**: No two curated POIs within 100m of each other — prevents clustering
- [ ] **Rarity tier: legendary**: Add a 4th tier above `rare` for POIs with wikipedia/wikidata tags or heritage designation
- [ ] **Target budget**: ~20 POIs per zone (configurable constant), allocated across tiers:
  - Legendary: 1-2
  - Rare: 3-4
  - Uncommon: 5-6
  - Common: 8-10
- [ ] **PoiCurator class**: Pure function that takes `List<Discovery>` and returns curated `List<Discovery>`, applying all filters and caps
- [ ] **Wire into MysteryPoiService.generatePois()**: Apply curation after Overpass fetch, before capping at `_maxActivePois`
- [ ] **Drip-feed waves**: Only ~8 POIs active initially. When >=50% discovered, unlock next wave from the curated set
- [ ] **Persist full curated set**: Store all ~20 curated POIs per zone (not just the active 3), so waves can draw from the pool

## Nice-to-haves
- [ ] Legendary POI gets a distinct pin style (gold border, sparkle) in MysteryPoiMarkerLayer
- [ ] Discovery notification shows rarity tier badge ("Legendary find!")
- [ ] Chain/brand detection to deprioritise (Starbucks, Costa, etc.)

## Acceptance criteria (definition of done)
- [ ] A zone with 162 raw Overpass results produces ~20 curated POIs
- [ ] No two curated POIs are within 100m of each other
- [ ] No category has more than 3 representatives
- [ ] POIs without names are excluded
- [ ] POIs with wikipedia tags are classified as legendary
- [ ] `PoiCurator` is a pure, testable class with no side effects
- [ ] Existing tests continue to pass
- [ ] "X discoveries waiting" counter reflects curated count, not raw Overpass count

## Risks / constraints
- Overpass data quality varies by area — some zones may have <20 quality POIs after filtering. Curator must gracefully return fewer if the pool is thin.
- Changing rarity tiers affects the existing `RarityTier` enum — needs backward-compatible serialization (add `legendary` to enum, existing `fromJson` must handle missing value).
- Wave system changes how `_maxActivePois` works — currently a flat cap of 3, needs to become wave-aware.

## Issue breakdown

### Issue A: `PoiCurator` — quality filter, scoring, diversity caps, spacing
New class in `lib/core/zone/poi_curator.dart`. Takes raw `List<Discovery>`, returns curated `List<Discovery>`. Implements: name filter, quality scoring, category diversity cap (max 3), minimum spacing (100m), tier budget allocation. Pure function, fully unit tested.

### Issue B: `RarityTier.legendary` — add 4th rarity tier
Add `legendary` to enum. Update `RarityClassifier` to promote POIs with `wikipedia`, `wikidata`, or `heritage` tags to legendary. Update serialization for backward compat. Update `CategoryPinConfig` if needed for legendary visual treatment.

### Issue C: Wave system — drip-feed POI activation
New `PoiWaveManager` or extend `MysteryPoiService` to track waves. Store full curated set per zone. Active wave = first ~8. Unlock next wave when >=50% of current wave discovered. Persist wave state.

### Issue D: Wire curation into `MysteryPoiService.generatePois()`
Call `PoiCurator.curate()` on Overpass results before selecting active POIs. Update `totalCount` to reflect curated count. Update `loadOrGenerate` to persist full curated set.

## PR discipline
- Branch → PR only
- PR body includes: `Closes #…` / `Fixes #…`
- Commands to run:
  - `flutter analyze`
  - `dart format --set-exit-if-changed .`
  - `flutter test`
