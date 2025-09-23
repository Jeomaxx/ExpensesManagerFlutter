# Finance App - Mobile Deployment Guide

## Overview
This Flutter Finance App has been configured for mobile deployment with support for both Android and iOS platforms.

## Current Status
- ✅ **Web Version**: Running successfully at port 5000 (simplified version)
- ⚠️ **Android Platform**: Platform configured, requires signing setup for production
- ⚠️ **iOS Platform**: Platform configured, requires macOS/Xcode for production builds
- ⚠️ **Build Scripts**: Created for both platforms, production-ready with signing guidance
- ✅ **Deployment Config**: Set up for autoscale web deployment

## ⚠️ Production Readiness Status
**This is a development/demo setup. Additional steps required for production:**
- Android: Configure signing certificates and keystore
- iOS: Configure Apple Developer account and code signing
- Both: Test on physical devices with release builds
- Store submission: Follow platform-specific review guidelines

## App Features
- Comprehensive finance management
- Transaction tracking
- Budget management
- Account management
- Financial goals
- Charts and visualization
- Arabic/English language support
- Secure storage and notifications

## Mobile Permissions Configured

### Android (AndroidManifest.xml)
- Internet access for data sync
- Network state monitoring
- Modern media permissions (Android 13+) and backward compatibility (Android 10-12)
- Camera for receipt scanning
- Notification permissions (requires runtime request on Android 13+)
- Biometric authentication

### iOS (Info.plist)
- Camera usage for receipt scanning
- Photo library read/write access for documents
- Face ID for secure authentication

## Building for Mobile

### Android APK
```bash
./build_android.sh
```
This creates:
- `build/app/outputs/flutter-apk/app-release.apk` (for direct installation)
- `build/app/outputs/bundle/release/app-release.aab` (for Google Play Store)

### iOS App
```bash
./build_ios.sh
```
This creates:
- `build/ios/iphoneos/Runner.app` (requires macOS and Xcode)

## Deployment Options

### Web Deployment (Current)
- **Target**: Autoscale deployment
- **Build**: `flutter build web --release`
- **Run**: Web server on port 5000
- **Features**: Responsive design, works on mobile browsers

### Mobile App Stores
- **Google Play**: Use the generated .aab file
- **Apple App Store**: Requires macOS with Xcode for final build and submission

## Architecture
- **Entry Points**: 
  - `lib/main_simple.dart` (web-compatible demo)
  - `lib/main.dart` (full-featured mobile app)
- **Platforms**: Android, iOS, Web
- **Language Support**: English, Arabic (RTL support)
- **Security**: Biometric authentication, secure storage

## Next Steps for Production
1. Configure app icons and branding
2. Set up proper signing certificates
3. Configure Firebase for notifications (optional)
4. Test on physical devices
5. Submit to app stores

## Development vs Production
- **Development**: Uses simple version for web compatibility
- **Production**: Full-featured mobile app with all finance capabilities