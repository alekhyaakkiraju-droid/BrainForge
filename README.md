# BrainForge

Gamified academic companion + ScienceSpark summer discovery app for kids aged 6–14.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI / Framework | Flutter 3.22+ / Dart 3.4+ |
| State management | Riverpod 2 + riverpod_generator |
| Navigation | GoRouter 14 |
| Game engine | Flame 1.x (ScienceSpark missions) |
| Offline storage | Hive 2 |
| Backend / Sync | Firebase (Firestore, Auth, Analytics, Crashlytics, App Check) |
| Animations | Lottie |

## Project Structure

```
lib/
├── core/           # App-wide utilities: router, theme, errors, logging
├── domain/         # Entities, repository interfaces, use-cases (no Flutter deps)
├── data/           # Repository implementations, Hive models, Firestore mappers
└── presentation/   # Screens, widgets, Riverpod providers (UI only)
```

## Getting Started

```bash
# Install dependencies
flutter pub get

# Run code generation (Riverpod, Hive, Freezed)
dart run build_runner build --delete-conflicting-outputs

# Run on iPad simulator (dev flavor)
flutter run --flavor dev -t lib/main.dart

# Analyze
flutter analyze

# Test
flutter test
```

> **Firebase credentials** are not committed. See `docs/firebase_setup.md`
> to configure the three Firebase projects (WO-002).

## Branch Convention

`wo/WO-XXX-short-description` — one branch per work order.
