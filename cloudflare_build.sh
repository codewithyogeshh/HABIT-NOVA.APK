#!/bin/bash
set -e

# Prevent Git dubious ownership errors in CI containers
git config --global --add safe.directory '*' || true

echo "=== Installing Flutter SDK on Cloudflare Build Machine ==="
if [ ! -d "$HOME/flutter" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
fi

export PATH="$PATH:$HOME/flutter/bin"
flutter config --no-analytics || true
flutter --version

echo "=== Resolving Dependencies ==="
flutter pub get

echo "=== Building Flutter Web (Release) ==="
flutter build web --release

echo "=== Copying SPA Routing & Performance Headers ==="
cp web/_redirects build/web/_redirects 2>/dev/null || true
cp web/_headers build/web/_headers 2>/dev/null || true

echo "=== Verifying Build Output ==="
ls -la build/web/

echo "=== Cloudflare Build Complete ==="
