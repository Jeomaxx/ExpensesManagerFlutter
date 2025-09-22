import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

enum CurrencyCode {
  SAR, USD, EUR, EGP, AED, KWD, QAR, BHD, OMR, JOD, LBP
}

enum LanguageCode {
  ar, en
}

enum ThemeMode {
  light, dark, system
}

enum DateFormat {
  ddMMyyyy, // 01/12/2024
  MMddyyyy, // 12/01/2024
  yyyyMMdd, // 2024-12-01
  ddMMMyyyy, // 01 Dec 2024
}

enum NotificationFrequency {
  never, daily, weekly, monthly
}

class AppSettings {
  // Display Settings
  final CurrencyCode defaultCurrency;
  final LanguageCode language;
  final ThemeMode themeMode;
  final DateFormat dateFormat;
  final bool use24HourTime;
  final double textScaleFactor;

  // Privacy & Security
  final bool requireBiometricAuth;
  final bool requirePinAuth;
  final String? pinCode;
  final int autoLockMinutes;
  final bool hideBalancesInRecents;
  final bool allowScreenshots;

  // Notifications
  final bool enableNotifications;
  final bool enableBudgetAlerts;
  final bool enablePaymentReminders;
  final bool enableGoalReminders;
  final bool enableBalanceAlerts;
  final NotificationFrequency budgetReportFrequency;
  final int reminderLeadDays;

  // Backup & Sync
  final bool enableAutoBackup;
  final bool enableCloudSync;
  final String? lastBackupDate;
  final bool syncOnWifiOnly;

  // Transaction Settings
  final bool enableReceiptScanning;
  final bool enableVoiceInput;
  final bool suggestCategories;
  final bool enableLocationTracking;
  final String defaultTransactionAccount;
  final bool requireTransactionNotes;

  // Budget Settings
  final bool enableBudgetRollover;
  final bool strictBudgetMode;
  final int budgetWarningPercentage;
  final bool includePendingTransactions;

  // Goal Settings
  final bool enableGoalProjections;
  final bool showGoalProgress;
  final int goalReminderFrequency; // days

  // Export Settings
  final String defaultExportFormat; // PDF, CSV, JSON
  final bool includeDeletedData;
  final bool passwordProtectExports;

  // AI & Analytics
  final bool enableAIInsights;
  final bool shareDataForInsights;
  final int insightGenerationFrequency; // days

  const AppSettings({
    this.defaultCurrency = CurrencyCode.SAR,
    this.language = LanguageCode.ar,
    this.themeMode = ThemeMode.system,
    this.dateFormat = DateFormat.ddMMyyyy,
    this.use24HourTime = true,
    this.textScaleFactor = 1.0,
    this.requireBiometricAuth = false,
    this.requirePinAuth = false,
    this.pinCode,
    this.autoLockMinutes = 5,
    this.hideBalancesInRecents = false,
    this.allowScreenshots = true,
    this.enableNotifications = true,
    this.enableBudgetAlerts = true,
    this.enablePaymentReminders = true,
    this.enableGoalReminders = true,
    this.enableBalanceAlerts = true,
    this.budgetReportFrequency = NotificationFrequency.monthly,
    this.reminderLeadDays = 3,
    this.enableAutoBackup = false,
    this.enableCloudSync = false,
    this.lastBackupDate,
    this.syncOnWifiOnly = true,
    this.enableReceiptScanning = true,
    this.enableVoiceInput = true,
    this.suggestCategories = true,
    this.enableLocationTracking = false,
    this.defaultTransactionAccount = '',
    this.requireTransactionNotes = false,
    this.enableBudgetRollover = true,
    this.strictBudgetMode = false,
    this.budgetWarningPercentage = 80,
    this.includePendingTransactions = true,
    this.enableGoalProjections = true,
    this.showGoalProgress = true,
    this.goalReminderFrequency = 7,
    this.defaultExportFormat = 'PDF',
    this.includeDeletedData = false,
    this.passwordProtectExports = true,
    this.enableAIInsights = true,
    this.shareDataForInsights = false,
    this.insightGenerationFrequency = 7,
  });

  Map<String, dynamic> toJson() {
    return {
      'defaultCurrency': defaultCurrency.name,
      'language': language.name,
      'themeMode': themeMode.name,
      'dateFormat': dateFormat.name,
      'use24HourTime': use24HourTime,
      'textScaleFactor': textScaleFactor,
      'requireBiometricAuth': requireBiometricAuth,
      'requirePinAuth': requirePinAuth,
      'pinCode': pinCode,
      'autoLockMinutes': autoLockMinutes,
      'hideBalancesInRecents': hideBalancesInRecents,
      'allowScreenshots': allowScreenshots,
      'enableNotifications': enableNotifications,
      'enableBudgetAlerts': enableBudgetAlerts,
      'enablePaymentReminders': enablePaymentReminders,
      'enableGoalReminders': enableGoalReminders,
      'enableBalanceAlerts': enableBalanceAlerts,
      'budgetReportFrequency': budgetReportFrequency.name,
      'reminderLeadDays': reminderLeadDays,
      'enableAutoBackup': enableAutoBackup,
      'enableCloudSync': enableCloudSync,
      'lastBackupDate': lastBackupDate,
      'syncOnWifiOnly': syncOnWifiOnly,
      'enableReceiptScanning': enableReceiptScanning,
      'enableVoiceInput': enableVoiceInput,
      'suggestCategories': suggestCategories,
      'enableLocationTracking': enableLocationTracking,
      'defaultTransactionAccount': defaultTransactionAccount,
      'requireTransactionNotes': requireTransactionNotes,
      'enableBudgetRollover': enableBudgetRollover,
      'strictBudgetMode': strictBudgetMode,
      'budgetWarningPercentage': budgetWarningPercentage,
      'includePendingTransactions': includePendingTransactions,
      'enableGoalProjections': enableGoalProjections,
      'showGoalProgress': showGoalProgress,
      'goalReminderFrequency': goalReminderFrequency,
      'defaultExportFormat': defaultExportFormat,
      'includeDeletedData': includeDeletedData,
      'passwordProtectExports': passwordProtectExports,
      'enableAIInsights': enableAIInsights,
      'shareDataForInsights': shareDataForInsights,
      'insightGenerationFrequency': insightGenerationFrequency,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      defaultCurrency: CurrencyCode.values.firstWhere(
        (e) => e.name == json['defaultCurrency'],
        orElse: () => CurrencyCode.SAR,
      ),
      language: LanguageCode.values.firstWhere(
        (e) => e.name == json['language'],
        orElse: () => LanguageCode.ar,
      ),
      themeMode: ThemeMode.values.firstWhere(
        (e) => e.name == json['themeMode'],
        orElse: () => ThemeMode.system,
      ),
      dateFormat: DateFormat.values.firstWhere(
        (e) => e.name == json['dateFormat'],
        orElse: () => DateFormat.ddMMyyyy,
      ),
      use24HourTime: json['use24HourTime'] ?? true,
      textScaleFactor: (json['textScaleFactor'] ?? 1.0).toDouble(),
      requireBiometricAuth: json['requireBiometricAuth'] ?? false,
      requirePinAuth: json['requirePinAuth'] ?? false,
      pinCode: json['pinCode'],
      autoLockMinutes: json['autoLockMinutes'] ?? 5,
      hideBalancesInRecents: json['hideBalancesInRecents'] ?? false,
      allowScreenshots: json['allowScreenshots'] ?? true,
      enableNotifications: json['enableNotifications'] ?? true,
      enableBudgetAlerts: json['enableBudgetAlerts'] ?? true,
      enablePaymentReminders: json['enablePaymentReminders'] ?? true,
      enableGoalReminders: json['enableGoalReminders'] ?? true,
      enableBalanceAlerts: json['enableBalanceAlerts'] ?? true,
      budgetReportFrequency: NotificationFrequency.values.firstWhere(
        (e) => e.name == json['budgetReportFrequency'],
        orElse: () => NotificationFrequency.monthly,
      ),
      reminderLeadDays: json['reminderLeadDays'] ?? 3,
      enableAutoBackup: json['enableAutoBackup'] ?? false,
      enableCloudSync: json['enableCloudSync'] ?? false,
      lastBackupDate: json['lastBackupDate'],
      syncOnWifiOnly: json['syncOnWifiOnly'] ?? true,
      enableReceiptScanning: json['enableReceiptScanning'] ?? true,
      enableVoiceInput: json['enableVoiceInput'] ?? true,
      suggestCategories: json['suggestCategories'] ?? true,
      enableLocationTracking: json['enableLocationTracking'] ?? false,
      defaultTransactionAccount: json['defaultTransactionAccount'] ?? '',
      requireTransactionNotes: json['requireTransactionNotes'] ?? false,
      enableBudgetRollover: json['enableBudgetRollover'] ?? true,
      strictBudgetMode: json['strictBudgetMode'] ?? false,
      budgetWarningPercentage: json['budgetWarningPercentage'] ?? 80,
      includePendingTransactions: json['includePendingTransactions'] ?? true,
      enableGoalProjections: json['enableGoalProjections'] ?? true,
      showGoalProgress: json['showGoalProgress'] ?? true,
      goalReminderFrequency: json['goalReminderFrequency'] ?? 7,
      defaultExportFormat: json['defaultExportFormat'] ?? 'PDF',
      includeDeletedData: json['includeDeletedData'] ?? false,
      passwordProtectExports: json['passwordProtectExports'] ?? true,
      enableAIInsights: json['enableAIInsights'] ?? true,
      shareDataForInsights: json['shareDataForInsights'] ?? false,
      insightGenerationFrequency: json['insightGenerationFrequency'] ?? 7,
    );
  }

  AppSettings copyWith({
    CurrencyCode? defaultCurrency,
    LanguageCode? language,
    ThemeMode? themeMode,
    DateFormat? dateFormat,
    bool? use24HourTime,
    double? textScaleFactor,
    bool? requireBiometricAuth,
    bool? requirePinAuth,
    String? pinCode,
    int? autoLockMinutes,
    bool? hideBalancesInRecents,
    bool? allowScreenshots,
    bool? enableNotifications,
    bool? enableBudgetAlerts,
    bool? enablePaymentReminders,
    bool? enableGoalReminders,
    bool? enableBalanceAlerts,
    NotificationFrequency? budgetReportFrequency,
    int? reminderLeadDays,
    bool? enableAutoBackup,
    bool? enableCloudSync,
    String? lastBackupDate,
    bool? syncOnWifiOnly,
    bool? enableReceiptScanning,
    bool? enableVoiceInput,
    bool? suggestCategories,
    bool? enableLocationTracking,
    String? defaultTransactionAccount,
    bool? requireTransactionNotes,
    bool? enableBudgetRollover,
    bool? strictBudgetMode,
    int? budgetWarningPercentage,
    bool? includePendingTransactions,
    bool? enableGoalProjections,
    bool? showGoalProgress,
    int? goalReminderFrequency,
    String? defaultExportFormat,
    bool? includeDeletedData,
    bool? passwordProtectExports,
    bool? enableAIInsights,
    bool? shareDataForInsights,
    int? insightGenerationFrequency,
  }) {
    return AppSettings(
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
      dateFormat: dateFormat ?? this.dateFormat,
      use24HourTime: use24HourTime ?? this.use24HourTime,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      requireBiometricAuth: requireBiometricAuth ?? this.requireBiometricAuth,
      requirePinAuth: requirePinAuth ?? this.requirePinAuth,
      pinCode: pinCode ?? this.pinCode,
      autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
      hideBalancesInRecents: hideBalancesInRecents ?? this.hideBalancesInRecents,
      allowScreenshots: allowScreenshots ?? this.allowScreenshots,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableBudgetAlerts: enableBudgetAlerts ?? this.enableBudgetAlerts,
      enablePaymentReminders: enablePaymentReminders ?? this.enablePaymentReminders,
      enableGoalReminders: enableGoalReminders ?? this.enableGoalReminders,
      enableBalanceAlerts: enableBalanceAlerts ?? this.enableBalanceAlerts,
      budgetReportFrequency: budgetReportFrequency ?? this.budgetReportFrequency,
      reminderLeadDays: reminderLeadDays ?? this.reminderLeadDays,
      enableAutoBackup: enableAutoBackup ?? this.enableAutoBackup,
      enableCloudSync: enableCloudSync ?? this.enableCloudSync,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
      syncOnWifiOnly: syncOnWifiOnly ?? this.syncOnWifiOnly,
      enableReceiptScanning: enableReceiptScanning ?? this.enableReceiptScanning,
      enableVoiceInput: enableVoiceInput ?? this.enableVoiceInput,
      suggestCategories: suggestCategories ?? this.suggestCategories,
      enableLocationTracking: enableLocationTracking ?? this.enableLocationTracking,
      defaultTransactionAccount: defaultTransactionAccount ?? this.defaultTransactionAccount,
      requireTransactionNotes: requireTransactionNotes ?? this.requireTransactionNotes,
      enableBudgetRollover: enableBudgetRollover ?? this.enableBudgetRollover,
      strictBudgetMode: strictBudgetMode ?? this.strictBudgetMode,
      budgetWarningPercentage: budgetWarningPercentage ?? this.budgetWarningPercentage,
      includePendingTransactions: includePendingTransactions ?? this.includePendingTransactions,
      enableGoalProjections: enableGoalProjections ?? this.enableGoalProjections,
      showGoalProgress: showGoalProgress ?? this.showGoalProgress,
      goalReminderFrequency: goalReminderFrequency ?? this.goalReminderFrequency,
      defaultExportFormat: defaultExportFormat ?? this.defaultExportFormat,
      includeDeletedData: includeDeletedData ?? this.includeDeletedData,
      passwordProtectExports: passwordProtectExports ?? this.passwordProtectExports,
      enableAIInsights: enableAIInsights ?? this.enableAIInsights,
      shareDataForInsights: shareDataForInsights ?? this.shareDataForInsights,
      insightGenerationFrequency: insightGenerationFrequency ?? this.insightGenerationFrequency,
    );
  }
}

class AppSettingsService {
  static final AppSettingsService _instance = AppSettingsService._internal();
  static AppSettingsService get instance => _instance;
  AppSettingsService._internal();

  static const String _settingsKey = 'app_settings';
  static const String _userPreferencesKey = 'user_preferences';

  SharedPreferences? _prefs;
  AppSettings _currentSettings = const AppSettings();

  AppSettings get currentSettings => _currentSettings;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
    print('App Settings service initialized successfully');
  }

  Future<void> _loadSettings() async {
    if (_prefs == null) return;

    final settingsJson = _prefs!.getString(_settingsKey);
    if (settingsJson != null) {
      try {
        final settingsMap = jsonDecode(settingsJson) as Map<String, dynamic>;
        _currentSettings = AppSettings.fromJson(settingsMap);
      } catch (e) {
        print('Error loading settings: $e');
        // Use default settings if loading fails
        _currentSettings = const AppSettings();
        await _saveSettings();
      }
    } else {
      // First time launch - save default settings
      await _saveSettings();
    }
  }

  Future<void> _saveSettings() async {
    if (_prefs == null) return;

    try {
      final settingsJson = jsonEncode(_currentSettings.toJson());
      await _prefs!.setString(_settingsKey, settingsJson);
    } catch (e) {
      print('Error saving settings: $e');
    }
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    _currentSettings = newSettings;
    await _saveSettings();
  }

  // SPECIFIC SETTING METHODS

  Future<void> updateCurrency(CurrencyCode currency) async {
    await updateSettings(_currentSettings.copyWith(defaultCurrency: currency));
  }

  Future<void> updateLanguage(LanguageCode language) async {
    await updateSettings(_currentSettings.copyWith(language: language));
  }

  Future<void> updateTheme(ThemeMode theme) async {
    await updateSettings(_currentSettings.copyWith(themeMode: theme));
  }

  Future<void> updateDateFormat(DateFormat format) async {
    await updateSettings(_currentSettings.copyWith(dateFormat: format));
  }

  Future<void> updateSecuritySettings({
    bool? requireBiometricAuth,
    bool? requirePinAuth,
    String? pinCode,
    int? autoLockMinutes,
  }) async {
    await updateSettings(_currentSettings.copyWith(
      requireBiometricAuth: requireBiometricAuth,
      requirePinAuth: requirePinAuth,
      pinCode: pinCode,
      autoLockMinutes: autoLockMinutes,
    ));
  }

  Future<void> updateNotificationSettings({
    bool? enableNotifications,
    bool? enableBudgetAlerts,
    bool? enablePaymentReminders,
    bool? enableGoalReminders,
    bool? enableBalanceAlerts,
    NotificationFrequency? budgetReportFrequency,
    int? reminderLeadDays,
  }) async {
    await updateSettings(_currentSettings.copyWith(
      enableNotifications: enableNotifications,
      enableBudgetAlerts: enableBudgetAlerts,
      enablePaymentReminders: enablePaymentReminders,
      enableGoalReminders: enableGoalReminders,
      enableBalanceAlerts: enableBalanceAlerts,
      budgetReportFrequency: budgetReportFrequency,
      reminderLeadDays: reminderLeadDays,
    ));
  }

  Future<void> updateBackupSettings({
    bool? enableAutoBackup,
    bool? enableCloudSync,
    bool? syncOnWifiOnly,
  }) async {
    await updateSettings(_currentSettings.copyWith(
      enableAutoBackup: enableAutoBackup,
      enableCloudSync: enableCloudSync,
      syncOnWifiOnly: syncOnWifiOnly,
    ));
  }

  Future<void> recordBackup() async {
    await updateSettings(_currentSettings.copyWith(
      lastBackupDate: DateTime.now().toIso8601String(),
    ));
  }

  // USER PREFERENCES (separate from main settings)

  Future<void> setUserPreference(String key, dynamic value) async {
    if (_prefs == null) return;

    final prefsJson = _prefs!.getString(_userPreferencesKey);
    Map<String, dynamic> prefs = {};
    
    if (prefsJson != null) {
      try {
        prefs = jsonDecode(prefsJson) as Map<String, dynamic>;
      } catch (e) {
        print('Error loading user preferences: $e');
      }
    }

    prefs[key] = value;

    try {
      await _prefs!.setString(_userPreferencesKey, jsonEncode(prefs));
    } catch (e) {
      print('Error saving user preference: $e');
    }
  }

  dynamic getUserPreference(String key, {dynamic defaultValue}) {
    if (_prefs == null) return defaultValue;

    final prefsJson = _prefs!.getString(_userPreferencesKey);
    if (prefsJson == null) return defaultValue;

    try {
      final prefs = jsonDecode(prefsJson) as Map<String, dynamic>;
      return prefs[key] ?? defaultValue;
    } catch (e) {
      print('Error getting user preference: $e');
      return defaultValue;
    }
  }

  Future<void> clearUserPreferences() async {
    if (_prefs == null) return;
    await _prefs!.remove(_userPreferencesKey);
  }

  Future<void> resetToDefaults() async {
    _currentSettings = const AppSettings();
    await _saveSettings();
    await clearUserPreferences();
  }

  // UTILITY METHODS

  String formatCurrency(double amount) {
    final symbols = {
      CurrencyCode.SAR: 'ريال',
      CurrencyCode.USD: '\$',
      CurrencyCode.EUR: '€',
      CurrencyCode.EGP: 'ج.م',
      CurrencyCode.AED: 'درهم',
      CurrencyCode.KWD: 'د.ك',
      CurrencyCode.QAR: 'ر.ق',
      CurrencyCode.BHD: 'د.ب',
      CurrencyCode.OMR: 'ر.ع',
      CurrencyCode.JOD: 'د.أ',
      CurrencyCode.LBP: 'ل.ل',
    };

    final symbol = symbols[_currentSettings.defaultCurrency] ?? _currentSettings.defaultCurrency.name;
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  String formatDate(DateTime date) {
    switch (_currentSettings.dateFormat) {
      case DateFormat.ddMMyyyy:
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      case DateFormat.MMddyyyy:
        return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
      case DateFormat.yyyyMMdd:
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      case DateFormat.ddMMMyyyy:
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
    }
  }

  String formatTime(DateTime time) {
    if (_currentSettings.use24HourTime) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
      final period = time.hour >= 12 ? 'PM' : 'AM';
      return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
    }
  }

  bool isRTL() {
    return _currentSettings.language == LanguageCode.ar;
  }
}