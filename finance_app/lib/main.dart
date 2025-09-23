// Foundation import removed - unnecessary
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import 'src/app.dart';
import 'src/core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize EasyLocalization
  await EasyLocalization.ensureInitialized();
  
  // Initialize notification service (handles platform detection internally)
  try {
    await NotificationService.instance.initialize();
  } catch (e) {
    debugPrint('Notification service initialization failed: $e');
  }
  
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('ar', 'SA'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en', 'US'),
      child: const ProviderScope(
        child: FinanceApp(),
      ),
    ),
  );
}