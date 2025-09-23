import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

// Conditional imports for platform-specific plugins
import 'package:flutter_local_notifications/flutter_local_notifications.dart' if (dart.library.js) 'package:flutter/foundation.dart' as notifications;
import 'package:permission_handler/permission_handler.dart' if (dart.library.js) 'package:flutter/foundation.dart' as permissions;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  NotificationService._internal();

  // Only initialize on mobile platforms
  final notifications.FlutterLocalNotificationsPlugin? _localNotifications = 
      kIsWeb ? null : notifications.FlutterLocalNotificationsPlugin();

  Future<void> initialize({bool firebaseAvailable = false}) async {
    if (kIsWeb) {
      print('Notification service initialized (Web platform - notifications disabled)');
      return;
    }
    
    try {
      // Request notification permissions
      await _requestPermissions();
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      print('Notification service initialized (Firebase disabled for Replit compatibility)');
    } catch (e) {
      print('Failed to initialize notification service: $e');
    }
  }

  Future<void> _requestPermissions() async {
    if (kIsWeb) return;
    
    try {
      // Request notification permission
      final status = await permissions.Permission.notification.request();
      if (status.isDenied) {
        print('Notification permission denied');
      } else {
        print('Notification permission granted');
      }
    } catch (e) {
      print('Failed to request permissions: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    if (kIsWeb || _localNotifications == null) return;
    
    try {
      const initializationSettingsAndroid =
          notifications.AndroidInitializationSettings('@mipmap/ic_launcher');

      const initializationSettingsIOS =
          notifications.DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );

      const initializationSettings =
          notifications.InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _localNotifications!.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
    } catch (e) {
      print('Failed to initialize local notifications: $e');
    }
  }

  void _onNotificationTapped(notifications.NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
  }

  Future<void> showTransactionReminder({
    required String title,
    required String body,
    DateTime? scheduledDate,
  }) async {
    if (kIsWeb || _localNotifications == null) {
      print('Transaction reminder: $title - $body (Web platform)');
      return;
    }
    
    try {
      const platformChannelSpecifics =
          notifications.NotificationDetails(
        android: notifications.AndroidNotificationDetails(
          'transaction_reminders',
          'Transaction Reminders',
          channelDescription: 'Reminders for recording transactions',
          importance: notifications.Importance.max,
          priority: notifications.Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: notifications.DarwinNotificationDetails(),
      );

      await _localNotifications!.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        platformChannelSpecifics,
      );
    } catch (e) {
      print('Failed to show transaction reminder: $e');
    }
  }

  Future<void> showBudgetAlert({
    required String title,
    required String body,
  }) async {
    if (kIsWeb || _localNotifications == null) {
      print('Budget alert: $title - $body (Web platform)');
      return;
    }
    
    try {
      const platformChannelSpecifics =
          notifications.NotificationDetails(
        android: notifications.AndroidNotificationDetails(
          'budget_alerts',
          'Budget Alerts',
          channelDescription: 'Alerts for budget limits and spending',
          importance: notifications.Importance.max,
          priority: notifications.Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: notifications.DarwinNotificationDetails(),
      );

      await _localNotifications!.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        platformChannelSpecifics,
      );
    } catch (e) {
      print('Failed to show budget alert: $e');
    }
  }

  Future<void> showGoalReminder({
    required String title,
    required String body,
    DateTime? scheduledDate,
  }) async {
    if (kIsWeb || _localNotifications == null) {
      print('Goal reminder: $title - $body (Web platform)');
      return;
    }
    
    try {
      const platformChannelSpecifics =
          notifications.NotificationDetails(
        android: notifications.AndroidNotificationDetails(
          'goal_reminders',
          'Goal Reminders',
          channelDescription: 'Reminders for financial goals',
          importance: notifications.Importance.max,
          priority: notifications.Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: notifications.DarwinNotificationDetails(),
      );

      await _localNotifications!.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        platformChannelSpecifics,
      );
    } catch (e) {
      print('Failed to show goal reminder: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    if (kIsWeb || _localNotifications == null) return;
    
    try {
      await _localNotifications!.cancelAll();
    } catch (e) {
      print('Failed to cancel all notifications: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    if (kIsWeb || _localNotifications == null) return;
    
    try {
      await _localNotifications!.cancel(id);
    } catch (e) {
      print('Failed to cancel notification $id: $e');
    }
  }
}