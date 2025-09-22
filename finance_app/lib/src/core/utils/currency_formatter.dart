import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';

class CurrencyFormatter {
  static String format({
    required double amount,
    required String currencyCode,
    String? locale,
    BuildContext? context,
  }) {
    final currentLocale = locale ?? _getLocaleString(context);
    final formatter = NumberFormat.currency(
      locale: currentLocale,
      symbol: _getCurrencySymbol(currencyCode),
      decimalDigits: 2,
    );
    
    return formatter.format(amount);
  }

  static String formatCompact({
    required double amount,
    required String currencyCode,
    String? locale,
    BuildContext? context,
  }) {
    final currentLocale = locale ?? _getLocaleString(context);
    final formatter = NumberFormat.compactCurrency(
      locale: currentLocale,
      symbol: _getCurrencySymbol(currencyCode),
      decimalDigits: amount >= 1000 ? 1 : 2,
    );
    
    return formatter.format(amount);
  }

  static String _getCurrencySymbol(String currencyCode) {
    switch (currencyCode) {
      case 'SAR':
        return 'ريال';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'EGP':
        return 'ج.م';
      case 'AED':
        return 'درهم';
      case 'KWD':
        return 'د.ك';
      case 'QAR':
        return 'ر.ق';
      case 'BHD':
        return 'د.ب';
      case 'OMR':
        return 'ر.ع';
      case 'JOD':
        return 'د.أ';
      case 'LBP':
        return 'ل.ل';
      default:
        return currencyCode;
    }
  }

  static List<String> getSupportedCurrencies() {
    return [
      'SAR', // Saudi Riyal
      'USD', // US Dollar
      'EUR', // Euro
      'EGP', // Egyptian Pound
      'AED', // UAE Dirham
      'KWD', // Kuwaiti Dinar
      'QAR', // Qatari Riyal
      'BHD', // Bahraini Dinar
      'OMR', // Omani Rial
      'JOD', // Jordanian Dinar
      'LBP', // Lebanese Pound
    ];
  }

  // Helper method to get locale string from context
  static String _getLocaleString(BuildContext? context) {
    if (context != null) {
      final locale = context.locale;
      return '${locale.languageCode}_${locale.countryCode}';
    }
    return 'ar_SA'; // Fallback to Arabic Saudi Arabia
  }

  static String getCurrencyName(String currencyCode, String locale) {
    final names = {
      'ar': {
        'SAR': 'الريال السعودي',
        'USD': 'الدولار الأمريكي',
        'EUR': 'اليورو',
        'EGP': 'الجنيه المصري',
        'AED': 'الدرهم الإماراتي',
        'KWD': 'الدينار الكويتي',
        'QAR': 'الريال القطري',
        'BHD': 'الدينار البحريني',
        'OMR': 'الريال العماني',
        'JOD': 'الدينار الأردني',
        'LBP': 'الليرة اللبنانية',
      },
      'en': {
        'SAR': 'Saudi Riyal',
        'USD': 'US Dollar',
        'EUR': 'Euro',
        'EGP': 'Egyptian Pound',
        'AED': 'UAE Dirham',
        'KWD': 'Kuwaiti Dinar',
        'QAR': 'Qatari Riyal',
        'BHD': 'Bahraini Dinar',
        'OMR': 'Omani Rial',
        'JOD': 'Jordanian Dinar',
        'LBP': 'Lebanese Pound',
      },
    };
    
    return names[locale]?[currencyCode] ?? currencyCode;
  }
}