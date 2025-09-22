import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:firebase_messaging/firebase_messaging.dart'; // Temporarily disabled for Replit compatibility
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  // final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance; // Temporarily disabled for Replit compatibility

  Future<void> initialize({bool firebaseAvailable = false}) async {
    // Request notification permissions
    await _requestPermissions();
    
    // Initialize local notifications
    await _initializeLocalNotifications();
    
    // Initialize Firebase messaging only if Firebase is available
    if (firebaseAvailable) {
      try {
        await _initializeFirebaseMessaging();
      } catch (e) {
        print('Firebase messaging initialization failed: $e');
      }
    } else {
      print('Skipping Firebase messaging - Firebase not available');
    }
  }

  Future<void> _requestPermissions() async {
    // Request notification permission
    final status = await Permission.notification.request();
    if (status.isDenied) {
      print('Notification permission denied');
    }

    // Request Firebase messaging permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');
  }

  Future<void> _initializeLocalNotifications() async {
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

  Future<void> _initializeFirebaseMessaging() async {
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(
        message.notification?.title ?? 'Finance App',
        message.notification?.body ?? '',
      );
    });

    // Handle notification opened app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message.data);
    });

    // Get the token for this device
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'finance_app_general',
      'General Notifications',
      channelDescription: 'General notifications for the Finance App',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformChannelSpecifics,
    );
  }

  Future<void> scheduleLoanReminder({
    required String loanId,
    required String lenderName,
    required double amount,
    required DateTime dueDate,
    int daysBefore = 3,
  }) async {
    final reminderDate = dueDate.subtract(Duration(days: daysBefore));
    
    if (reminderDate.isBefore(DateTime.now())) {
      return; // Don't schedule notifications in the past
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'finance_app_loans',
      'Loan Reminders',
      channelDescription: 'Reminders for upcoming loan payments',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.zonedSchedule(
      loanId.hashCode,
      'Loan Payment Reminder',
      'Payment of \$${amount.toStringAsFixed(2)} to $lenderName is due in $daysBefore days',
      _convertToTZDateTime(reminderDate),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'loan_reminder:$loanId',
    );
  }

  Future<void> cancelLoanReminder(String loanId) async {
    await _localNotifications.cancel(loanId.hashCode);
  }

  void _onNotificationTapped(NotificationResponse response) {
    _handleNotificationTap({'payload': response.payload});
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    // Handle navigation based on notification data
    final payload = data['payload'] as String?;
    if (payload != null) {
      if (payload.startsWith('loan_reminder:')) {
        final loanId = payload.split(':')[1];
        // Navigate to loan details
        print('Navigate to loan: $loanId');
      }
    }
  }

  // Helper method to convert DateTime to TZDateTime
  // Note: In a real app, you'd use timezone package
  dynamic _convertToTZDateTime(DateTime dateTime) {
    return dateTime; // Simplified for this example
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
}