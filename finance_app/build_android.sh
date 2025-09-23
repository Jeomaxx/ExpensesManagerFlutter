#!/bin/bash

# Build script for Android deployment
echo "Building Finance App for Android..."

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build APK
flutter build apk --release

# Build App Bundle (for Google Play Store)
flutter build appbundle --release

echo "Android build completed!"
echo "APK location: build/app/outputs/flutter-apk/app-release.apk"
echo "App Bundle location: build/app/outputs/bundle/release/app-release.aab"