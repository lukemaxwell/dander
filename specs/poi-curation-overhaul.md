# POI Curation Overhaul

**Status:** Validated — ready for implementation
**Date:** 2025-03-15
**Trigger:** User discovered a "cafe" that was actually a shop. OSM data accuracy is insufficient for consumer-facing discovery.

---

## Problem

The app sources POIs from OpenStreetMap via the Overpass API and presents them as mystery discoveries. Several data quality issues make this unreliable:

1. **Inaccurate business tags** — OSM `amenity` values can be outdated or wrong (a shop tagged as `amenity=cafe`)
2. **Street furniture noise** — raw queries return benches, bins, bike racks (840 POIs in test area, 142 were benches)
3. **Missing area features** — parks, gardens, nature reserves are mapped as `way`/`relation` in OSM but the app only queries `node`, so they never appear
4. **No verification layer** — once a POI is classified, there's no cross-reference or user correction mechanism

## Proposed Solution

Replace the current "fetch everything, filter loosely" approach with a **curated category allowlist** and **extended Overpass query**.

### 1. Category Allowlist

Only surface POIs in categories we've vetted as stable, interesting, and unlikely to be miscategorised:

| Group | Categories | Source tag |
|-------|-----------|------------|
| Historic & heritage | monument, memorial, castle, ruins, archaeological_site, battlefield, manor, city_gate, wayside_cross, wayside_shrine | `historic` |
| Art & culture | artwork, museum, gallery, sculpture | `tourism`, `amenity` |
| Scenic & nature | viewpoint, nature_reserve, park, garden | `tourism`, `leisure` |
| Community & civic | community_centre, library, public_bookcase, place_of_worship, fountain, clock, drinking_water | `amenity`, `leisure` |
| Information | information (boards, trail markers) | `tourism` |

**Excluded:** All commercial businesses (cafes, restaurants, pubs, shops, banks, etc.). These may be added later as a curated/monetised layer using a verified data source.

### 2. Extended Overpass Query

Current query fetches `node` only. Must extend to `way` and `relation` with `out center` to capture area features like parks.

**Impact measured (Ogilvie Terrace, Edinburgh, 1km radius):**

| Metric | Node-only | Node + Way + Relation |
|--------|-----------|----------------------|
| Raw POIs | 840 | 4,413 |
| Allowlisted (named) | 25 | 61 |
| Parks | 0 | 10 |
| Places of worship | 1 | 13 |
| Legendary tier | 1 | 8 |

### 3. Name-required filter

POIs without a name are excluded. This is already enforced by `PoiCurator` but is critical — 3,039 of 3,108 allowlisted results in the test area were unnamed residential garden polygons.

---

## Validation Status

### Completed

- [x] Audit script created (`scripts/poi_audit.py`) with `--allowlist-only` and batch modes
- [x] **30 locations tested** (20 UK + 10 US) across all area types
- [x] **Adaptive radius validated** at 750m default with density-floor expansion

### Zone Radius Decision

The app previously hardcoded `500.0` in `map_screen.dart` with no documented reasoning. Product analysis determined the optimal radius based on two constraints:

1. **Session pacing** — a zone should take 3–5 walking sessions (20–30 min each) to complete, creating goal-gradient return triggers
2. **POI density** — the wave system needs ~15–20 named POIs to sustain 3 waves

| Radius | Walk-across time | Sessions to explore | POI coverage |
|--------|-----------------|--------------------:|-------------|
| 500m | ~10 min | 1–2 | Thin in rural/suburban |
| 750m | ~15 min | 3–4 | Adequate most places |
| 1000m | ~20 min | 4–7 | Comfortable everywhere |

**Decision: 750m default with adaptive density floor.**

```
if (poiCount at 750m >= 15) → use 750m
else if (poiCount at 1000m >= 10) → use 1000m
else → use 1500m
```

This ensures consistent session pacing across all geography types without penalising users in POI-rich areas with oversized zones.

### Validation Results — 750m Radius

Borderline locations re-tested at 750m to validate the density floor:

| Location | Type | @1000m | @750m | Action |
|----------|------|-------:|------:|--------|
| Innerleithen | rural_village | 10 | 10 | Expand → 1000m |
| Aviemore | highland_village | 10 | 9 | Expand → 1000m |
| Glencoe | remote_rural | 12 | 8 | Expand → 1000m |
| Durness | remote_rural | 2 | 0 | Expand → 1500m |
| Scottsdale | suburban | 22 | 18 | 750m OK |
| Woodstock VT | rural_village | 25 | 22 | 750m OK |
| Corstorphine | suburban | 27 | 17 | 750m OK |
| Dunfermline | small_town | 38 | 29 | 750m OK |
| Slough | urban_deprived | 31 | 17 | 750m OK |

**Result:** 750m works for all urban, suburban, and small-town locations. Only remote rural/Highland locations need expansion — the density floor handles these automatically.

### Full Test Results — 1000m Radius (30 locations)

*Note: initial audit was run at 1000m. Results at this radius remain valid as the upper bound for the adaptive system.*

**UK (20 locations):**

| Location | Area Type | Named POIs | Verdict |
|----------|-----------|----------:|---------|
| Ogilvie Terrace Edinburgh | urban_residential | 61 | GOOD |
| Edinburgh Old Town | dense_urban | 328 | GOOD |
| Corstorphine Edinburgh | suburban | 27 | GOOD |
| Dunfermline | small_town | 38 | GOOD |
| Innerleithen | rural_village | 10 | ADEQUATE |
| South Queensferry | new_build_suburb | 40 | GOOD |
| Fort William | highland_town | 36 | GOOD |
| Durness | remote_rural | 2 | SPARSE |
| Aviemore | highland_village | 10 | ADEQUATE |
| Glencoe | remote_rural | 12 | ADEQUATE |
| Westminster London | dense_urban | 341 | GOOD |
| Tower of London City | dense_urban_historic | 342 | GOOD |
| Hackney Central London | urban_mixed | 116 | GOOD |
| Barking East London | urban_deprived | 42 | GOOD |
| Tottenham North London | urban_deprived | 44 | GOOD |
| Croydon South London | outer_suburban | 52 | GOOD |
| Manchester City Centre | dense_urban | 119 | GOOD |
| Milton Keynes | new_town | 95 | GOOD |
| Slough | urban_deprived | 31 | GOOD |
| Birmingham City Centre | urban_mixed | 340 | GOOD |

**US (10 locations):**

| Location | Area Type | Named POIs | Verdict |
|----------|-----------|----------:|---------|
| Manhattan Midtown NYC | dense_urban | 128 | GOOD |
| Brooklyn Williamsburg | urban_mixed | 100 | GOOD |
| Detroit Downtown | urban_deprived | 80 | GOOD |
| San Francisco Mission | urban_mixed | 81 | GOOD |
| Woodstock Vermont | rural_village | 25 | GOOD |
| Scottsdale Phoenix | suburban | 22 | GOOD |
| New Orleans French Quarter | dense_urban_historic | 118 | GOOD |
| Chicago Loop | dense_urban | 164 | GOOD |
| Portland Oregon | urban_mixed | 199 | GOOD |
| Austin Texas | dense_urban | 212 | GOOD |

**Key findings:**
- 27/30 locations pass at 1000m with 20+ POIs; all 10 US locations pass
- "Urban deprived" areas perform well — Barking (42), Tottenham (44), Detroit (80)
- New-build areas surprised — Milton Keynes (95), South Queensferry (40)
- Dense urban areas have massive pools — Birmingham (340), Westminster (341), Austin (212)
- Top categories across all locations: place_of_worship, memorial, artwork, park, information
- Only genuinely remote Highland locations (population < 500) fall below threshold

### Validation Checklist

- [x] **Dense urban** — Edinburgh Old Town (328), Westminster (341), Manchester (119), Birmingham (340), Chicago (164), Austin (212). Quality verified.
- [x] **Suburban** — Corstorphine (17@750m), Croydon (52@1km), Scottsdale (18@750m). Wave system achievable without businesses.
- [x] **Small town** — Dunfermline (29@750m), Fort William (36@1km). Historic sites carry the count.
- [x] **Rural village** — Innerleithen (10), Aviemore (9@750m), Woodstock VT (22@750m). Density floor expansion handles sparse cases.
- [x] **New-build suburb** — South Queensferry (40), Milton Keynes (95). Better than expected.
- [x] **Urban deprived** — Barking (42), Tottenham (44), Slough (17@750m), Detroit (80). Community and heritage assets well-represented.
- [x] **Remote rural** — Durness (0@750m, 2@1km). Genuinely sparse — needs 1500m expansion.
- [x] **US coverage** — all 10 locations pass. OSM allowlist approach works internationally.

### Open Questions

1. **Garden noise** — `leisure=garden` returns thousands of residential plots (875 unnamed in Manchester alone). Recommend excluding `garden` unless it has a wikipedia/wikidata tag or quality score >= 3.
2. **Place of worship weighting** — 13–37 churches in dense areas. Consider capping at 5–8 per wave to ensure category diversity.
3. **Supplementary sources** — only needed for genuinely remote areas (population < 500). Wikidata SPARQL or national heritage APIs could fill gaps.
4. **Business layer timeline** — when businesses are added back (as curated/monetised), what data source? Google Places API has cost + ToS constraints.

---

## Implementation Scope

### App Changes

1. **`map_screen.dart`** — replace hardcoded `500.0` radius with adaptive radius from `MysteryPoiService`.
2. **`mystery_poi_service.dart`** — implement adaptive radius: query at 750m, if named POI count < 15 expand to 1000m, if still < 10 expand to 1500m.
3. **`overpass_client.dart`** — extend query to include `way` and `relation` with `out center`. Convert centre coordinates to `LatLng` for area features.
4. **`rarity_classifier.dart`** — add allowlist filter. Reject categories not in the allowlist before scoring.
5. **`poi_curator.dart`** — tighten garden filtering (require name + minimum quality score). Consider category caps for place_of_worship.
6. **`discovery.dart`** — add `osmType` field (`node`, `way`, `relation`) for provenance tracking.

### Script/Tooling Changes

1. **`scripts/poi_audit.py`** — batch mode for running multiple locations from a CSV (done)
2. **Density report** — summary across all test locations showing pass/fail per area type (done)
3. **US test locations** — `scripts/poi_audit_locations_us.csv` (done)

### Not In Scope

- Google Places cross-reference (future)
- User-reported corrections (future)
- Business layer / monetisation (future)
- Backend/API — app remains fully client-side for POI fetching

---

## Audit Script Reference

```bash
# Default location (Ogilvie Terrace, Edinburgh)
python3 scripts/poi_audit.py --allowlist-only

# Custom location
python3 scripts/poi_audit.py --lat 55.9533 --lng -3.1883 --radius 1000 \
    --name "Edinburgh Old Town" --allowlist-only

# Export for analysis
python3 scripts/poi_audit.py --allowlist-only --export results.json
```
