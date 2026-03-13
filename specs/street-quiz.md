# SPEC: Street Name Quiz — Neighbourhood Memory Game

## Goal
- Turn every street the user has walked into a flashcard, using spaced repetition to quiz them on street names until their neighbourhood is truly known — not just explored.

## Non-goals
- Not a navigation tool — does not give directions or routing
- No crowd-sourced street name corrections in MVP
- No cross-neighbourhood or global leaderboards in MVP
- No audio pronunciation of street names
- No POI quizzing in this feature (discoveries are separate)
- No AR/camera overlay of street names

## Users / scenario
- **The explorer who wants to truly know their neighbourhood** — has cleared 40% of the fog but realises they couldn't name half the streets they've walked. Opens the Quiz tab, sees 23 streets queued for review. Does a 5-minute session before coffee and nails 18/23.
- **The new resident** — moved in 2 weeks ago, uses the quiz daily to build mental map of their area. Streak motivates them to go for a short walk each day to unlock new streets to learn.
- **The competitive user** — wants 100% exploration AND 100% street mastery. The "Mastered" count on the Quiz tab is a second axis of achievement beyond fog coverage.

## Requirements (must)

### Street Collection
- [ ] Every street (OSM `highway=*` way with a `name` tag) that the user walks is added to their "Streets Learned" collection
- [ ] A street is considered "walked" when the user's GPS track intersects the street's geometry within 20m
- [ ] Streets are loaded from OpenStreetMap Overpass API (same bounding-box approach as POI discovery)
- [ ] Street data cached locally; syncs when network available
- [ ] Streets only appear in the quiz after being walked at least once — never quizzed before walked

### Spaced Repetition Engine
- [ ] Each street has a memory state: `new → learning → review → mastered`
- [ ] Scheduling based on SM-2 algorithm (simplified): correct answer increases interval, wrong answer resets to `learning`
- [ ] Intervals: new=same session, learning=1 day, review=3/7/14/30 days (doubling), mastered=30+ days
- [ ] Streets due for review today surface automatically on Quiz tab open
- [ ] Max 20 streets per quiz session to prevent fatigue

### Quiz Mechanic
- [ ] Each question shows: a map snippet centred on the street with the street highlighted in gold, surrounding streets greyed out, no labels visible
- [ ] Question format: "What is this street called?" with 4 multiple-choice answers
- [ ] Distractors (wrong answers) drawn from other walked streets in the same neighbourhood to make it non-trivial
- [ ] If fewer than 3 other walked streets exist, distractors drawn from unwalked nearby streets
- [ ] User selects answer → immediate feedback (green correct / red wrong) with the correct name revealed on map
- [ ] After feedback, user taps "Next" to proceed
- [ ] Session ends after 20 questions or when queue is empty; summary card shown

### Quiz Session Summary
- [ ] Shows: questions answered, correct %, streets mastered this session, current streak
- [ ] "Go explore" CTA if queue is empty (links back to map)

### Progress & Streaks
- [ ] "Streets mastered" count shown on Quiz tab and Profile
- [ ] Daily quiz streak — maintaining streak requires at least one quiz session per day
- [ ] Mastery percentage: mastered streets / total walked streets

### Quiz Tab
- [ ] Dedicated bottom nav tab (replace or add alongside existing tabs)
- [ ] Shows: due count ("5 streets due"), mastery %, walked streets count, mastered streets count
- [ ] "Start Review" button (disabled if nothing due)
- [ ] "Practice All" button — re-quiz all walked streets regardless of schedule
- [ ] Streets list: scrollable list of all walked streets with their mastery state badge

## Nice-to-haves
- [ ] Difficulty setting: show partial street name as hint (e.g. "_ _ _ _ e   S t r e e t")
- [ ] Map animation: street "lights up" on the full neighbourhood map when answered correctly
- [ ] Voice input mode: say the street name instead of tapping
- [ ] Neighbourhood quiz certificate: shareable card when 100% of walked streets are mastered
- [ ] Street history card: tap any street in the list to see when you first walked it, quiz history, fun OSM facts (length, year named, etc.)
- [ ] "Nearby unwalked" nudge: "Walk 3 more streets to unlock 8 new quiz cards"

## Acceptance criteria (definition of done)
- [ ] Walking a street (simulated GPS track) adds it to the walked streets collection within 1 location update
- [ ] The quiz presents a map snippet with the correct street highlighted and 4 answer options
- [ ] Correct answer advances the street's interval; wrong answer resets it to `learning`
- [ ] Streets not yet walked never appear as the quiz target (may appear as distractors)
- [ ] Quiz tab shows accurate due count, mastery %, and walked street count
- [ ] Session summary appears after completing 20 questions or exhausting the queue
- [ ] Spaced repetition schedule persists across app restarts
- [ ] Map snippet renders without street name labels (fog of labels)
- [ ] All P0 logic (SR engine, street detection, quiz flow) has unit tests with 80%+ coverage

## Risks / constraints
- **OSM street geometry** — streets are stored as ways (sequences of nodes), not simple lines. Intersection detection requires geometry math. For MVP, simplify to bounding-box proximity of the way's nodes rather than precise segment intersection.
- **Map snippet without labels** — flutter_map renders OSM tiles which include labels baked into raster tiles. To hide labels on the quiz snippet, use a label-free tile layer (e.g. Stadia Maps `stamen_toner_background` or OSM `{z}/{x}/{y}.png` with a custom style). Alternatively, render a vector map — more complex but cleaner.
- **Distractor quality** — wrong answers must be plausible (nearby streets) but not so similar as to be ambiguous. Requires geographic filtering of distractor candidates.
- **Street name uniqueness** — some areas have many streets with similar names (e.g. "High Street", "Church Road"). The quiz must avoid cases where multiple correct answers exist in the choice set.
- **SM-2 edge cases** — timezone changes, offline use, and app not opened for days must not corrupt the spaced repetition schedule.

## Issue breakdown (to create in GitHub)

- **Issue 10: Street data layer — OSM streets loading, geometry, local cache**
  - Description: Load named streets from OpenStreetMap Overpass API for the user's neighbourhood bounding box (`highway=* [name]`). Parse way geometries (node sequences). Cache locally in Hive. Implement `StreetRepository` with `saveStreets`, `getStreets(bounds)`, `markWalked(streetId, walkedAt)`, `getWalkedStreets`. Street model: `id`, `name`, `nodes: List<LatLng>`, `walkedAt: DateTime?`.
  - Acceptance: Streets load for a bounding box; walked state persists across restarts; cache used when offline
  - Test plan: Unit tests for Overpass query, street model serialisation, repository CRUD; mock HTTP for API tests

- **Issue 11: Street detection — GPS track intersection with walked streets**
  - Description: On each location update during an active walk, check whether the user has come within 20m of any unwalked street node. If yes, mark that street as walked. Use the existing `WalkService` location stream as input. Implement `StreetDetectionService` that subscribes to position updates and emits `Street` events when a new street is walked.
  - Acceptance: Simulated GPS track that passes a street triggers `walkedAt` being set; streets not on the track are not marked; detection works offline
  - Test plan: Unit tests for proximity detection (haversine to nearest node); unit tests for detection service with mock position stream; edge cases: street with single node, very long street

- **Issue 12: Spaced repetition engine — SM-2 scheduling**
  - Description: Implement a simplified SM-2 spaced repetition scheduler. `SpacedRepetitionEngine` takes a `StreetMemoryRecord` (streetId, state, interval, easeFactor, nextReviewDate, reviewHistory) and a `QuizResult` (correct/incorrect) and returns an updated record. States: `new → learning → review → mastered`. Intervals: wrong=reset to 1 day, correct multiplies interval by easeFactor (default 2.5, min 1.3). Mastered when interval ≥ 30 days. `QuizScheduler` returns streets due today, capped at 20.
  - Acceptance: Correct answers increase interval; wrong answers reset to learning; mastered threshold correct; due streets filtered by nextReviewDate ≤ today
  - Test plan: Unit tests for all state transitions, interval calculations, edge cases (first review, already mastered, timezone boundary)

- **Issue 13: Quiz map snippet widget**
  - Description: Build `QuizMapSnippet` widget — a non-interactive flutter_map showing a small area (zoom ~16) centred on the quiz street. The target street is rendered as a gold polyline overlay; surrounding streets are not highlighted. Crucially, **no street name labels** must be visible. Use a label-free tile layer URL (Stadia Maps `alidade_smooth_dark` without labels, or equivalent free option). The widget accepts a `Street` and renders its geometry.
  - Acceptance: Target street rendered in gold; map shows no text labels; widget is non-interactive; renders correctly at various street lengths (short alley vs long road)
  - Test plan: Widget test verifying the polyline layer is present; widget test verifying non-interactive (no GestureDetector); screenshot test for visual verification

- **Issue 14: Quiz screen — question flow, answer selection, feedback**
  - Description: Implement the full quiz question screen. Displays `QuizMapSnippet` in the top half, question text and 4 `ChoiceButton` widgets in the bottom half. On selection: disable all buttons, highlight correct (green) and selected-wrong (red), show correct street name on map. "Next" button appears after selection. Wire to `QuizSession` state object that tracks current question index, score, and session streets. On session complete (20 answered or queue empty), navigate to `QuizSummaryScreen`.
  - Acceptance: Quiz shows map snippet + 4 choices; tapping correct turns green; tapping wrong turns red + correct highlighted green; Next advances or ends session; no answer possible after selection
  - Test plan: Widget tests for all answer states (correct, wrong, not-yet-answered); widget test for Next button behaviour; unit tests for QuizSession state machine

- **Issue 15: Quiz tab — home screen, due count, streets list**
  - Description: Build the Quiz tab home screen. Shows mastery stats header (due count, mastery %, walked/mastered counts). "Start Review" button (active only when due > 0). "Practice All" button. Scrollable list of all walked streets with mastery state badge (new/learning/review/mastered). Wire to `QuizRepository` for persisted memory records and `StreetRepository` for walked streets. Add Quiz tab to bottom navigation bar.
  - Acceptance: Due count matches scheduler output; mastery % correct; Start Review disabled when due=0; streets list shows all walked streets; mastery badge correct for each street
  - Test plan: Widget tests for empty state, populated state, due/not-due button states; unit tests for mastery % calculation

- **Issue 16: Quiz summary screen and streak tracking**
  - Description: Build `QuizSummaryScreen` shown at end of each session. Shows: correct/total, accuracy %, streets moved to mastered, current daily streak. Implement daily quiz streak — a streak day requires ≥1 quiz session completed. `QuizStreakTracker` mirrors `StreakTracker` from the progress module. Persist streak in Hive. Show streak on Quiz tab home and Profile screen.
  - Acceptance: Summary shown after session ends with correct stats; streak increments on session completion; streak resets if no session for >1 calendar day; streak displayed on Profile
  - Test plan: Widget tests for summary card; unit tests for streak logic (increment, reset, edge cases)

## PR discipline
- Branch → PR only
- PR body includes: `Closes #…` / `Fixes #…`
- Commands to run (paste output in PR):
  - `flutter analyze`
  - `dart format --set-exit-if-changed .`
  - `flutter test --coverage`
