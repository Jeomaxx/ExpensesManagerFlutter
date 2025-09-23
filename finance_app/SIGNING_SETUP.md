# Mobile App Signing and Release Configuration

## Android Signing Setup

### 1. Create a Keystore
```bash
keytool -genkey -v -keystore finance-app-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias finance-app
```

### 2. Create key.properties file
Create `android/key.properties`:
```
storePassword=your_store_password
keyPassword=your_key_password  
keyAlias=finance-app
storeFile=../finance-app-key.jks
```

### 3. Configure app/build.gradle
Add signing configuration to `android/app/build.gradle.kts`:
```kotlin
// Load keystore properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}
```

## iOS Signing Setup

### 1. Apple Developer Account
- Enroll in Apple Developer Program ($99/year)
- Create App ID in Apple Developer Console
- Generate signing certificates

### 2. Xcode Configuration
- Open `ios/Runner.xcworkspace` in Xcode
- Set your Team ID in project settings
- Configure Bundle Identifier
- Enable automatic signing or configure manual signing

### 3. Provisioning Profiles
- Development: For testing on devices
- Distribution: For App Store submission

## Runtime Permissions

### Android (API 23+)
The app must request runtime permissions for:
- `POST_NOTIFICATIONS` (Android 13+)
- `CAMERA` (when scanning receipts)
- `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO` (when accessing photos)

### iOS
The app will prompt users for:
- Camera access (receipt scanning)
- Photo library access (document storage)
- Face ID/Touch ID (biometric authentication)

## Store Submission Checklist

### Google Play Store
- [ ] App Bundle (.aab) signed with release key
- [ ] Privacy Policy URL
- [ ] App descriptions and screenshots
- [ ] Content rating questionnaire
- [ ] Store listing graphics

### Apple App Store
- [ ] IPA file built with distribution certificate
- [ ] App Store Connect metadata
- [ ] Screenshots for all device sizes
- [ ] App Review Information
- [ ] Export compliance documentation

## Security Considerations
- Store signing keys securely (not in version control)
- Use environment variables or secure storage for sensitive data
- Follow platform security guidelines
- Regular security updates and dependency management