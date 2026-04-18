import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Service for managing local notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz_data.initializeTimeZones();

    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    _isInitialized = true;
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    final result = await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    return result ?? true;
  }

  /// Show immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'flow_finance_channel',
      'Flow Finance',
      channelDescription: 'Notifications for Flow Finance app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  /// Schedule a notification
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'flow_finance_scheduled',
      'Scheduled Notifications',
      channelDescription: 'Scheduled notifications for reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Schedule daily reminder
  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'flow_finance_daily',
      'Daily Reminders',
      channelDescription: 'Daily reminder notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedule weekly reminder
  Future<void> scheduleWeeklyReminder({
    required int id,
    required String title,
    required String body,
    required int day, // 1 = Monday, 7 = Sunday
    required int hour,
    required int minute,
  }) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'flow_finance_weekly',
      'Weekly Reminders',
      channelDescription: 'Weekly reminder notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfDayAndTime(day, hour, minute),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Show budget alert notification
  Future<void> showBudgetAlert({
    required String category,
    required double percentage,
  }) async {
    final title = percentage >= 100
        ? 'Budget Exceeded!'
        : percentage >= 80
            ? 'Budget Warning'
            : 'Budget Alert';

    final body = percentage >= 100
        ? 'You\'ve exceeded your budget for $category'
        : 'You\'ve used ${percentage.toStringAsFixed(0)}% of your $category budget';

    await showNotification(
      id: _budgetAlertId(category),
      title: title,
      body: body,
      payload: 'budget:$category',
    );
  }

  /// Schedule bill reminder
  Future<void> scheduleBillReminder({
    required int id,
    required String billName,
    required double amount,
    required DateTime dueDate,
  }) async {
    // Schedule 3 days before
    final reminderDate = dueDate.subtract(const Duration(days: 3));

    if (reminderDate.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: id,
        title: 'Upcoming Bill: $billName',
        body: '\$${amount.toStringAsFixed(2)} due on ${dueDate.toNotificationShortDate()}',
        scheduledDate: reminderDate,
        payload: 'bill:$id',
      );
    }

    // Schedule on due date
    await scheduleNotification(
      id: id + 1000,
      title: 'Bill Due Today: $billName',
      body: '\$${amount.toStringAsFixed(2)} is due today',
      scheduledDate: dueDate,
      payload: 'bill:$id',
    );
  }

  /// Schedule daily budget check reminder
  Future<void> scheduleDailyBudgetCheck() async {
    await scheduleDailyReminder(
      id: 100,
      title: 'Daily Budget Check',
      body: 'Don\'t forget to log your expenses today!',
      hour: 20,
      minute: 0,
    );
  }

  /// Schedule weekly summary
  Future<void> scheduleWeeklySummary() async {
    await scheduleWeeklyReminder(
      id: 200,
      title: 'Weekly Financial Summary',
      body: 'Review your spending for this week',
      day: 7, // Sunday
      hour: 10,
      minute: 0,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  tz.TZDateTime _nextInstanceOfDayAndTime(int day, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    // Adjust to the correct day of week
    while (scheduled.weekday != day) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }

    return scheduled;
  }

  int _budgetAlertId(String category) {
    return category.hashCode.abs() % 10000 + 10000;
  }

  void _onNotificationResponse(NotificationResponse response) {
    // Handle notification tap
    final payload = response.payload;
    if (payload != null) {
      // Navigate based on payload
      // This will be handled by the app navigator
    }
  }
}

/// Extension for date formatting - notification specific
extension NotificationDateFormatting on DateTime {
  String toNotificationShortDate() {
    return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }
}
