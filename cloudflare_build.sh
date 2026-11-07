#!/bin/bash
set -e

echo "=== Installing Flutter SDK on Cloudflare Build Machine ==="
if [ ! -d "$HOME/flutter" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
fi

export PATH="$PATH:$HOME/flutter/bin"
flutter --version

echo "=== Building Flutter Web (Release) ==="
flutter build web --release

echo "=== Copying SPA routing & headers ==="
cp web/_redirects build/web/_redirects 2>/dev/null || true
cp web/_headers build/web/_headers 2>/dev/null || true

echo "=== Build Complete ==="

