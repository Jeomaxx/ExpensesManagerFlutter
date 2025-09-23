#!/bin/bash

# Production iOS Build Script for Finance App
echo "Building Finance App for iOS (Production)..."

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ ERROR: iOS builds require macOS and Xcode"
    echo "This script must be run on a Mac with Xcode installed"
    exit 1
fi

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ ERROR: Xcode is not installed or not in PATH"
    echo "Please install Xcode from the App Store"
    exit 1
fi

echo "⚠️  IMPORTANT: Ensure the following are configured:"
echo "   - Apple Developer account"
echo "   - Signing certificates"
echo "   - Provisioning profiles"
echo "   - App ID in Apple Developer Console"
echo ""

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build iOS for release
echo "Building iOS app..."
flutter build ios --release --no-codesign

echo ""
echo "🍎 iOS build completed!"
echo "📁 iOS app location: build/ios/iphoneos/Runner.app"
echo ""
echo "📋 Next steps for App Store deployment:"
echo "   1. Open ios/Runner.xcworkspace in Xcode"
echo "   2. Configure signing with your developer account"
echo "   3. Archive the app (Product > Archive)"
echo "   4. Upload to App Store Connect"
echo "   5. Submit for review"
echo ""
echo "💡 For automated builds, configure code signing and use:"
echo "   flutter build ipa --release"