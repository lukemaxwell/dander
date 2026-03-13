# Dander

A fog-of-war neighbourhood explorer app. Reveal your neighbourhood as you walk, collect discoveries, and track your exploration progress.

## Getting started

### Prerequisites

- Flutter 3.x (stable channel)
- Dart 3.x

### Install dependencies

```bash
flutter pub get
```

### Run the app

```bash
flutter run
```

### Build

```bash
# Android
flutter build apk

# iOS
flutter build ios --no-codesign
```

## Development

### Project structure

```
lib/
  core/
    di/           # Dependency injection (GetIt)
    navigation/   # GoRouter setup and route names
    theme/        # Colour palette and ThemeData
  features/
    map/          # Fog-of-war map screen
    discoveries/  # Discovery collection screen
    profile/      # User profile and stats screen
  shared/
    widgets/      # Shared UI components (AppShell, etc.)
  main.dart
test/
  core/           # Unit tests for core modules
  features/       # Widget and unit tests per feature
```

### Commands

```bash
# Static analysis
flutter analyze

# Format check
dart format --set-exit-if-changed .

# Tests with coverage
flutter test --coverage

# Coverage report (requires lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Roadmap

See [specs/dander-mvp.md](specs/dander-mvp.md) for the full feature specification and issue breakdown.

| Issue | Feature | Status |
|-------|---------|--------|
| #1 | Project scaffolding, CI, base architecture | In progress |
| #2 | Fog-of-war rendering engine | Planned |
| #3 | Location tracking service | Planned |
| #4 | Discovery system — POI loading, proximity detection | Planned |
| #5 | Discovery Card UI and collection screen | Planned |
| #6 | Walk tracking UI — start/stop, live stats, summary | Planned |
| #7 | Exploration progress — percentage, streaks, badges | Planned |
| #8 | Sharing — coverage map, discovery cards, walk summary | Planned |
| #9 | Offline support and local data persistence | Planned |
