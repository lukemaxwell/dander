# SPEC: Dander — Fog-of-War Neighbourhood Explorer (MVP)

## Goal
- Provide a gamified walking app that turns your neighbourhood into a game world — a fog-of-war map that clears as you walk, revealing hidden discoveries (cafes, parks, street art, historical spots) that you collect, with exploration progress tracking and shareable coverage maps.

## Non-goals
- Not a fitness tracker — does not track pace, calories, heart rate, or workout metrics
- Not a route planner in MVP — AI-generated routes come in v1.5 ("Surprise Me" button)
- Not a social network — friend features, leaderboards, and challenges come in v2
- Not a tourism/travel app — focused on your everyday neighbourhood, not holiday destinations
- No AR/camera features in MVP
- No local business partnerships or sponsored content in MVP

## Users / scenario
- **Daily walker** opens Dander, sees their neighbourhood mostly covered in fog with "You've explored 23% — 31 discoveries waiting." Goes for their usual walk but takes a different turn to clear more fog. Finds a Rare discovery (hidden garden) they never knew existed. Screenshots their coverage map and shares it.
- **New resident** just moved to a neighbourhood and uses Dander to systematically explore their area, treating it like a game. Motivated by the discovery collection and exploration percentage.
- **Friends competing** — two people in the same area compare exploration percentages. "I've explored 67% of E8, you've only done 34%." Drives both to walk more.
- **Content creator** films a TikTok following a Dander-suggested route, reacting to discoveries found along the way.

## Requirements (must)

### Core Map Experience
- [ ] Fog-of-war map covers the user's neighbourhood on first open, with only their immediate location revealed
- [ ] Fog clears in real-time as the user walks, with a radius of ~50m around their position
- [ ] Map uses OpenStreetMap tiles as the base layer beneath the fog
- [ ] Fog state persists between sessions — previously explored areas remain revealed
- [ ] Smooth, performant fog rendering at 60fps on mid-range devices (2022+ phones)

### Discovery System
- [ ] Points of interest auto-populated from OpenStreetMap Overpass API (cafes, parks, monuments, street art, viewpoints, historical markers, etc.)
- [ ] Discoveries are hidden until the user walks within 30m of them for the first time
- [ ] Each discovery has a rarity tier: Common (bronze), Uncommon (silver), Rare (gold)
- [ ] Discovery Card generated on first visit — shows name, category, rarity, location, and discovery date
- [ ] Discovery collection screen showing all found discoveries, filterable by rarity and category
- [ ] Discovery count and breakdown visible on user profile

### Progress & Gamification
- [ ] Neighbourhood exploration percentage calculated and displayed prominently (primary metric)
- [ ] Weekly walking streak tracked (walk at least once per week to maintain streak)
- [ ] Walk history — list of past walks with date, duration, distance, fog cleared %, and discoveries found
- [ ] Walk summary card shown at end of each walk — fog cleared, discoveries found, new streets walked
- [ ] Basic badges: "First Dander" (first walk), "Explorer" (10% explored), "Pathfinder" (25%), "Local Legend" (50%), "Cartographer" (75%), "Omniscient" (100%)

### Sharing
- [ ] Shareable coverage map — bird's-eye screenshot of fog map with exploration %, exportable as image
- [ ] Shareable Discovery Cards — individual discovery as image for social media
- [ ] Share walk summary card after completing a walk

### Technical
- [ ] Flutter cross-platform app (iOS + Android)
- [ ] Background location tracking (battery-efficient, significant-change mode when app backgrounded)
- [ ] Local-first data storage — fog state, discoveries, walk history stored on device
- [ ] Offline support — fog clears and discoveries trigger even without internet (syncs when online)
- [ ] Minimal backend — user account (optional), fog state backup, discovery database sync
- [ ] App size under 50MB

## Nice-to-haves
- [ ] "Surprise Me" button — generates a 15/30/45 min walk through unexplored areas (v1.5)
- [ ] Legendary (diamond) tier discoveries — community-nominated spots with 50+ votes
- [ ] Notification: "3 undiscovered spots within 10 minutes of you"
- [ ] Dark mode / light mode toggle
- [ ] Wander Score — persistent exploration reputation number
- [ ] Daily missions: "Find a Rare discovery today"
- [ ] Friend leaderboards by neighbourhood
- [ ] Neighbourhood challenges — community-wide exploration goals
- [ ] Seasonal events: "Spring Bloom: find every park by April 30"
- [ ] Sound effect + animation on discovery (especially Rare tier)
- [ ] Weekly recap card — km walked, fog cleared, discoveries, new cafes visited

## Acceptance criteria (definition of done)
- [ ] First open shows neighbourhood covered in fog with only current location circle revealed
- [ ] Walking for 5 minutes clears fog along the path taken, persisted on app restart
- [ ] Walking past a POI from OpenStreetMap for the first time triggers a Discovery Card popup with correct name, category, and rarity
- [ ] Exploration percentage updates in real-time during a walk
- [ ] Discovery collection screen shows all found discoveries with correct rarity tiers
- [ ] Walk summary card at end of walk shows accurate stats (fog %, discoveries, distance)
- [ ] Shareable coverage map generates a visually appealing image with fog/revealed areas and exploration %
- [ ] App works offline — fog clears and discoveries trigger without network
- [ ] Background location tracking works with acceptable battery impact (<5% per hour of walking)
- [ ] Fog rendering maintains 60fps on Pixel 7 / iPhone 13 equivalent
- [ ] All P0 features have unit tests and widget tests with 80%+ coverage

## Risks / constraints
- **Battery drain** — continuous GPS tracking kills batteries. Must use significant-change / activity-based tracking when backgrounded, fine GPS only when app is foregrounded and walk is active.
- **Fog rendering performance** — custom canvas rendering of thousands of revealed circles could be expensive. May need tile-based fog (divide map into grid cells, mark cells as explored) rather than pixel-perfect circle punching.
- **OpenStreetMap POI quality** — OSM coverage varies by area. Dense cities have rich POI data; suburbs/rural areas may have sparse discoveries. Need graceful handling of low-POI areas.
- **Rarity assignment** — no universal "rarity" field in OSM. Must define rules (e.g., `tourism=viewpoint` → Rare, `amenity=cafe` → Common, `historic=*` → Rare). Rules need tuning per geography.
- **Location permissions** — iOS and Android increasingly restrict background location. Must justify to app reviewers and users why background access is needed.
- **Offline fog state storage** — storing per-tile fog state efficiently. A simple grid (e.g., 10m x 10m cells) as a bitfield should be manageable but needs design.
- **Map tile costs** — OSM tiles are free but self-hosting tile servers at scale costs money. Can use free tile providers (e.g., Stadia Maps free tier) for MVP.

## Issue breakdown (to create in GitHub)

- **Issue 1: Project scaffolding — Flutter app, CI, base architecture**
  - Description: Initialize Flutter project with folder structure (features/, core/, shared/), add CI (GitHub Actions for lint + test), configure linting rules, add .gitignore, README stub. Set up dependency injection pattern and base navigation (GoRouter). Add flutter_map and geolocator packages.
  - Acceptance: `flutter build apk` and `flutter build ios` succeed; `flutter test` passes; CI runs on push; app launches showing a basic map centred on user location
  - Test plan: `flutter analyze` clean; `flutter test` passes; CI green; manual test on Android emulator and iOS simulator

- **Issue 2: Fog-of-war rendering engine**
  - Description: Implement the fog overlay on top of the map. The fog is an opaque layer covering the entire visible map area. As the user's location updates, circles of ~50m radius are "punched" through the fog. Use a tile-based grid system (e.g., 10m x 10m cells) where each cell is marked explored/unexplored. Render fog efficiently using CustomPainter with tile-based approach. Fog state persists to local storage (Hive or SQLite).
  - Acceptance: Map shows with fog overlay; moving the user position (simulated) clears fog in a circle; fog state survives app restart; rendering stays above 60fps with 10,000+ cleared cells
  - Test plan: Unit tests for fog grid data structure (mark cell, query cell, serialisation); widget tests for fog painter rendering; performance benchmark with large grids

- **Issue 3: Location tracking service**
  - Description: Implement location tracking using geolocator package. Two modes: (1) Active walk mode — high-accuracy GPS updates every 5 seconds when walk is in progress; (2) Background mode — significant-change updates only. Track walk start/stop, distance, duration. Handle location permission requests gracefully with clear rationale. Store walk data (polyline of coordinates, timestamps) locally.
  - Acceptance: Starting a walk tracks GPS coordinates at regular intervals; walk distance and duration are calculated accurately; location updates continue when app is backgrounded during active walk; battery usage is acceptable
  - Test plan: Unit tests for distance calculation, duration tracking, coordinate processing; integration test for location permission flow; manual test of background tracking on physical device

- **Issue 4: Discovery system — POI loading, proximity detection, rarity assignment**
  - Description: Load points of interest from OpenStreetMap Overpass API for the user's area (bounding box query). Cache POI data locally. Implement proximity detection — when user location comes within 30m of an undiscovered POI, trigger a "discovery" event. Assign rarity tiers based on OSM tags (define rules: historic/viewpoint → Rare, independent cafes/street art → Uncommon, chain shops/basic amenities → Common). Store discovered/undiscovered state locally.
  - Acceptance: POIs load for current area; walking near a POI triggers discovery; rarity tiers are assigned correctly; discovered state persists; works offline with cached data
  - Test plan: Unit tests for Overpass query building, proximity detection algorithm, rarity assignment rules; integration tests with mock POI data; manual test walking past real POIs

- **Issue 5: Discovery Card UI and collection screen**
  - Description: When a discovery is triggered, show a beautiful popup card with: POI name, category icon, rarity tier (colour-coded bronze/silver/gold), location, and discovery date. Add a collection screen (grid/list view) showing all found discoveries, filterable by rarity and category. Show discovery count and rarity breakdown on profile. Design the card to be visually appealing and screenshot-worthy.
  - Acceptance: Discovery popup appears on proximity trigger with correct data; collection screen shows all discoveries with filters; rarity colours match spec (bronze/silver/gold); cards look good on both iOS and Android
  - Test plan: Widget tests for Discovery Card rendering with different rarity tiers; widget tests for collection screen filtering; golden file tests for card appearance

- **Issue 6: Walk tracking UI — start/stop, live stats, summary**
  - Description: Implement walk session UI. Bottom sheet or floating button to start/stop a walk. During walk: show live stats (duration, distance, fog cleared %, discoveries found this walk). On walk end: show summary card with total stats. Store walk history locally. Walk history screen shows past walks with date, stats, and mini-map of route taken.
  - Acceptance: User can start and stop a walk; live stats update during walk; summary card shows accurate stats at end; walk history screen lists past walks; mini-map shows the route polyline
  - Test plan: Widget tests for walk session UI states; unit tests for stat calculations; integration test for full walk flow (start → location updates → stop → summary)

- **Issue 7: Exploration progress — percentage calculation, streaks, badges**
  - Description: Calculate neighbourhood exploration percentage. Define "neighbourhood" as a bounding box around the user's home location (configurable radius, default 2km). Percentage = explored grid cells / total grid cells in bounding box. Implement weekly streak tracking (walk at least once per week). Implement badge system with 6 badges based on exploration milestones. Show progress on profile/home screen.
  - Acceptance: Exploration percentage is accurate and updates after each walk; streak counter increments correctly; badges unlock at correct thresholds; all displayed on profile
  - Test plan: Unit tests for percentage calculation with various grid states; unit tests for streak logic (including edge cases: missed week, timezone changes); unit tests for badge unlock conditions

- **Issue 8: Sharing — coverage map export, discovery card export, walk summary export**
  - Description: Generate shareable images for three items: (1) Coverage map — bird's-eye view of fog map with exploration %, Dander branding, and user's neighbourhood name; (2) Discovery Card — individual card as PNG; (3) Walk summary — post-walk stats card. Use Flutter's RepaintBoundary + toImage for capture. Integrate with share_plus for native share sheet.
  - Acceptance: All three share types generate visually appealing PNG images; share sheet opens with image attached; images include Dander branding; works on both iOS and Android
  - Test plan: Widget tests for share image rendering; manual test of share flow to Instagram Stories, WhatsApp, iMessage; verify image quality and branding

- **Issue 9: Offline support and local data persistence**
  - Description: Ensure the app works fully offline. Fog state, discovery state, walk history, and cached POI data all stored locally (Hive or drift/SQLite). Map tiles cached for offline use (flutter_map tile caching). POI data syncs when network is available. Design data schema for fog grid, discoveries, walks, and user profile. Handle first-launch gracefully — preload POI data for current area on first network connection.
  - Acceptance: App works without network after initial POI load; fog clears offline; discoveries trigger offline; data survives app restart and phone restart; cached map tiles display offline
  - Test plan: Unit tests for data layer (CRUD operations, serialisation); integration test simulating offline scenario; manual test: enable airplane mode, go for walk, verify fog and discoveries work

## PR discipline
- Branch → PR only
- PR body includes: `Closes #…` / `Fixes #…`
- Commands to run (paste output in PR):
  - `flutter analyze`
  - `dart format --set-exit-if-changed .`
  - `flutter test --coverage`
