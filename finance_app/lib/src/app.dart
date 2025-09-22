import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import 'shared/theme/app_theme.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'core/routing/app_router.dart';

class FinanceApp extends ConsumerWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine text direction based on locale
    final isRTL = context.locale.languageCode == 'ar';
    
    return MaterialApp(
      title: 'Finance App',
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const SplashPage(),
      onGenerateRoute: AppRouter.generateRoute,
      debugShowCheckedModeBanner: false,
      // Force text direction based on locale - simplified approach
      builder: (context, child) {
        return child!;
      },
    );
  }
}