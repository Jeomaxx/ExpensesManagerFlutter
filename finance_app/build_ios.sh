#!/bin/bash

# Build script for iOS deployment  
echo "Building Finance App for iOS..."

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build iOS (requires macOS and Xcode)
flutter build ios --release

echo "iOS build completed!"
echo "iOS app location: build/ios/iphoneos/Runner.app"
echo "Note: iOS builds require Xcode and macOS for App Store deployment"