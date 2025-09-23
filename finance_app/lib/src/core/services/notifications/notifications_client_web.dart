import 'notifications_client.dart';

class NotificationsClientWeb implements NotificationsClient {
  @override
  Future<void> initialize() async {
    print('Notification service initialized (Web platform - notifications disabled)');
  }

  @override
  Future<void> requestPermissions() async {
    print('Notification permissions requested (Web platform - no-op)');
  }

  @override
  Future<void> showTransactionReminder({
    required String title,
    required String body,
    DateTime? scheduledDate,
  }) async {
    print('Transaction reminder: $title - $body (Web platform)');
  }

  @override
  Future<void> showBudgetAlert({
    required String title,
    required String body,
  }) async {
    print('Budget alert: $title - $body (Web platform)');
  }

  @override
  Future<void> showGoalReminder({
    required String title,
    required String body,
    DateTime? scheduledDate,
  }) async {
    print('Goal reminder: $title - $body (Web platform)');
  }

  @override
  Future<void> cancelAllNotifications() async {
    print('Cancel all notifications (Web platform - no-op)');
  }

  @override
  Future<void> cancelNotification(int id) async {
    print('Cancel notification $id (Web platform - no-op)');
  }
}