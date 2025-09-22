import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sqflite/sqflite.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/loan.dart';
import '../models/goal.dart';
import '../services/database_service.dart';

enum ReminderType {
  payment,
  budget,
  goal,
  custom,
  billDue,
  lowBalance,
  overspending,
}

enum AlertSeverity {
  info,
  warning,
  critical,
}

class FinancialReminder {
  final String id;
  final String userId;
  final ReminderType type;
  final String title;
  final String message;
  final DateTime scheduledDate;
  final bool isRecurring;
  final int? recurringInterval; // days
  final bool isActive;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime lastModified;

  const FinancialReminder({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.scheduledDate,
    this.isRecurring = false,
    this.recurringInterval,
    this.isActive = true,
    this.metadata,
    required this.createdAt,
    required this.lastModified,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.name,
      'title': title,
      'message': message,
      'scheduled_date': scheduledDate.toIso8601String(),
      'is_recurring': isRecurring ? 1 : 0,
      'recurring_interval': recurringInterval,
      'is_active': isActive ? 1 : 0,
      'metadata': metadata != null ? jsonEncode(metadata) : null,
      'created_at': createdAt.toIso8601String(),
      'last_modified': lastModified.toIso8601String(),
    };
  }

  factory FinancialReminder.fromJson(Map<String, dynamic> json) {
    return FinancialReminder(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: ReminderType.values.firstWhere((e) => e.name == json['type']),
      title: json['title'] as String,
      message: json['message'] as String,
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      isRecurring: (json['is_recurring'] as int) == 1,
      recurringInterval: json['recurring_interval'] as int?,
      isActive: (json['is_active'] as int) == 1,
      metadata: json['metadata'] != null ? jsonDecode(json['metadata']) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastModified: DateTime.parse(json['last_modified'] as String),
    );
  }
}

class FinancialAlert {
  final String id;
  final String userId;
  final ReminderType type;
  final AlertSeverity severity;
  final String title;
  final String message;
  final DateTime triggeredAt;
  final bool isRead;
  final bool isActionable;
  final String? actionData;
  final DateTime createdAt;

  const FinancialAlert({
    required this.id,
    required this.userId,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.triggeredAt,
    this.isRead = false,
    this.isActionable = false,
    this.actionData,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.name,
      'severity': severity.name,
      'title': title,
      'message': message,
      'triggered_at': triggeredAt.toIso8601String(),
      'is_read': isRead ? 1 : 0,
      'is_actionable': isActionable ? 1 : 0,
      'action_data': actionData,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FinancialAlert.fromJson(Map<String, dynamic> json) {
    return FinancialAlert(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: ReminderType.values.firstWhere((e) => e.name == json['type']),
      severity: AlertSeverity.values.firstWhere((e) => e.name == json['severity']),
      title: json['title'] as String,
      message: json['message'] as String,
      triggeredAt: DateTime.parse(json['triggered_at'] as String),
      isRead: (json['is_read'] as int) == 1,
      isActionable: (json['is_actionable'] as int) == 1,
      actionData: json['action_data'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class RemindersAlertsService {
  static final RemindersAlertsService _instance = RemindersAlertsService._internal();
  static RemindersAlertsService get instance => _instance;
  RemindersAlertsService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<Database> get _db async => await DatabaseService.instance.database;

  Future<void> initialize() async {
    if (_isInitialized) return;

    if (kIsWeb) {
      print('Local notifications not available on web - using web notifications instead');
      _isInitialized = true;
      return;
    }

    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _isInitialized = true;
    print('Reminders and Alerts service initialized successfully');
  }

  void _onNotificationTap(NotificationResponse details) {
    print('Notification tapped: ${details.payload}');
    // Handle notification tap - navigate to relevant screen
  }

  // REMINDER MANAGEMENT
  
  Future<void> createReminder(FinancialReminder reminder) async {
    final db = await _db;
    
    await db.insert('financial_reminders', reminder.toJson());
    
    // Schedule local notification
    await _scheduleNotification(reminder);
  }

  Future<void> updateReminder(FinancialReminder reminder) async {
    final db = await _db;
    
    await db.update(
      'financial_reminders',
      reminder.toJson(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
    
    // Cancel existing notification and reschedule
    await _notifications.cancel(reminder.id.hashCode);
    await _scheduleNotification(reminder);
  }

  Future<void> deleteReminder(String reminderId) async {
    final db = await _db;
    
    await db.delete(
      'financial_reminders',
      where: 'id = ?',
      whereArgs: [reminderId],
    );
    
    // Cancel notification
    await _notifications.cancel(reminderId.hashCode);
  }

  Future<List<FinancialReminder>> getUserReminders(String userId) async {
    final db = await _db;
    
    final maps = await db.query(
      'financial_reminders',
      where: 'user_id = ? AND is_active = 1',
      whereArgs: [userId],
      orderBy: 'scheduled_date ASC',
    );
    
    return maps.map((map) => FinancialReminder.fromJson(map)).toList();
  }

  Future<List<FinancialReminder>> getUpcomingReminders(String userId, {int days = 7}) async {
    final db = await _db;
    final endDate = DateTime.now().add(Duration(days: days));
    
    final maps = await db.query(
      'financial_reminders',
      where: 'user_id = ? AND is_active = 1 AND scheduled_date <= ?',
      whereArgs: [userId, endDate.toIso8601String()],
      orderBy: 'scheduled_date ASC',
    );
    
    return maps.map((map) => FinancialReminder.fromJson(map)).toList();
  }

  Future<void> _scheduleNotification(FinancialReminder reminder) async {
    if (!reminder.isActive || reminder.scheduledDate.isBefore(DateTime.now())) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'financial_reminders',
      'Financial Reminders',
      channelDescription: 'Reminders for payments, budgets, and financial goals',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails();
    const notificationDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.zonedSchedule(
      reminder.id.hashCode,
      reminder.title,
      reminder.message,
      _convertToTZDateTime(reminder.scheduledDate),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: jsonEncode(reminder.toJson()),
    );

    // Schedule recurring reminders
    if (reminder.isRecurring && reminder.recurringInterval != null) {
      await _scheduleRecurringReminder(reminder);
    }
  }

  Future<void> _scheduleRecurringReminder(FinancialReminder reminder) async {
    if (reminder.recurringInterval == null) return;
    
    var nextDate = reminder.scheduledDate.add(Duration(days: reminder.recurringInterval!));
    int count = 0;
    
    // Schedule next 10 occurrences
    while (count < 10 && nextDate.isBefore(DateTime.now().add(const Duration(days: 365)))) {
      final recurringReminder = FinancialReminder(
        id: '${reminder.id}_recurring_$count',
        userId: reminder.userId,
        type: reminder.type,
        title: reminder.title,
        message: reminder.message,
        scheduledDate: nextDate,
        isRecurring: false, // Don't make the recurring ones recurring again
        isActive: reminder.isActive,
        metadata: reminder.metadata,
        createdAt: reminder.createdAt,
        lastModified: DateTime.now(),
      );
      
      await _scheduleNotification(recurringReminder);
      
      nextDate = nextDate.add(Duration(days: reminder.recurringInterval!));
      count++;
    }
  }

  // SMART ALERT GENERATION
  
  Future<void> generateSmartAlerts(String userId) async {
    // This would be called periodically to check for conditions that warrant alerts
    await _checkBudgetAlerts(userId);
    await _checkPaymentAlerts(userId);
    await _checkGoalAlerts(userId);
    await _checkBalanceAlerts(userId);
  }

  Future<void> _checkBudgetAlerts(String userId) async {
    // Check for budget overspending
    // This would require access to budget and transaction repositories
    // Implementation would check spending vs budget and create alerts
  }

  Future<void> _checkPaymentAlerts(String userId) async {
    // Check for upcoming payments
    // This would require access to loan repository
    // Implementation would check for due payments and create alerts
  }

  Future<void> _checkGoalAlerts(String userId) async {
    // Check for goal milestones or deadline alerts
    // This would require access to goal repository
    // Implementation would check goal progress and deadlines
  }

  Future<void> _checkBalanceAlerts(String userId) async {
    // Check for low account balances
    // This would require access to account repository
    // Implementation would check balances against thresholds
  }

  // ALERT MANAGEMENT
  
  Future<void> createAlert(FinancialAlert alert) async {
    final db = await _db;
    
    await db.insert('financial_alerts', alert.toJson());
    
    // Show immediate notification for critical alerts
    if (alert.severity == AlertSeverity.critical) {
      await _showImmediateNotification(alert);
    }
  }

  Future<List<FinancialAlert>> getUserAlerts(String userId, {bool? isRead}) async {
    final db = await _db;
    
    String whereClause = 'user_id = ?';
    List<dynamic> whereArgs = [userId];
    
    if (isRead != null) {
      whereClause += ' AND is_read = ?';
      whereArgs.add(isRead ? 1 : 0);
    }
    
    final maps = await db.query(
      'financial_alerts',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'triggered_at DESC',
    );
    
    return maps.map((map) => FinancialAlert.fromJson(map)).toList();
  }

  Future<void> markAlertAsRead(String alertId) async {
    final db = await _db;
    
    await db.update(
      'financial_alerts',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [alertId],
    );
  }

  Future<int> getUnreadAlertCount(String userId) async {
    final db = await _db;
    
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM financial_alerts WHERE user_id = ? AND is_read = 0',
      [userId],
    );
    
    return result.first['count'] as int;
  }

  Future<void> _showImmediateNotification(FinancialAlert alert) async {
    const androidDetails = AndroidNotificationDetails(
      'financial_alerts',
      'Financial Alerts',
      channelDescription: 'Important financial alerts and warnings',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    
    const iosDetails = DarwinNotificationDetails();
    const notificationDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.show(
      alert.id.hashCode,
      alert.title,
      alert.message,
      notificationDetails,
      payload: jsonEncode(alert.toJson()),
    );
  }

  // PREDEFINED REMINDER TEMPLATES
  
  FinancialReminder createBillReminder({
    required String userId,
    required String billName,
    required DateTime dueDate,
    required double amount,
    bool isRecurring = true,
    int recurringInterval = 30,
  }) {
    return FinancialReminder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      type: ReminderType.billDue,
      title: 'Bill Due: $billName',
      message: 'Your $billName bill of \$${amount.toStringAsFixed(2)} is due ${_formatDueDate(dueDate)}',
      scheduledDate: dueDate.subtract(const Duration(days: 3)), // Remind 3 days before
      isRecurring: isRecurring,
      recurringInterval: recurringInterval,
      metadata: {
        'billName': billName,
        'amount': amount,
        'dueDate': dueDate.toIso8601String(),
      },
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
    );
  }

  FinancialReminder createBudgetCheckReminder({
    required String userId,
    required String categoryName,
    required DateTime scheduledDate,
  }) {
    return FinancialReminder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      type: ReminderType.budget,
      title: 'Budget Check: $categoryName',
      message: 'Time to review your $categoryName spending this month',
      scheduledDate: scheduledDate,
      isRecurring: true,
      recurringInterval: 30,
      metadata: {
        'categoryName': categoryName,
      },
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
    );
  }

  FinancialReminder createGoalMilestoneReminder({
    required String userId,
    required String goalName,
    required DateTime targetDate,
    required double currentAmount,
    required double targetAmount,
  }) {
    final percentage = (currentAmount / targetAmount) * 100;
    
    return FinancialReminder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      type: ReminderType.goal,
      title: 'Goal Progress: $goalName',
      message: 'You\'re ${percentage.toStringAsFixed(1)}% towards your $goalName goal. Keep it up!',
      scheduledDate: DateTime.now().add(const Duration(days: 7)),
      isRecurring: true,
      recurringInterval: 14, // Every 2 weeks
      metadata: {
        'goalName': goalName,
        'currentAmount': currentAmount,
        'targetAmount': targetAmount,
        'targetDate': targetDate.toIso8601String(),
      },
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
    );
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) return 'today';
    if (difference == 1) return 'tomorrow';
    if (difference < 7) return 'in $difference days';
    return 'on ${date.day}/${date.month}/${date.year}';
  }

  // Helper method to convert DateTime to TZDateTime (simplified)
  dynamic _convertToTZDateTime(DateTime dateTime) {
    // This is a simplified version. In a real app, you'd use the timezone package
    return dateTime;
  }
}