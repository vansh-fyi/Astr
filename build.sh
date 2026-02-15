#!/bin/bash
set -e

FLUTTER_VERSION="3.35.1"

echo "=== Astr Web Build ==="
echo "Flutter target: $FLUTTER_VERSION"

# Install Flutter (cached between builds on Vercel)
if [ ! -d "$HOME/flutter" ]; then
  echo "Installing Flutter $FLUTTER_VERSION..."
  git clone https://github.com/flutter/flutter.git -b "$FLUTTER_VERSION" "$HOME/flutter"
else
  echo "Flutter found, checking version..."
  cd "$HOME/flutter"
  CURRENT=$(git describe --tags --abbrev=0 2>/dev/null || echo "unknown")
  if [ "$CURRENT" != "$FLUTTER_VERSION" ]; then
    echo "Updating Flutter from $CURRENT to $FLUTTER_VERSION..."
    git fetch --tags
    git checkout "$FLUTTER_VERSION"
  fi
  cd -
fi

export PATH="$HOME/flutter/bin:$PATH"

# Precache web artifacts
flutter precache --web

# Get dependencies
flutter pub get

# Build web release
flutter build web --release --base-href="/"

echo "=== Build complete ==="
