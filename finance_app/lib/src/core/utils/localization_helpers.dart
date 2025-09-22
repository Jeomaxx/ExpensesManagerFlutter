import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'currency_formatter.dart';
import 'date_formatter.dart';

/// Helper functions that automatically use the current context locale
class LocalizationHelpers {
  
  /// Format currency using current context locale
  static String formatCurrency(
    BuildContext context,
    double amount,
    String currencyCode,
  ) {
    return CurrencyFormatter.format(
      amount: amount,
      currencyCode: currencyCode,
      context: context,
    );
  }

  /// Format currency in compact form using current context locale  
  static String formatCurrencyCompact(
    BuildContext context,
    double amount,
    String currencyCode,
  ) {
    return CurrencyFormatter.formatCompact(
      amount: amount,
      currencyCode: currencyCode,
      context: context,
    );
  }

  /// Format date using current context locale
  static String formatDate(BuildContext context, DateTime date) {
    return DateFormatter.formatDate(date, context: context);
  }

  /// Format short date using current context locale
  static String formatShortDate(BuildContext context, DateTime date) {
    return DateFormatter.formatShortDate(date, context: context);
  }

  /// Format time using current context locale
  static String formatTime(BuildContext context, DateTime date) {
    return DateFormatter.formatTime(date, context: context);
  }

  /// Format date and time using current context locale
  static String formatDateTime(BuildContext context, DateTime date) {
    return DateFormatter.formatDateTime(date, context: context);
  }

  /// Format relative date using current context locale
  static String formatRelativeDate(BuildContext context, DateTime date) {
    return DateFormatter.formatRelativeDate(date, context: context);
  }

  /// Get month name using current context locale
  static String getMonthName(BuildContext context, int month) {
    return DateFormatter.getMonthName(month, context: context);
  }

  /// Get day name using current context locale
  static String getDayName(BuildContext context, DateTime date) {
    return DateFormatter.getDayName(date, context: context);
  }

  /// Get currency name in current locale
  static String getCurrencyName(BuildContext context, String currencyCode) {
    final locale = context.locale.languageCode;
    return CurrencyFormatter.getCurrencyName(currencyCode, locale);
  }

  /// Check if current locale is RTL
  static bool isRTL(BuildContext context) {
    return context.locale.languageCode == 'ar';
  }

  /// Get text direction for current locale
  static TextDirection getTextDirection(BuildContext context) {
    return isRTL(context) ? TextDirection.rtl : TextDirection.ltr;
  }
}