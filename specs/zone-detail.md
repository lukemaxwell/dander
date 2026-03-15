# SPEC: Zone Detail Screen — Your Neighbourhood Trophy Case

## Goal
Give users a dedicated, visually rewarding screen that celebrates their exploration of a zone — showing progression, discoveries, learning mastery, and activity in a way that makes them feel proud of what they've achieved and motivated to explore more.

## Non-goals
- Editing zone settings (rename/delete already handled from the card)
- Zone-scoped map view (separate future feature)
- Real-time walk tracking from this screen
- Multi-zone comparison view
- Changing zone data model or persistence

## Users / scenario
A user who has been walking and exploring in a zone taps a zone card on the Zones tab. The screen opens with a hero progression display and scrollable sections showing their exploration stats, discovery collection, and quiz mastery — each section revealing with a staggered entrance that builds anticipation. The user scrolls through their achievements feeling a sense of accomplishment and can clearly see what's left to unlock at the next level.

## Design direction

### Emotional goal
The zone detail screen should feel like opening your **personal exploration journal** — not a dry stats dashboard. Every number should feel earned. The design should answer: "Look how much of this neighbourhood you own."

### Visual structure (top → bottom)

1. **Hero zone header** — zone name (large), level badge with accent glow at higher levels, created date as a subtle timestamp. The zone's current fog radius visualised as a ring graphic (reuse `_RingPainter` pattern from ProfileScreen's `_ExplorationRing`). Centre shows exploration % for this zone.

2. **XP progress card** — current XP / next threshold with a 6pt progress bar (rounded caps). Below the bar: current radius on the left, next-level radius on the right, with an arrow between. At max level: celebratory "Max level reached" with accent glow.

3. **Exploration stats row** — three-column stat card (reuse `_WalkStatsCard` / `_StatColumn` pattern from ProfileScreen):
   - Streets walked (with `Icons.route` icon)
   - Discoveries found (with `Icons.explore` icon)
   - Distance walked (with `Icons.straighten` icon)
   Numbers should use `CountUpText` for animated reveal on first load.

4. **Discovery collection card** — section title "Discoveries" with total count. Two sub-sections:
   - **By rarity**: Rarity rows (reuse `_RarityRow` pattern from ProfileScreen) — legendary/rare/uncommon/common with coloured dots and counts. Rare+ tiers get a subtle `DanderElevation.rarityGlow` on the dot.
   - **By category**: Horizontal wrap of category chips showing icon + count (e.g. "cafe 3", "park 5"). Categories with 0 discovered show as muted/locked state. This creates a "collection" feel — users can see what categories they haven't found yet.

5. **Learning mastery card** — section title "Quiz Mastery" with overall mastery %. Four-segment horizontal bar showing mastered/review/learning/new proportions (green/blue/amber/muted). Below: counts for each state with coloured dot + label (reuse `MasteryBadge` pattern from QuizHomeScreen).

6. **Recent activity** (nice-to-have) — last 5 walks/discoveries as a compact timeline. Each entry: icon (walk/discovery), name/description, relative timestamp ("2 days ago"). Tappable rows for future drill-down.

### Animation & motion
- **Staggered entrance**: Sections animate in with 40ms stagger delay, using `SlideTransition` + `FadeTransition` (bottom-up, ease-out, 250ms). Respect `DanderMotion.isReduced`.
- **Count-up numbers**: Stat values animate from 0 → actual value using existing `CountUpText` widget (already in the codebase). Skip when reduced motion.
- **Progress bar fill**: XP bar animates from 0 → current progress over 400ms on first build. Skip when reduced motion.
- **Hero transition**: Zone name and level badge use a shared element / hero transition from the ZoneCard for spatial continuity.

### Tokens & consistency
- Background: `DanderColors.surfaceElevated` (matches ZonesScreen, ProfileScreen)
- Cards: `DanderColors.cardBackground` with `DanderColors.cardBorder` + `DanderElevation.level1`
- Section titles: `DanderTextStyles.titleLarge`
- Stat values: `DanderTextStyles.headlineSmall` or `titleLarge`
- Body text: `DanderTextStyles.bodySmall` / `bodyMedium`
- All spacing from `DanderSpacing` constants
- `ScreenHeader` for the top title area (consistent with all other screens)

## Requirements (must)
- [ ] Tapping a ZoneCard navigates to ZoneDetailScreen with a push transition
- [ ] Back button returns to zones list (preserve scroll position)
- [ ] Hero header shows zone name, "Lv.X" badge, created date, and exploration ring
- [ ] XP progress card: current XP, next level threshold, 6pt progress bar, current + next radius
- [ ] Exploration stats: streets walked, discoveries found, distance walked (filtered by zone geography)
- [ ] Discovery breakdown by rarity tier with coloured indicators
- [ ] Discovery breakdown by category with collection-style chips
- [ ] Learning mastery: segmented bar + counts for mastered/review/learning/new
- [ ] All data filtered by geographic proximity to zone centre within zone radius
- [ ] Loading skeleton shown while data resolves
- [ ] Empty states for sections with no data (encouraging language, not error language)
- [ ] Stat numbers animate with CountUpText on first load
- [ ] Staggered section entrance animation (respects reduced motion)

## Nice-to-haves
- [ ] Recent activity timeline (last 5 walks + discoveries)
- [ ] Hero transition on zone name/level badge from card to detail
- [ ] XP progress bar animated fill on first load
- [ ] Accent glow on level badge at L4+ (uses `DanderElevation.accentGlow`)
- [ ] Category chips tappable to show individual discovery names
- [ ] "Next milestone" callout: "12 more streets to Lv.3"

## Acceptance criteria (definition of done)
- [ ] Tapping zone card pushes ZoneDetailScreen; back returns to list with scroll preserved
- [ ] Header displays zone name, level badge, created date, exploration ring
- [ ] XP section shows progress bar, XP text, radius info
- [ ] Exploration stats display correct counts filtered by zone geography
- [ ] Discovery breakdown shows rarity and category counts
- [ ] Learning mastery shows segmented bar and state distribution
- [ ] Loading skeleton shown while data resolves
- [ ] Empty states display encouraging copy (not error states)
- [ ] CountUpText animates stat values; animations skipped under reduced motion
- [ ] Staggered entrance animates sections; skipped under reduced motion
- [ ] All existing tests still pass
- [ ] Widget tests cover ZoneDetailScreen sections (header, stats, discoveries, mastery)
- [ ] Unit tests cover ZoneStatsService geo-filtering and aggregation
- [ ] `flutter analyze` clean, `flutter test` green

## Risks / constraints
- **No zone-entity FK**: Walks, streets, discoveries stored globally — must filter by geographic proximity at query time. Use bounding box pre-filter then Haversine for accuracy.
- **Performance**: Filtering all entities by distance could be expensive. Bounding box pre-filter (lat/lng ± radius in degrees) reduces candidate set before Haversine. Consider caching results in ZoneStatsService.
- **Repository access**: Screen needs 5 repositories (Zone, Street, Discovery, Quiz, Walk). Wire through a `ZoneStatsService` registered in service locator — screen depends on one service, not five repos.
- **Walk-zone association**: Walk sessions have point arrays. A walk "belongs" to a zone if any walk point falls within the zone radius. Use bounding box check on walk start/end points for efficiency.
- **Category data**: Discovery categories come from OSM tags — some may be "unknown". Filter these out of the category chips or show as "Other".
- **Exploration %**: Calculate as (discovered POIs within zone radius) / (total cached POIs within zone radius). Handle division by zero.

## Issue breakdown

### Issue 1: ZoneStatsService — geo-filtered aggregation layer
- **Description**: Create `ZoneStatsService` that aggregates zone-scoped stats from all repositories. Methods: `getStats(Zone zone)` returning a `ZoneStats` data class with: streets walked count, discovery count, discoveries by category (Map<String, int>), discoveries by rarity (Map<RarityTier, int>), total distance walked, quiz mastery counts (Map<MemoryState, int>), exploration percentage, and recent activity list. Use bounding box pre-filter (lat/lng ± radius converted to degrees) then Haversine distance check. Register in service locator.
- **Acceptance**: `ZoneStatsService.getStats()` returns correct aggregated data. Bounding box pre-filter reduces candidate set. Unit tests with known coordinates inside/outside zone radius. Tests for category grouping, rarity counting, mastery state aggregation, and exploration % calculation.
- **Test plan**: Unit tests with mock repositories and known coordinates. Test boundary conditions (POI exactly at radius edge). Test empty data returns zero counts. Test "unknown" category handling.

### Issue 2: ZoneDetailScreen UI — header, XP, stats, discoveries, mastery
- **Description**: Create `ZoneDetailScreen` that receives a zone ID, loads zone + stats from `ZoneStatsService`, and renders all sections per the design direction above. Include: hero header with exploration ring, XP progress card, exploration stats row with CountUpText, discovery collection card (rarity rows + category chips), learning mastery card with segmented bar. Use `DanderColors`/`DanderTextStyles`/`DanderElevation` tokens. Include loading skeleton (`ZoneDetailLoadingSkeleton`) and encouraging empty states. Add staggered entrance animation (40ms per section, 250ms duration, ease-out, respects `DanderMotion.isReduced`).
- **Acceptance**: Screen renders all sections with correct data. Loading skeleton shown during fetch. Empty states use encouraging language. CountUpText animates numbers. Staggered entrance works and respects reduced motion. Matches existing app design patterns (ProfileScreen, ZonesScreen).
- **Test plan**: Widget tests with mock ZoneStatsService. Test loading, populated, and empty states. Test section rendering. Test that reduced motion skips animations.

### Issue 3: Navigation wiring — ZoneCard tap pushes ZoneDetailScreen
- **Description**: Wire `onZoneTapped` in ZonesScreen to push ZoneDetailScreen via app router. Register `/zones/:id` route in AppRouter. Pass zone ID as route parameter. Ensure back navigation preserves zones list scroll position.
- **Acceptance**: Tapping zone card navigates to detail screen. Back returns to zones list at previous scroll position. Route registered in AppRouter with zone ID parameter.
- **Test plan**: Widget test verifying navigation callback fires. Verify route is registered. Test back navigation preserves state.

## PR discipline
- Branch → PR only
- PR body includes: `Closes #…`
- Commands to run (paste output in PR):
  - `flutter analyze`
  - `flutter test`
