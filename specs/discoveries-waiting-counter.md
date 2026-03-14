# SPEC: Discoveries waiting counter — show total discoverable POIs in area

## Goal
- Surface the total number of undiscovered POIs in the current area as a "X discoveries waiting" counter on the map screen, giving users a sense of how much there is to find and motivating continued exploration.

## Non-goals
- Leaderboard or social comparison of discovery counts
- Persisting total counts across sessions (recalculated on each zone entry)
- Showing individual POI locations — the counter is aggregate only

## Users / scenario
- A walker opens the map and sees `[████░░░░░░] 2% explored` with `43 discoveries waiting` beneath it. As they walk and reveal POIs, the waiting count ticks down, reinforcing progress and creating a "gotta find 'em all" pull.

## Requirements (must)
- [ ] `MysteryPoiService.generatePois()` returns both active POIs and the total discoverable count from Overpass
- [ ] `GenerateResult` model holds `activePois: List<MysteryPoi>` + `totalCount: int`
- [ ] `ExplorationBadge` accepts optional `discoveriesWaiting` param and renders it as a second line beneath the progress bar
- [ ] MapScreen wires total count from generate result into ExplorationBadge
- [ ] Counter updates (decrements) when a POI is revealed
- [ ] When `discoveriesWaiting` is null or 0, the second line is hidden (badge stays compact)

## Nice-to-haves
- [ ] Animate the counter decrement (brief scale pulse)
- [ ] Show "All discovered!" message when count reaches 0

## Acceptance criteria (definition of done)
- [ ] ExplorationBadge shows "X discoveries waiting" beneath progress bar when count > 0
- [ ] Counter hides when count is 0 or null
- [ ] generatePois returns total count alongside active POIs
- [ ] Revealing a POI decrements the displayed counter
- [ ] All new code has 80%+ test coverage
- [ ] Full test suite passes

## Risks / constraints
- `generatePois()` return type changes from `List<MysteryPoi>` to `GenerateResult` — all callers must be updated
- Overpass API already returns the full list; we just need to stop discarding its length

## Issue breakdown (to create in GitHub)

- **Issue A: GenerateResult model + service update**
  - Add `GenerateResult` class with `activePois` and `totalCount`
  - Update `MysteryPoiService.generatePois()` to return `GenerateResult` instead of `List<MysteryPoi>`
  - Update all callers
  - Tests: generatePois returns correct totalCount, activePois capped at 3

- **Issue B: ExplorationBadge discoveries waiting display**
  - Add optional `discoveriesWaiting` param to ExplorationBadge
  - Render "X discoveries waiting" as a second line beneath the progress bar row when > 0
  - Hide when null or 0
  - Tests: renders with count, hides when 0, hides when null

- **Issue C: MapScreen wiring — discoveries waiting counter**
  - Store total count from generatePois result
  - Decrement on POI reveal
  - Pass count to ExplorationBadge
  - Tests: counter present, decrements on reveal

## PR discipline
- Branch → PR only
- PR body includes: `Closes #…`
- Commands to run:
  - `flutter analyze`
  - `dart format --set-exit-if-changed .`
  - `flutter test`
