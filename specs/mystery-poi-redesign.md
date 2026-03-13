# SPEC: Mystery POI redesign — surprise discoveries, compass charges, trophy pins

## Goal
- Transform mystery POIs from visible waypoints into hidden surprises that reward exploration, with a compass charge mechanic to optionally reveal one, and category-coloured trophy pins that build a personal collection map.

## Non-goals
- Monetisation / paywall for compass charges (future consideration, not this iteration)
- Social features (sharing trophy map, leaderboards)
- Custom POI categories beyond the existing seven + default
- Server-side POI persistence (stays local via Hive)

## Users / scenario
- A walker exploring their neighbourhood. They don't see POIs on the map — they just walk. When they wander within 50m of a hidden POI, it bursts into view as a coloured category pin with an animation. Over time their map fills with trophies.
- Optionally, the walker spends a compass charge to reveal the nearest hidden POI as a `?` marker, giving them a destination when they want one.

## Requirements (must)
- [ ] MysteryPoi supports three states: `unrevealed` (invisible), `hinted` (shows `?`), `revealed` (shows category pin)
- [ ] Unrevealed POIs are never rendered on the map
- [ ] Hinted POIs show as amber `?` markers (existing style)
- [ ] Revealed POIs show as category-coloured pins with distinct icons per category
- [ ] CategoryPinConfig maps category string → (IconData, Color) for all 7 categories + default
- [ ] CompassCharges model: earn 1 charge per 500m walked, max 3 stored, persisted via Hive
- [ ] CompassButton widget on map screen: shows charge count, disabled at 0, taps to hint nearest POI
- [ ] Discovery animation on reveal: pin scales up with elastic bounce (300ms) + particle burst (6-8 particles in category colour)
- [ ] MapScreen wires compass charges into walk distance tracking and POI hint flow

## Nice-to-haves
- [ ] Fog-burst radial wipe animation at POI location on reveal
- [ ] Haptic feedback on discovery (HeavyImpact) and compass use (MediumImpact)
- [ ] Sound effect hook (no audio implementation, just a callback for future use)

## Acceptance criteria (definition of done)
- [ ] Walking past a hidden POI triggers reveal animation + category pin drop — no prior indication on map
- [ ] Compass button shows current charge count; tapping reveals nearest unrevealed POI as `?`
- [ ] Walking 500m during a walk session awards 1 compass charge (up to max 3)
- [ ] Revealed POIs persist across app restarts as coloured category pins
- [ ] All 7 categories render with distinct icon and colour
- [ ] All new code has 80%+ test coverage
- [ ] Full test suite passes (1300+ tests)

## Risks / constraints
- MysteryPoi model change (adding `state` enum) requires migration of existing serialized data — `fromJson` must handle legacy format where `name != null` → revealed, `name == null` → unrevealed (no `state` field)
- CompassCharges persistence adds a new Hive box — register in service locator
- Discovery animation must not block map interaction — use overlay, auto-dismiss

## Issue breakdown (to create in GitHub)

- **Issue A: MysteryPoi state machine**
  - Add `PoiState` enum (unrevealed, hinted, revealed) to MysteryPoi model
  - Update `isRevealed` getter, add `isHinted` getter, add `hint()` method
  - Backward-compatible `fromJson` / `toJson`
  - Tests: state transitions, serialization roundtrip, legacy format parsing

- **Issue B: CategoryPinConfig**
  - New file `lib/core/theme/category_pin_config.dart`
  - Maps 7 categories + default → (IconData, Color)
  - Tests: every category returns correct icon/colour, unknown category returns default

- **Issue C: MysteryPoiMarkerLayer redesign**
  - Unrevealed POIs: not rendered
  - Hinted POIs: amber `?` marker (existing _UnrevealedMarker style)
  - Revealed POIs: category pin via CategoryPinConfig
  - Tests: empty list, unrevealed-only (nothing renders), hinted shows `?`, revealed shows category icon, mixed states

- **Issue D: CompassCharges model + repository**
  - Immutable model: currentCharges, maxCharges (3), metersPerCharge (500)
  - `earnFromDistance(double meters)` → new CompassCharges with charges added
  - `spend()` → new CompassCharges with charges - 1
  - HiveCompassChargesRepository for persistence
  - Tests: earn logic, spend logic, max cap, serialization, zero-charge spend throws

- **Issue E: CompassButton widget**
  - Floating button on map screen showing compass icon + charge count badge
  - Disabled (greyed) when charges == 0
  - On tap: finds nearest unrevealed POI from notifier, calls `hint()`, updates notifier
  - Tests: renders count, disabled at 0, tap calls callback

- **Issue F: Discovery burst animation**
  - DiscoveryBurstOverlay widget: takes screen position + category
  - Pin scales 0→1 with Curves.elasticOut over 300ms
  - 6-8 particles burst outward in category colour (reuse confetti pattern)
  - Auto-removes after animation completes
  - Tests: renders without error, auto-dismisses

- **Issue G: MapScreen wiring**
  - Add CompassCharges notifier, compass button, charge earning on walk distance
  - Wire discovery burst animation on POI reveal
  - Hide unrevealed POIs (already handled by Issue C marker layer change)
  - Tests: compass button present, charges update on distance

## PR discipline
- Branch → PR only
- PR body includes: `Closes #…`
- Commands to run:
  - `flutter analyze`
  - `dart format --set-exit-if-changed .`
  - `flutter test`
