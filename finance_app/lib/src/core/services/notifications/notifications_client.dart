abstract class NotificationsClient {
  Future<void> initialize();
  Future<void> requestPermissions();
  
  Future<void> showTransactionReminder({
    required String title,
    required String body,
    DateTime? scheduledDate,
  });
  
  Future<void> showBudgetAlert({
    required String title,
    required String body,
  });
  
  Future<void> showGoalReminder({
    required String title,
    required String body,
    DateTime? scheduledDate,
  });
  
  Future<void> cancelAllNotifications();
  Future<void> cancelNotification(int id);
}