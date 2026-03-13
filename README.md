# Dander

> **Your neighbourhood is a game world.**

Dander is a fog-of-war exploration game for the real world. As you walk, you lift the fog from your local streets — revealing the map of the places you've actually been. Mystery markers hide local gems sourced from OpenStreetMap: hidden cafés, forgotten parks, street art, historic landmarks. Walk there to unlock them.

The more you explore, the more your neighbourhood comes alive.

---

## North Star

Most people live in the same few square miles for years and still don't really *know* the place. They walk the same routes, miss the alley that leads to the best coffee, never find out that the unremarkable building on the corner was a Victorian bathhouse.

Dander makes local exploration feel like an adventure. It borrows the fog-of-war mechanic from strategy games — you only see the streets you've personally walked — and layers a discovery and progression system on top of the real world. Every walk chips away at the fog. Every discovery is a trophy. Every zone you master earns XP and levels up.

The north star is simple: **make going for a walk feel like playing a game, forever.**

---

## What it does

- **Fog of war** — the map starts dark. Walking literally reveals it, street by street, with smooth-edged fog that updates in real time.
- **Mystery POIs** — up to 3 `?` markers are always visible within your zone, sourced live from OpenStreetMap (pubs, parks, street art, viewpoints, cafés, historic sites). Walk within 50m to reveal them and earn XP.
- **Zones** — define named zones for the areas you explore (home, work, weekend patch). Each zone has its own XP, level, and fog coverage.
- **Street quiz** — streets you've walked become flashcard prompts. Spaced repetition (SM-2) keeps you sharp on your own neighbourhood geography.
- **Exploration badge** — a live percentage overlay shows how much of the visible map you've uncovered.
- **Streaks and badges** — weekly walk streaks, category badges for each type of discovery, level-up celebrations with confetti.
- **Walk sessions** — start a walk to earn street XP as you move. Stop to see your summary: distance, duration, fog cleared.
- **Discoveries collection** — every POI you find is saved with its name, category, rarity tier (common / uncommon / rare), and discovery date.

---

## Screenshots

_(add screenshots here)_

---

## Getting started

### Prerequisites

- Flutter 3.x (stable channel)
- Dart 3.x
- iOS 14+ or Android 5.0+

### Install

```bash
flutter pub get
flutter run
```

### Build

```bash
# iOS
flutter build ios --no-codesign

# Android
flutter build apk
```

---

## Development

### Project structure

```
lib/
  core/
    di/             # Dependency injection (GetIt)
    discoveries/    # Overpass client, proximity detection, rarity
    fog/            # FogGrid, FogPainter, FogLayer
    location/       # GPS service, walk session
    navigation/     # GoRouter routes
    theme/          # Colour palette, typography, spacing
    zone/           # Zone model, XP, level-up, mystery POIs, cooldown
  features/
    discoveries/    # Discovery collection screen and cards
    map/            # Fog-of-war map screen, POI markers, walk control
    profile/        # Streak, badges, exploration ring
    quiz/           # Street quiz — SM-2 spaced repetition
    splash/         # Animated splash screen
    zones/          # Zones list and zone cards
  shared/
    widgets/        # AppShell, DanderCard, DanderButton, confetti, flip card
  main.dart
test/
  core/             # Unit tests for core modules
  features/         # Widget and integration tests per feature
```

### Commands

```bash
# Tests
flutter test

# Tests with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html && open coverage/html/index.html

# Static analysis
flutter analyze

# Format
dart format .
```

---

## Roadmap

### Shipped

| # | Feature |
|---|---------|
| #1 | Project scaffolding, CI, base architecture |
| #2 | Fog-of-war rendering engine |
| #3 | Location tracking service |
| #4 | Discovery system — OSM POI loading, proximity detection, rarity |
| #5 | Discovery card UI and collection screen |
| #6 | Walk tracking — start/stop, live stats, summary card |
| #7 | Exploration progress — percentage, streaks, badges |
| #8 | Walk summary sharing |
| #9 | Offline support and local persistence (Hive) |
| #19–20 | Street data layer and GPS track intersection |
| #21–25 | Street quiz — SM-2 spaced repetition, question flow, daily streak |
| #33–39 | Full design system — typography, logo, icon, splash, theming, haptics |
| #40 | Screen polish — gradients, staggered lists, 3D flip card |
| #51–54 | Zone system — XP, levels, fog radius expansion, level-up overlay |
| #55 | Mystery POI markers — `?` overlays, arrival detection, trophy state |
| #57 | Zones list screen |
| #60 | Zone migration for existing data |
| #65–66 | Fog zoom desync fix, radial vignette |

### In progress / up next

| # | Feature |
|---|---------|
| #56 | POI category filter with cooldown |
| #58 | Global meta-progression profile screen |
| #59 | Turf share card — render and export |

---

## Tech stack

- **Flutter** — cross-platform iOS/Android
- **flutter_map + OpenStreetMap** — map tiles and POI data via Overpass API
- **Hive** — local persistence
- **GetIt** — dependency injection
- **GoRouter** — navigation
- **google_fonts** — Space Grotesk (headlines) + Inter (body)
- **geolocator** — GPS tracking
