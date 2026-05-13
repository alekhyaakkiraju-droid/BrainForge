# GitHub Actions Secrets Reference

All secrets must be added to the repository under **Settings → Secrets and variables → Actions**.

## Firebase

| Secret | Description |
|--------|-------------|
| `FIREBASE_CLI_TOKEN` | Firebase CI token (`firebase login:ci`) |
| `GOOGLE_SERVICES_JSON_STAGING` | Full content of `google-services.json` for brainforge-staging |
| `GOOGLE_SERVICES_JSON_PROD` | Full content of `google-services.json` for brainforge-prod |
| `GOOGLE_SERVICE_INFO_PLIST_STAGING` | Full content of `GoogleService-Info.plist` for brainforge-staging |
| `GOOGLE_SERVICE_INFO_PLIST_PROD` | Full content of `GoogleService-Info.plist` for brainforge-prod |
| `FIREBASE_ANDROID_API_KEY_DEV` | Android API key for brainforge-dev |
| `FIREBASE_ANDROID_APP_ID_DEV` | Android App ID for brainforge-dev |
| `FIREBASE_ANDROID_SENDER_ID_DEV` | Android Sender ID for brainforge-dev |
| `FIREBASE_IOS_API_KEY_DEV` | iOS API key for brainforge-dev |
| `FIREBASE_IOS_APP_ID_DEV` | iOS App ID for brainforge-dev |
| `FIREBASE_IOS_SENDER_ID_DEV` | iOS Sender ID for brainforge-dev |
| *(repeat for STAGING and PROD)* | |

## Android (Google Play)

| Secret | Description |
|--------|-------------|
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded release keystore (.jks) |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_PASSWORD` | Key password |
| `ANDROID_KEY_ALIAS` | Key alias |
| `PLAY_STORE_JSON_KEY` | Google Play service account JSON key content |

## iOS (App Store)

| Secret | Description |
|--------|-------------|
| `ASC_KEY_ID` | App Store Connect API key ID |
| `ASC_ISSUER_ID` | App Store Connect issuer ID |
| `ASC_KEY_CONTENT` | App Store Connect API key content (base64) |
| `MATCH_PASSWORD` | Fastlane Match encryption password |
| `MATCH_GIT_BASIC_AUTHORIZATION` | Base64-encoded `username:token` for Match repo |

## Workflow Triggers Summary

| Event | Workflow | Target |
|-------|----------|--------|
| Pull request → main | `pr_check.yml` | analyze + test + rules |
| Push to main | `deploy_staging.yml` | build + deploy staging |
| Push tag `v*` | `deploy_production.yml` | build + deploy prod |
