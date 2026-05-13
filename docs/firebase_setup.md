# Firebase Setup (WO-002)

This document describes how to wire in real Firebase credentials once
the three Firebase projects (`brainforge-dev`, `brainforge-staging`,
`brainforge-prod`) are created in WO-002.

## Prerequisites

```bash
dart pub global activate flutterfire_cli
npm install -g firebase-tools
firebase login
```

## Generate per-flavor firebase_options.dart

```bash
# Dev
flutterfire configure \
  --project brainforge-dev \
  --out lib/core/config/firebase_options_dev.dart \
  --platforms android,ios

# Staging
flutterfire configure \
  --project brainforge-staging \
  --out lib/core/config/firebase_options_staging.dart \
  --platforms android,ios

# Prod
flutterfire configure \
  --project brainforge-prod \
  --out lib/core/config/firebase_options_prod.dart \
  --platforms android,ios
```

Then update `lib/core/config/firebase_options.dart` to select the
correct options based on the active build flavor (via `--dart-define`
or `String.fromEnvironment`).

## Never commit credentials

`google-services.json`, `GoogleService-Info.plist`, and
`firebase_options*.dart` files are in `.gitignore`.
Store them in GitHub Actions secrets (see WO-003).
