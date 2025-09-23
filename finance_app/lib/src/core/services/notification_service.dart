import 'package:flutter/foundation.dart';
import 'notifications/notifications_client.dart';
import 'notifications/notifications_client_web.dart';
import 'notifications/notifications_client_mobile.dart';

NotificationsClient _createNotificationsClient() {
  if (kIsWeb) {
    return NotificationsClientWeb();
  } else {
    return NotificationsClientMobile();
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  NotificationService._internal();

  late final NotificationsClient _client = _createNotificationsClient();

  Future<void> initialize({bool firebaseAvailable = false}) async {
    try {
      await _client.requestPermissions();
      await _client.initialize();
      print('Notification service initialized successfully');
    } catch (e) {
      print('Failed to initialize notification service: $e');
    }
  }

  Future<void> showTransactionReminder({
    required String title,
    required String body,
    DateTime? scheduledDate,
  }) async {
    try {
      await _client.showTransactionReminder(
        title: title,
        body: body,
        scheduledDate: scheduledDate,
      );
    } catch (e) {
      print('Failed to show transaction reminder: $e');
    }
  }

  Future<void> showBudgetAlert({
    required String title,
    required String body,
  }) async {
    try {
      await _client.showBudgetAlert(
        title: title,
        body: body,
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
    try {
      await _client.showGoalReminder(
        title: title,
        body: body,
        scheduledDate: scheduledDate,
      );
    } catch (e) {
      print('Failed to show goal reminder: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _client.cancelAllNotifications();
    } catch (e) {
      print('Failed to cancel all notifications: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _client.cancelNotification(id);
    } catch (e) {
      print('Failed to cancel notification $id: $e');
    }
  }
}