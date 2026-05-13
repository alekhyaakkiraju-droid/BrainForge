#!/usr/bin/env bash
# Sets up per-flavor Firebase credential files for local development.
#
# Prerequisites: real credential files must already exist (obtained from
# the Firebase Console or a team secret manager).
#
# Usage:
#   chmod +x scripts/setup_firebase_credentials.sh
#   ./scripts/setup_firebase_credentials.sh dev       # copy dev credentials
#   ./scripts/setup_firebase_credentials.sh staging   # copy staging credentials
#   ./scripts/setup_firebase_credentials.sh prod      # copy prod credentials
#   ./scripts/setup_firebase_credentials.sh all       # copy all three

set -euo pipefail

FLAVOR="${1:-all}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"

copy_android() {
  local env="$1"
  local src="$ROOT/android/app/src/$env/google-services.json"
  local dst="$ROOT/android/app/google-services.json"
  if [[ ! -f "$src" ]]; then
    echo "❌  Missing: $src"
    echo "   Copy the real google-services.json for '$env' from the Firebase Console."
    exit 1
  fi
  cp "$src" "$dst"
  echo "✅  Android [$env]: google-services.json copied to android/app/"
}

copy_ios() {
  local env="$1"
  local src="$ROOT/ios/config/$env/GoogleService-Info.plist"
  local dst="$ROOT/ios/Runner/GoogleService-Info.plist"
  if [[ ! -f "$src" ]]; then
    echo "❌  Missing: $src"
    echo "   Copy the real GoogleService-Info.plist for '$env' from the Firebase Console."
    exit 1
  fi
  cp "$src" "$dst"
  echo "✅  iOS [$env]: GoogleService-Info.plist copied to ios/Runner/"
}

case "$FLAVOR" in
  dev|staging|prod)
    copy_android "$FLAVOR"
    copy_ios "$FLAVOR"
    echo ""
    echo "Run the app with: flutter run --flavor $FLAVOR --dart-define=FLAVOR=$FLAVOR"
    ;;
  all)
    for env in dev staging prod; do
      copy_android "$env" || true
      copy_ios "$env" || true
    done
    ;;
  *)
    echo "Usage: $0 [dev|staging|prod|all]"
    exit 1
    ;;
esac
