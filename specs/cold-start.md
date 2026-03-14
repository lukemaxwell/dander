# SPEC: Cold Start Fix — "Your World in 60 Seconds"

## Goal
- Eliminate first-launch churn by delivering value within 60 seconds of opening the app, before the user goes for their first walk.

## Non-goals
- Full onboarding tutorial or multi-screen walkthrough (we want implicit, not didactic)
- Paywall or upgrade prompts during first session
- Social features or account creation
- Changing the core fog-of-war or zone mechanics for returning users

## Users / scenario
- **Who:** A person who just installed Dander and has never used it before.
- **When:** First app launch, likely at home or at work — NOT already on a walk.
- **Why:** They saw a share card or App Store listing and want to see what the app does. They have about 30 seconds of patience before they decide to keep or delete.

## Requirements (must)

### Phase 1: Instant Micro-Reveal
- [ ] On first launch, after GPS is acquired, auto-clear a 100m radius around the user's current position (up from the current 50m default)
- [ ] Display a small overlay chip: "You've explored X% of your neighbourhood" where X is the tiny percentage (e.g. 0.2%)
- [ ] The fog-clear should animate (radial wipe outward, ~800ms) rather than appearing instantly
- [ ] First-launch flag (`isFirstLaunch`) gates this behaviour — returning users see nothing different

### Phase 2: Animated Preview
- [ ] After the micro-reveal settles, play a 5-second "preview" animation showing a simulated walk path extending from the user's position
- [ ] The simulated path should show fog dissolving along a curved route, a POI marker appearing with a discovery burst, and floating XP text
- [ ] The animation is non-interactive — the user watches, then it fades out
- [ ] A brief text overlay appears: "Every walk reveals more of your world"
- [ ] Reduced motion: skip the preview animation entirely, show a static info card instead

### Phase 3: First Walk Contract
- [ ] After the preview (or immediately for reduced motion), show an overlay prompt: "Walk 200m to discover your first zone"
- [ ] The prompt includes a real-time distance counter that updates as the user moves (GPS-driven)
- [ ] At 200m cumulative distance, auto-create the user's first zone (use current position as centre, prompt for name)
- [ ] Fire the standard zone creation celebration + level-up overlay
- [ ] The 200m prompt dismisses itself once triggered, and does not reappear on subsequent launches
- [ ] If the user dismisses the prompt manually, it reappears next launch until they've walked 200m

### Phase 4: Post-First-Walk Zoom-Out
- [ ] When the user stops their first walk (via WalkControl "End Walk"), trigger a camera zoom-out animation
- [ ] Camera pulls from current zoom level to ~14 zoom (neighbourhood scale) over 2 seconds, easing out
- [ ] The cleared fog path is visible as a glowing trail against the dark fog — the "wow moment"
- [ ] After the zoom-out settles (500ms pause), show a share prompt: "Share your first exploration" with a rendered FirstWalkShareCard
- [ ] The share card shows: exploration silhouette (fog shape, no street names), distance walked, POIs discovered, "dander.app" watermark
- [ ] User can dismiss the share prompt without sharing
- [ ] Zoom-out only fires once (first walk completion). Subsequent walks use normal end-walk flow

## Nice-to-haves
- [ ] Haptic feedback on micro-reveal completion (medium impact)
- [ ] Sound effect on POI discovery during preview animation
- [ ] "Tap anywhere to skip" on the preview animation
- [ ] Pre-seed a guaranteed "starter POI" within 300m if no OSM POIs exist nearby (edge case for rural users)

## Acceptance criteria (definition of done)
- [ ] First-time user sees fog cleared in 100m radius immediately after GPS fix
- [ ] Animated preview plays once and does not replay on subsequent launches
- [ ] "Walk 200m" prompt appears with live distance counter
- [ ] At 200m, first zone auto-creates with celebration animation
- [ ] Camera zooms out after first walk ends, showing cleared path
- [ ] Share prompt appears after zoom-out with rendered card (no location data in card)
- [ ] Returning users skip all onboarding — no regressions to existing flow
- [ ] All animations respect `DanderMotion.isReduced(context)`
- [ ] All tests pass (existing 1684 + new tests for each phase)

## Risks / constraints
- GPS may not be available immediately on first launch (user indoors, permission not yet granted). The micro-reveal must wait for a valid fix — show a "Locating you..." state with a subtle pulsing animation.
- The 100m micro-reveal radius at home may reveal very little interesting map content. The preview animation compensates by showing what a REAL walk looks like.
- Rural users may have no POIs within walking distance. The preview animation should use simulated POIs. The 200m contract works regardless of POI density.
- The animated preview must NOT interfere with map interactivity — it plays on an overlay layer above the map.
- The FirstWalkShareCard must not contain GPS coordinates, street names, or any location-identifying information. Only the silhouette shape and stats.

## Issue breakdown (to create in GitHub)

### Issue 1: First-launch micro-reveal (100m animated fog clear)
- Description: When `isFirstLaunch` is true and GPS fix is acquired, animate a 100m radius fog clear around the user's position (expanding the current 50m instant clear). Show an exploration percentage chip overlay. Gate behind first-launch flag so returning users are unaffected.
- Acceptance:
  - [ ] First launch clears 100m radius with radial wipe animation (~800ms)
  - [ ] Exploration percentage chip displays after reveal
  - [ ] Returning users see standard 50m instant reveal (no regression)
  - [ ] Reduced motion: instant reveal (no animation), chip still shows
- Test plan:
  - [ ] Unit test: `FogGrid.markExplored` with 100m radius produces correct cell count
  - [ ] Widget test: first-launch overlay shows percentage chip
  - [ ] Widget test: non-first-launch skips overlay

### Issue 2: Animated walk preview (5s simulated exploration)
- Description: After micro-reveal, play a 5-second overlay animation simulating a walk: a curved path extends from user position, fog dissolves along it, a POI marker pings with discovery burst, floating XP appears. Non-interactive. Fades to "Every walk reveals more of your world" text, then auto-dismisses. Fires only on first launch.
- Acceptance:
  - [ ] Preview animation plays after micro-reveal on first launch only
  - [ ] Animation shows simulated fog clearing, POI discovery, XP text
  - [ ] Overlay text displays and fades
  - [ ] Does not replay on subsequent app opens
  - [ ] Reduced motion: shows static info card instead of animation
- Test plan:
  - [ ] Widget test: preview overlay renders on first launch
  - [ ] Widget test: preview overlay does not render on returning launch
  - [ ] Widget test: reduced motion shows static fallback

### Issue 3: First walk contract (200m prompt with live counter)
- Description: After preview dismisses, show a persistent overlay prompt: "Walk 200m to discover your first zone" with a real-time GPS-driven distance counter. At 200m cumulative, auto-create the first zone (prompt for name), fire celebration. Dismiss prompt permanently after zone creation. If manually dismissed, re-show next launch until 200m is reached.
- Acceptance:
  - [ ] "Walk 200m" prompt appears after preview on first launch
  - [ ] Distance counter updates in real-time from GPS stream
  - [ ] At 200m, zone creation dialog fires automatically
  - [ ] Standard level-up celebration plays after zone creation
  - [ ] Prompt does not reappear once zone is created
  - [ ] Manual dismiss → prompt returns next launch
- Test plan:
  - [ ] Unit test: distance accumulation logic (haversine, 200m threshold)
  - [ ] Widget test: prompt renders when no zones exist
  - [ ] Widget test: prompt hidden when zone already exists
  - [ ] Integration test: distance counter updates from mock GPS stream

### Issue 4: Post-first-walk zoom-out + share card
- Description: When the user ends their first-ever walk (via WalkControl), animate the map camera from current zoom to ~14 (neighbourhood scale) over 2 seconds. After 500ms pause, show a share prompt with a rendered FirstWalkShareCard (exploration silhouette, distance, POIs discovered, no location data). Share prompt is dismissable. Zoom-out fires only on first walk completion.
- Acceptance:
  - [ ] Camera zooms out smoothly after first walk ends (2s, ease-out)
  - [ ] Share prompt appears 500ms after zoom-out settles
  - [ ] FirstWalkShareCard renders with silhouette, stats, branding
  - [ ] Share card contains NO GPS coordinates or street names
  - [ ] Share prompt is dismissable without sharing
  - [ ] Zoom-out does not fire on subsequent walk completions
- Test plan:
  - [ ] Widget test: zoom-out triggers on first walk end
  - [ ] Widget test: zoom-out does NOT trigger on second walk end
  - [ ] Widget test: share card renders without location data
  - [ ] Widget test: share prompt dismissal works

## PR discipline
- Branch → PR only
- PR body includes: `Spec: specs/cold-start.md` and `Closes #…`
- Commands to run (paste output in PR):
  - `flutter analyze`
  - `flutter test`
