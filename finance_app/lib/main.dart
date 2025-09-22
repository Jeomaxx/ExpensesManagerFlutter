import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';

import 'src/app.dart';
import 'src/core/services/database_service.dart';
import 'src/core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize EasyLocalization
  await EasyLocalization.ensureInitialized();
  
  // Initialize Firebase (with error handling)
  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp();
    firebaseInitialized = true;
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization failed: $e');
    print('App will continue without Firebase features');
  }
  
  // Initialize local database
  await DatabaseService.instance.database;
  
  // Initialize notifications (only if Firebase is available)
  try {
    await NotificationService.instance.initialize(firebaseAvailable: firebaseInitialized);
  } catch (e) {
    print('Notification service initialization failed: $e');
  }
  
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('ar', 'SA'), // Arabic
        Locale('en', 'US'), // English
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar', 'SA'),
      child: const ProviderScope(
        child: FinanceApp(),
      ),
    ),
  );
}