# Zone Progression System

**Status:** Draft
**Date:** 2026-03-13

---

## Goal

Replace the single-area fog map with a multi-zone, level-based progression system that works anywhere in the world and drives long-term retention through XP, POI discovery, and a shareable turf card.

---

## Non-goals

- Real-time cloud sync / backend infrastructure (MVP: iCloud backup of local storage)
- Social/rival features that share user location with others (privacy/safety)
- Fog creep mechanic (deferred — see specs note)
- Android support for iCloud backup path

---

## Users / Scenario

A user walks their home neighbourhood daily, earning XP and unlocking a wider explorable radius. They travel to Barcelona for a weekend — the app detects a new location, creates a Barcelona zone, and they start fresh there. When they return home, their home zone is exactly as they left it. Over time they accumulate zones like trophy regions.

---

## Requirements (must)

### Zones
- [ ] A zone is created automatically when the user is detected >50 km from any existing zone centre
- [ ] Zone detection runs when the app is foregrounded (not background — battery/privacy)
- [ ] On new zone detection, show prompt: *"You're somewhere new! Start exploring [Name]?"* with name pre-filled from reverse geocoding (editable)
- [ ] User can dismiss the prompt (no zone created until they accept)
- [ ] Each zone stores independently: fog state, XP, level, quiz history, discovered POIs, badges
- [ ] Zones are listed in a Zones screen, each showing name, level, and % streets explored
- [ ] Active zone switches automatically based on current GPS position

### Levels & XP
- [ ] XP is earned per zone: walking a new street (+10 XP), correct quiz answer (+5 XP), quiz streak bonus (+2 XP per answer beyond 3 in a row), POI discovered (+50 XP)
- [ ] Level thresholds (XP): L1 0–99, L2 100–299, L3 300–699, L4 700–1499, L5 1500+
- [ ] Each level unlocks a wider explorable fog radius: L1 500m, L2 1.5km, L3 3km, L4 8km, L5 unlimited
- [ ] Streets, quiz questions, and POIs outside the current radius are hidden/locked
- [ ] Level-up triggers a celebration animation and shows what was unlocked

### POI System (Zelda-style)
- [ ] Up to 3 mystery POIs are active at any time within the current radius, shown as obscured `?` markers in the fog
- [ ] POIs are sourced from OpenStreetMap within the current zone radius
- [ ] Categories: pub, park, historic, street art, viewpoint, café, library (extensible)
- [ ] User can request a POI of a specific category (cooldown: 4 hours)
- [ ] On physical arrival (within 50m): POI is revealed with name, OSM description, and category icon
- [ ] Discovery awards +50 XP and a category badge (first discovery of each type)
- [ ] Some POIs are flagged as "required" — completing them contributes to level XP threshold
- [ ] POI markers persist on the map after discovery (trophy state)

### Data Persistence
- [ ] All zone data stored locally using Hive
- [ ] iOS iCloud backup covers Hive data automatically (no extra code required)
- [ ] Export/import zone data as JSON (future-proofing for cloud sync migration)

### Turf Share Card
- [ ] Accessible from each Zone detail screen: "Share your turf"
- [ ] Rendered as an off-screen widget then captured as PNG
- [ ] Design: dark parchment background, golden fog silhouette of explored territory, zone name in serif font, level badge (e.g. "Level 3 Explorer"), street count, Dander logo
- [ ] Shared via standard iOS share sheet (image only — no location metadata embedded)

### Global Meta-Progression
- [ ] Profile screen shows: total zones explored, total streets walked (all zones), total POIs discovered, total badges collected
- [ ] Badges are grouped by zone on the profile screen

---

## Nice-to-haves

- Animated XP bar fill on street walk / quiz answer
- Zone nicknames with emoji (e.g. "🏠 Home" auto-tagged for first zone)
- "Postcard" variant of share card per zone (more travel-themed)
- Push notification when a new mystery POI spawns nearby

---

## Acceptance Criteria

- [ ] User walks 500m from app install location → streets reveal, XP increments correctly
- [ ] User reaches 100 XP → level 2 unlocked, fog radius visibly expands to 1.5km
- [ ] User travels >50km → new zone prompt appears on next app foreground
- [ ] Two zones exist → switching location switches active zone with correct fog/XP state
- [ ] Mystery POI appears on map → user walks to it → revealed with name and +50 XP awarded
- [ ] Share card generates PNG with correct zone name, level, and fog silhouette
- [ ] App deleted and restored from iCloud backup → all zone data intact

---

## Risks / Constraints

- **OSM data quality**: POI density varies by location. Need fallback if <3 POIs exist in radius (lower cooldown, wider search radius)
- **GPS accuracy**: 50m arrival threshold may be too tight indoors — consider 80m
- **Fog silhouette rendering**: Capturing explored territory as a shareable image requires off-screen canvas render; test on older devices for performance
- **iCloud backup lag**: Not real-time — user should not expect instant cross-device sync (document this clearly in onboarding)
- **Reverse geocoding rate limits**: Apple's CLGeocoder has a rate limit; cache results per zone

---

## Issue Breakdown

| # | Title | Label |
|---|-------|-------|
| 1 | Data model: Zone entity with Hive persistence | feat |
| 2 | Zone auto-detection and new-zone prompt | feat |
| 3 | XP system: earning, storage, and level thresholds | feat |
| 4 | Level-up: fog radius expansion and celebration animation | feat |
| 5 | POI system: OSM fetch, mystery markers, arrival detection | feat |
| 6 | POI category filter with cooldown | feat |
| 7 | Zones list screen | feat |
| 8 | Global meta-progression profile screen | feat |
| 9 | Turf share card: render and export | feat |
| 10 | Migrate existing fog/quiz state into Zone model | refactor |

---

## PR Discipline

Branch naming: `feat/zone-progression-<issue-number>`
All PRs reference this spec: `Spec: specs/zone-progression.md`
