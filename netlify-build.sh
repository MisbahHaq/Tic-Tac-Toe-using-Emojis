#!/usr/bin/env bash
# Netlify build command: installs the Flutter SDK (cached between builds)
# and builds the web output that is published from build/web.
set -euo pipefail

FLUTTER_BRANCH="${FLUTTER_VERSION:-stable}"
CACHE_DIR="${NETLIFY_CACHE_DIR:-/opt/build/cache}"
FLUTTER_HOME="$CACHE_DIR/flutter-sdk"
FLUTTER_BIN="$FLUTTER_HOME/bin/flutter"

mkdir -p "$CACHE_DIR"

if [ ! -x "$FLUTTER_BIN" ]; then
  echo "Installing Flutter ($FLUTTER_BRANCH)..."
  rm -rf "$FLUTTER_HOME"
  git clone --depth 1 --branch "$FLUTTER_BRANCH" https://github.com/flutter/flutter.git "$FLUTTER_HOME"
fi

export PATH="$FLUTTER_HOME/bin:$PATH"

flutter config --no-analytics >/dev/null 2>&1 || true
flutter precache --web >/dev/null 2>&1 || true
flutter pub get
flutter build web --release