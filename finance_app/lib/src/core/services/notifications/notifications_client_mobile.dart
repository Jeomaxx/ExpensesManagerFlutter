import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'notifications_client.dart';

class NotificationsClientMobile implements NotificationsClient {
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  @override
  Future<void> requestPermissions() async {
    final status = await Permission.notification.request();
    if (status.isDenied) {
      print('Notification permission denied');
    } else {
      print('Notification permission granted');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
  }

  @override
  Future<void> showTransactionReminder({
    required String title,
    required String body,
    DateTime? scheduledDate,
  }) async {
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(
      android: AndroidNotificationDetails(
        'transaction_reminders',
        'Transaction Reminders',
        channelDescription: 'Reminders for recording transactions',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  @override
  Future<void> showBudgetAlert({
    required String title,
    required String body,
  }) async {
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(
      android: AndroidNotificationDetails(
        'budget_alerts',
        'Budget Alerts',
        channelDescription: 'Alerts for budget limits and spending',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  @override
  Future<void> showGoalReminder({
    required String title,
    required String body,
    DateTime? scheduledDate,
  }) async {
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(
      android: AndroidNotificationDetails(
        'goal_reminders',
        'Goal Reminders',
        channelDescription: 'Reminders for financial goals',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  @override
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  @override
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }
}