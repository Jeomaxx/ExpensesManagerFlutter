import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';

class DateFormatter {
  static String formatDate(DateTime date, {String? locale, BuildContext? context}) {
    final currentLocale = locale ?? _getLocaleFromContext(context);
    
    if (currentLocale == 'ar') {
      // Arabic date format
      return DateFormat('d MMMM yyyy', 'ar').format(date);
    } else {
      // English date format
      return DateFormat('MMM d, yyyy', 'en').format(date);
    }
  }

  static String formatShortDate(DateTime date, {String? locale, BuildContext? context}) {
    final currentLocale = locale ?? _getLocaleFromContext(context);
    
    if (currentLocale == 'ar') {
      return DateFormat('d/M/yyyy', 'ar').format(date);
    } else {
      return DateFormat('M/d/yyyy', 'en').format(date);
    }
  }

  static String formatTime(DateTime date, {String? locale, BuildContext? context}) {
    final currentLocale = locale ?? _getLocaleFromContext(context);
    
    if (currentLocale == 'ar') {
      return DateFormat('h:mm a', 'ar').format(date);
    } else {
      return DateFormat('h:mm a', 'en').format(date);
    }
  }

  static String formatDateTime(DateTime date, {String? locale, BuildContext? context}) {
    return '${formatDate(date, locale: locale, context: context)} ${formatTime(date, locale: locale, context: context)}';
  }

  static String formatRelativeDate(DateTime date, {String? locale, BuildContext? context}) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'today'.tr();
    } else if (difference.inDays == 1) {
      return 'yesterday'.tr();
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${'days_ago'.tr()}';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? 'week_ago'.tr() : '$weeks ${'weeks_ago'.tr()}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? 'month_ago'.tr() : '$months ${'months_ago'.tr()}';
    } else {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? 'year_ago'.tr() : '$years ${'years_ago'.tr()}';
    }
  }

  static String getMonthName(int month, {String? locale, BuildContext? context}) {
    final currentLocale = locale ?? _getLocaleFromContext(context);
    
    final date = DateTime(2024, month);
    if (currentLocale == 'ar') {
      return DateFormat('MMMM', 'ar').format(date);
    } else {
      return DateFormat('MMMM', 'en').format(date);
    }
  }

  static String getDayName(DateTime date, {String? locale, BuildContext? context}) {
    final currentLocale = locale ?? _getLocaleFromContext(context);
    
    if (currentLocale == 'ar') {
      return DateFormat('EEEE', 'ar').format(date);
    } else {
      return DateFormat('EEEE', 'en').format(date);
    }
  }

  // Helper method to get locale from context
  static String _getLocaleFromContext(BuildContext? context) {
    if (context != null) {
      return context.locale.languageCode;
    }
    return 'ar'; // Fallback to Arabic if no context available
  }
}