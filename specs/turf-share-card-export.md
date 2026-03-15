# SPEC: Turf share card export

## Goal
Make the turf share card so visually striking that users *want* to share it — a prestige artefact
of their exploration that stands out in a feed — then make sharing it effortless.

## Why this matters
Sharing is the primary organic growth loop. Every share is a Dander ad in the social feeds of
people who don't have the app. The card must earn attention: it should look like a trophy, not a
screenshot.

## Non-goals
- Social-network-specific deep links or UTM tracking.
- Scheduled or automatic sharing.
- Sharing multiple zones at once.
- Live/animated GIF export (static PNG only).

## Users / scenario
A user levels up, clears 50%+ fog, or just finishes a satisfying walk. They open the zone detail
screen, feel proud, and want to show it off. The share experience must reinforce that feeling — a
preview that makes them smile before they hit Send.

---

## Part 1 — TurfShareCard visual redesign

The existing card is functional but generic. It needs to feel like a collectible. All changes are
in `lib/features/sharing/presentation/widgets/turf_share_card.dart`.

### Card dimensions
Keep 1080 × 1350 (4:5 portrait — Instagram / iMessage optimised).

### Background: star-field + coordinate grid
Replace the plain gradient with two layers painted by a private `CustomPainter`:

1. **Base gradient** — keep `Color(0xFF0F0F1A)` → `Color(0xFF1A1A2E)` top-left → bottom-right.
2. **Coordinate grid** — faint lines every ~60px, `Color(0xFFFFFFFF)` at 4% opacity, stroke 0.5px.
   Gives a map/cartography feel without being heavy.
3. **Star field** — 40 dots at random positions, radii 1–3px, opacity 15–40%, white. Seeded from
   `zone.id.hashCode` so they are stable per zone (not random on each render).

### Territory silhouette — glow treatment
Replace flat amber cells with a two-pass paint:

1. **Glow pass** — for each explored cell, draw a larger rect (cell + 8px bleed) with
   `MaskFilter.blur(BlurStyle.normal, 12)` and `Color(0xFFFFC107)` at 20% opacity.
   This creates a warm aura around the explored territory.
2. **Fill pass** — draw the actual cells in `Color(0xFFFFC107)` at 85% opacity (same as before
   but slightly more saturated).
3. **Exploration ring** — drawn by `_ExplorationRingPainter` (see below) around the territory
   preview area. A 6px arc from 0° → (explorationPct × 360°), amber, with a bright dot at the
   tip. Background track at 8% white. Identical visual language to the app's XP ring.

### Exploration % as headline stat
Swap street count from the primary number role. New layout (bottom section):

```
┌─────────────────────────────────────┐
│  [ring] 67%          34 streets     │
│         explored     walked         │
└─────────────────────────────────────┘
```

- `explorationPct` formatted as `"${pct.round()}%"` — 96px, w900, white, letter-spacing -2
- `"explored"` — 28px, w400, white60
- `streetCount` — 56px, w700, amber
- `"streets walked"` — 28px, w400, white60
- Separated by a faint 1px vertical divider

`TurfShareCard` gains `required double explorationPct` parameter.
`TurfShareCardData` gains `exploredPct` field (double, 0.0–1.0).

### Level badge — gold gradient treatment
Replace flat amber border with a shimmer gradient border (double-Container pattern):

- Outer Container: `LinearGradient([Color(0xFFFFD700), Color(0xFFFFC107), Color(0xFFFF8F00)])`, borderRadius 100, padding 2px
- Inner Container: `Color(0xFF1A1A2E)` fill, same radius
- Text: `"Level X Explorer"` in existing style

### Zone name — cartographic serif feel
Keep Space Grotesk / existing bold style but add a subtle amber text shadow:
```dart
shadows: [Shadow(color: Color(0xFFFFC107).withAlpha(60), blurRadius: 16, offset: Offset(0, 4))]
```

### Footer — bolder Dander watermark
- Left: Dander "D" logo mark (existing purple square, slightly larger: 48px)
- Right: `"dander.app"` in white at 35% opacity, 24px
- Centre: a thin 1px amber divider line spanning the full width above the footer

### `TurfShareCardData` updates
```dart
class TurfShareCardData {
  final String zoneName;
  final int level;
  final int streetCount;
  final int exploredCellCount;
  final double exploredPct;   // NEW: 0.0–1.0, drives the ring and headline
}
```

`TurfShareCard` signature update:
```dart
const TurfShareCard({
  required Zone zone,
  required int streetCount,
  required double explorationPct,  // NEW
  FogGrid? fogGrid,
});
```

---

## Part 2 — Share preview sheet (new UX flow)

Instead of immediately invoking the share sheet, tap opens a `TurfSharePreviewSheet` bottom sheet.
This is the "moment of pride" — user sees a gorgeous preview of their card before sharing.

### File
`lib/features/subscription/presentation/widgets/turf_share_preview_sheet.dart`
(lives in sharing, not subscription)
→ `lib/features/sharing/presentation/widgets/turf_share_preview_sheet.dart`

### Sheet layout
Full-height modal bottom sheet (`isScrollControlled: true`, `DraggableScrollableSheet`), dark
background (`DanderColors.surface`), rounded top corners (24px):

```
┌────────────────────────────────┐
│ ●●● drag handle                │
│                                │
│  YOUR TURF                     │  ← labelMedium, secondary, letter-spacing 3
│  Hackney                       │  ← headlineLarge, white, w900
│                                │
│  ┌──────────────────────────┐  │
│  │                          │  │
│  │   [TurfShareCard         │  │  ← scaled to fit (Transform.scale)
│  │    preview, ~0.35 scale] │  │  ← subtle drop shadow beneath card
│  │                          │  │
│  └──────────────────────────┘  │
│                                │
│  Caption (optional, editable): │  ← labelSmall, onSurfaceMuted
│  ┌──────────────────────────┐  │
│  │ I've mapped 67% of       │  │  ← TextField, pre-filled, 2 lines max
│  │ Hackney on @DanderApp    │  │
│  └──────────────────────────┘  │
│                                │
│  [    Share your turf  →  ]   │  ← ElevatedButton, amber, full width, 56px
│  [    Save to Photos      ]   │  ← OutlinedButton, cardBorder, full width, 48px
└────────────────────────────────┘
```

### Behaviour
- Sheet opens immediately on share tap (no async wait). Card preview renders synchronously.
- "Share your turf →" tap:
  1. Shows spinner in button (disabled state)
  2. Calls `ShareService.captureWidget(TurfShareCard(...), size: Size(1080, 1350))`
  3. Calls `ShareService.shareImage(bytes, subject: captionController.text)`
  4. Fires `ZoneTurfShared` analytics
  5. Pops the sheet on success
- "Save to Photos" tap:
  1. Captures card (same as above)
  2. Uses `ImageGallerySaver` or `Gal` package to save to camera roll
  3. Shows snackbar "Saved to Photos"
- Both buttons show error snackbar on failure with retry
- Pre-filled caption: `"I've mapped ${pct}% of ${zoneName} with @DanderApp 🗺"`
  - User can edit or clear it; caption attached as Share text (not burned into PNG)

### Animation
- Sheet entrance: standard `showModalBottomSheet` slide-up, 300ms easeOutCubic
- Card preview: `FadeTransition` + `SlideTransition` (from 8px below), 350ms, 100ms delay after sheet opens
- Share button: `Pressable`-style scale 0.97 on press

---

## Part 3 — Zone detail share entry point

Replace the small icon button in the header with a more prominent bottom action.

### Change
Remove icon from header (too subtle, competes with back button).

Add to the bottom of `ZoneDetailScreen`, outside the scroll, above the safe area:

```dart
SafeArea(
  child: Padding(
    padding: EdgeInsets.fromLTRB(DanderSpacing.lg, 0, DanderSpacing.lg, DanderSpacing.md),
    child: SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _openShareSheet,
        icon: Icon(Icons.ios_share, size: 20),
        label: Text('Share your turf'),
        style: ElevatedButton.styleFrom(
          backgroundColor: DanderColors.secondary,
          foregroundColor: DanderColors.onSecondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DanderSpacing.borderRadiusMd)),
          elevation: 0,
        ),
      ),
    ),
  ),
)
```

`_openShareSheet()`:
1. Loads `FogGrid` via `FogRepository` (async, show brief skeleton shimmer on button text)
2. Computes `explorationPct` from `ZoneStats.explorationPct` (already in `stats`)
3. Opens `TurfSharePreviewSheet` via `showModalBottomSheet`

Button is visible as soon as stats are loaded (same condition as existing stats rendering).
Haptic: `HapticService.light()` on tap.

---

## Requirements (must)
- [ ] `TurfShareCard` redrawn with: star-field background, coordinate grid, glow silhouette, exploration ring, % headline stat, gradient level badge, amber zone name shadow
- [ ] `TurfShareCardData` and `TurfShareCard` updated with `exploredPct` parameter
- [ ] `TurfSharePreviewSheet` bottom sheet: scaled card preview, editable caption, Share + Save buttons
- [ ] Share button in `ZoneDetailScreen` is full-width amber CTA, not a header icon
- [ ] Caption pre-filled from zone data; included as share text (not burned into PNG)
- [ ] Loading state on Share button: spinner, disabled, no double-tap
- [ ] Error snackbar on capture failure
- [ ] `ZoneTurfShared` analytics event on success
- [ ] All design tokens used — no hardcoded hex in widget files except `TurfShareCard` (which is a self-contained image renderer, not an app screen)
- [ ] `DanderMotion.isReduced()` respected — skip card preview fade-in animation

## Nice-to-haves
- [ ] "Save to Photos" button (requires `gal` package)
- [ ] Star-field dots seeded from `zone.id.hashCode` for stability
- [ ] Exploration ring animated (spins in on sheet open, 500ms ease-out)
- [ ] Haptic success feedback after share completes

## Acceptance criteria (definition of done)
- [ ] Zone detail screen shows "Share your turf" amber button at bottom
- [ ] Tapping opens preview sheet with scaled card and caption field
- [ ] Card preview shows: zone name, level badge, territory glow, exploration ring, % explored, street count, star-field background, coordinate grid, Dander logo
- [ ] "Share your turf →" triggers native share sheet with PNG + caption text
- [ ] PNG is 1080×1350 with all visual elements rendered
- [ ] Error recovery: snackbar with retry
- [ ] `ZoneTurfShared` fires with correct properties
- [ ] Widget tests cover: preview sheet renders, share path, error path, analytics event

## Risks / constraints
- `WidgetRenderer.render()` requires Flutter rendering pipeline — mock `ShareService` in widget tests.
- `FogGrid` may be null — `TurfShareCard` handles this gracefully (placeholder shown).
- Glow pass in `_TerritoryPainter` with `MaskFilter.blur` is GPU-intensive. Only called during offscreen render (not on-screen), so perf is acceptable. Time the render on an iPhone X-class device (<1.5s target).
- `gal` package (Save to Photos) requires `NSPhotoLibraryAddUsageDescription` in `Info.plist` on iOS and `WRITE_EXTERNAL_STORAGE` on Android <10.

---

## Issue breakdown

### #182 — Add `ZoneTurfShared` analytics event *(already created)*

### #183 — Redesign `TurfShareCard` for prestige visual quality
- Description: Rewrite `TurfShareCard` and `TurfShareCardData` per Part 1 of the spec. Add star-field + grid background, glow silhouette, exploration ring, % headline stat, gradient level badge, amber zone name shadow. Add `exploredPct` parameter.
- Acceptance: Visual diff shows all new elements; existing `fogGrid: null` fallback still works.
- Test plan: Widget test renders with fog grid and without. Golden test for visual regression.

### #184 — `TurfSharePreviewSheet`: preview + caption + share flow
- Description: New bottom sheet widget per Part 2. Scaled card preview, editable caption, Share + Save buttons. Wires `ShareService.captureWidget` and `shareImage`. Fires analytics.
- Acceptance: Sheet opens, preview renders, share sheet invoked with PNG + caption, analytics fires.
- Test plan: Widget tests with mocked `ShareService` — success, error, loading state, caption pre-fill.

### #185 — Wire "Share your turf" CTA into ZoneDetailScreen
- Description: Remove header icon, add full-width amber button at bottom per Part 3. Opens `TurfSharePreviewSheet` with zone + stats data. Haptic on tap.
- Acceptance: Button visible after stats load; tapping opens preview sheet.
- Test plan: Widget test for button presence; mock sheet open.

---

## PR discipline
- Branch per issue: `feat/share-183-card-redesign`, `feat/share-184-preview-sheet`, `feat/share-185-zone-detail-cta`
- Merge order: #182 → #183 → #184 → #185
- PR body includes: `Closes #59` on final PR (#185)
- Commands:
  - `flutter analyze`
  - `flutter test`
