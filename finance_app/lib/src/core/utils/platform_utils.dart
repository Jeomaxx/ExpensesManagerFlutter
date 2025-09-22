import 'package:flutter/foundation.dart';

class PlatformUtils {
  static bool get isWeb => kIsWeb;
  static bool get isMobile => !kIsWeb;
  
  static bool get supportsDatabase => !kIsWeb;
  static bool get supportsNotifications => !kIsWeb;
  static bool get supportsCamera => !kIsWeb;
  static bool get supportsVoiceInput => !kIsWeb;
  static bool get supportsFileSystem => !kIsWeb;
  static bool get supportsBiometrics => !kIsWeb;
  
  static String getUnsupportedMessage(String feature) {
    return '$feature is not available on web. Please use the mobile app for this feature.';
  }
  
  static void showWebLimitation(String feature) {
    if (kIsWeb) {
      print('Warning: $feature is not supported on web platform');
    }
  }
}