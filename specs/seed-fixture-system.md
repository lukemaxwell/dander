# SPEC: Unified Seed/Fixture System

## Goal
A single fixture infrastructure that seeds the app into deterministic states for marketing screenshots, developer testing, and E2E automation — injecting data at the repository layer so the real UI renders against pre-loaded state.

## Non-goals
- No fake features or UI redesign for marketing
- No brittle one-off screenshot hacks
- No production runtime cost — fixture code is debug-only
- No in-app debug menu in v1 (future nice-to-have)
- Not replacing real integration tests with fixture-only tests

## Users / scenario
- **Marketing**: launch simulator with `--dart-define=SEED_PROFILE=mid_progress`, capture screenshot-ready map with discoveries
- **Developer**: launch with `SEED_PROFILE=active_zone` to skip 20-min walk, debug zone/POI/fog behaviour instantly
- **E2E tests**: `SeedProfileLoader.load('onboarding_complete')` in test setUp for deterministic, repeatable scenarios

## Requirements (must)
- [ ] `SeedProfile` enum with named presets readable via `String.fromEnvironment('SEED_PROFILE')`
- [ ] `SeedFixture` abstract class defining the data each fixture provides (walks, discoveries, zones, fog, POIs, progress/XP, onboarding state)
- [ ] At least 5 concrete fixtures: `empty`, `onboarding_complete`, `active_zone`, `mid_progress`, `high_payoff`
- [ ] `SeedProfileLoader` that detects the profile at startup and populates repositories before the app renders
- [ ] Modified `setupLocator()` / `main()` flow to call `SeedProfileLoader` when a profile is set
- [ ] `FakeLocationService` implementing `LocationService` that emits a configurable static position and always returns `hasPermission = true`
- [ ] Permission suppression: skip location/notification permission flows when a seed profile is active
- [ ] Onboarding suppression: `AppStateRepository` reports `isFirstLaunch = false` when a seed profile is active (unless the fixture explicitly wants onboarding)
- [ ] Fixture location defaults to a real London neighbourhood with good POI density (e.g. Greenwich/Blackheath area)
- [ ] All fixture code excluded from release builds via `kDebugMode` guards or tree-shaking
- [ ] Documentation: run instructions for each preset

## Nice-to-haves
- [ ] `fresh` and `multi_zone` and `full_zone` presets
- [ ] Composable fixtures (e.g. `mid_progress` extends `onboarding_complete` + adds walks)
- [ ] In-app debug menu to switch fixtures without relaunch
- [ ] Configurable simulated position per fixture (not just one default)
- [ ] Fake compass heading stream for POI navigation testing

## Acceptance criteria (definition of done)
- [ ] `flutter run --dart-define=SEED_PROFILE=mid_progress` launches the app into a screenshot-ready map state with walked routes and at least one visible discovery
- [ ] `flutter run --dart-define=SEED_PROFILE=active_zone` shows a zone with mystery POIs (some revealed, some not)
- [ ] `flutter run --dart-define=SEED_PROFILE=empty` launches a clean-install state with no permission prompts
- [ ] E2E test can call `SeedProfileLoader.load('onboarding_complete')` and assert the app skips onboarding
- [ ] No fixture code is present in release builds (verified by searching release binary or inspecting tree-shaking)
- [ ] A second developer can reproduce the same state using only the documentation

## Risks / constraints
- **Hive box initialisation order**: fixtures must populate boxes after they're opened in `main()` but before widgets build. Need to ensure the seed loader runs at the right point in the startup sequence.
- **Fog grid binary format**: seeding fog state requires generating valid `FogGrid.toBytes()` data. May need a helper to create fog grids from walked coordinates.
- **Map tile rendering**: seeded state will look correct but the underlying map tiles still need network. Simulator must have connectivity for map backgrounds.
- **AppStateRepository created outside setupLocator**: currently instantiated in `main()` before DI. Fixture system needs to intercept this or replace it.
- **Release build safety**: `String.fromEnvironment` returns empty string in release, but fixture classes should also be behind `kDebugMode` to ensure tree-shaking eliminates them.

## Issue breakdown

### Issue 1: Seed profile detection and loader skeleton
- Description: Add `SeedProfile` enum, `SeedFixture` abstract class, `SeedProfileLoader`, and wire into `main()` / `setupLocator()`. No actual fixture data yet — just the infrastructure that reads `SEED_PROFILE` and calls the right fixture.
- Acceptance: `--dart-define=SEED_PROFILE=empty` is detected at startup, loader runs, no crash. Unknown profile names log a warning.
- Test plan: Unit test `SeedProfile.fromString()` parsing. Integration test that loader calls fixture methods.

### Issue 2: FakeLocationService and permission suppression
- Description: Implement `FakeLocationService` conforming to `LocationService` that emits a static configurable position, always grants permission. When seed profile is active, register `FakeLocationService` instead of `GeolocatorLocationService`. Suppress onboarding by setting `isFirstLaunch = false`.
- Acceptance: App launches with seed profile, no location permission prompt, no onboarding flow, map centres on fixture position.
- Test plan: Unit test `FakeLocationService` stream emission. Manual test on simulator confirms no permission dialog.

### Issue 3: Fog grid seeding helper
- Description: Create a helper that generates a valid `FogGrid` with specified tiles revealed, given a list of walked coordinates. This is the foundation for all fixtures that show walked routes.
- Acceptance: Helper produces a `FogGrid` where tiles along a given path are revealed. Round-trip through `toBytes()`/`fromBytes()` preserves state.
- Test plan: Unit test with known coordinates, verify expected tiles are revealed.

### Issue 4: `empty` and `onboarding_complete` fixtures
- Description: Implement the two simplest fixtures. `empty` = fresh install state, no data. `onboarding_complete` = past onboarding, no walks, map centred on fixture location.
- Acceptance: Both launch cleanly with correct state. `empty` shows clean-install state, `onboarding_complete` goes straight to map.
- Test plan: Manual launch with each profile on simulator. E2E test loads `onboarding_complete` and asserts map screen is visible.

### Issue 5: `active_zone` fixture
- Description: Seed a zone with mystery POIs at various states (some revealed, some unrevealed), a partial fog grid showing walked routes, and progress data. Uses real London coordinates.
- Acceptance: Launch shows a zone with walked area, mystery POI markers on map, and zone card on zones page.
- Test plan: Manual verification on simulator. Assert zone exists in zone repository, POIs exist in mystery POI repository.

### Issue 6: `mid_progress` and `high_payoff` marketing fixtures
- Description: Build the two primary marketing presets. `mid_progress` = one zone with a pleasing revealed route shape, 1-2 visible discoveries, active UI state. `high_payoff` = stronger revealed area, multiple discoveries, rich map. Both should produce screenshot-ready visuals.
- Acceptance: Screenshots from both presets are visually strong — good fog contrast, visible discoveries, centred composition.
- Test plan: Capture screenshots on iPhone 15 Pro simulator at both presets. Visual review confirms marketing-quality output.

### Issue 7: Documentation and runbook
- Description: Write run instructions for each preset, document how to add new fixtures, and provide example CLI commands for common workflows (screenshot capture, E2E test setup, dev debugging).
- Acceptance: A developer unfamiliar with the system can launch any preset using only the docs.
- Test plan: Hand docs to another team member and verify they can reproduce a seeded state.

## PR discipline
- Branch → PR only
- PR body includes: `Spec: specs/seed-fixture-system.md`
- Commands to run:
  - `flutter analyze`
  - `dart format --set-exit-if-changed .`
  - `flutter test`
