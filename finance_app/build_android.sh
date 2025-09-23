#!/bin/bash

# Production Android Build Script for Finance App
echo "Building Finance App for Android (Production)..."

# Check if signing config exists
if [ ! -f android/key.properties ]; then
    echo "WARNING: No signing configuration found!"
    echo "Create android/key.properties with:"
    echo "storePassword=<your-store-password>"
    echo "keyPassword=<your-key-password>"
    echo "keyAlias=<your-key-alias>"
    echo "storeFile=<path-to-keystore-file>"
    echo ""
fi

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build App Bundle for Google Play Store (recommended)
echo "Building App Bundle for Google Play Store..."
flutter build appbundle --release --target-platform android-arm,android-arm64,android-x64

# Build APK with ABI splits (for direct distribution)
echo "Building APK with ABI splits..."
flutter build apk --split-per-abi --release

echo "Android build completed!"
echo ""
echo "📱 App Bundle (for Play Store): build/app/outputs/bundle/release/app-release.aab"
echo "📦 APK files: build/app/outputs/flutter-apk/"
echo ""
echo "⚠️  IMPORTANT: Ensure signing is configured before Play Store upload!"
echo "📋 Next steps:"
echo "   1. Test on real devices"
echo "   2. Configure Play Console"
echo "   3. Upload AAB file to Play Store"