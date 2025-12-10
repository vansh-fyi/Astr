#!/bin/bash
set -e

echo "Installing Flutter..."

# Install Flutter
if [ ! -d "$HOME/flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 $HOME/flutter
fi

# Add Flutter to PATH
export PATH="$HOME/flutter/bin:$PATH"

# Enable web support
flutter config --enable-web

# Get dependencies
flutter pub get

# Build web app
flutter build web --release --web-renderer canvaskit

echo "Build completed successfully!"
