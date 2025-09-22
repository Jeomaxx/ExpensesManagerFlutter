import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/account_repository.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/user_repository.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

// Repository Providers
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService.instance;
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository.instance;
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository.instance;
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository.instance;
});

// Service Providers
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});

// App Settings Provider
final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  return AppSettingsNotifier();
});

class AppSettings {
  final String language;
  final String currency;
  final bool isDarkMode;
  final bool notificationsEnabled;
  final bool biometricEnabled;

  const AppSettings({
    this.language = 'ar',
    this.currency = 'SAR',
    this.isDarkMode = false,
    this.notificationsEnabled = true,
    this.biometricEnabled = false,
  });

  AppSettings copyWith({
    String? language,
    String? currency,
    bool? isDarkMode,
    bool? notificationsEnabled,
    bool? biometricEnabled,
  }) {
    return AppSettings(
      language: language ?? this.language,
      currency: currency ?? this.currency,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }
}

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier() : super(const AppSettings());

  void updateLanguage(String language) {
    state = state.copyWith(language: language);
  }

  void updateCurrency(String currency) {
    state = state.copyWith(currency: currency);
  }

  void toggleDarkMode() {
    state = state.copyWith(isDarkMode: !state.isDarkMode);
  }

  void toggleNotifications() {
    state = state.copyWith(notificationsEnabled: !state.notificationsEnabled);
  }

  void toggleBiometric() {
    state = state.copyWith(biometricEnabled: !state.biometricEnabled);
  }
}