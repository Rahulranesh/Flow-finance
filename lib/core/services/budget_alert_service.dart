import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'currency_formatter.dart';
import '../../data/models/transaction_model.dart';

/// Service for budget alerts and notifications
class BudgetAlertService {
  static final BudgetAlertService _instance = BudgetAlertService._internal();
  factory BudgetAlertService() => _instance;
  BudgetAlertService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Initialize budget alerts
  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    _isInitialized = true;
  }

  /// Check budget and send alerts if needed
  Future<void> checkBudgetAlerts({
    required Budget budget,
    required List<Transaction> transactions,
    required String categoryName,
  }) async {
    final spent = _calculateSpent(budget, transactions);
    final percentage = (spent / budget.limit) * 100;

    // Alert at 80% threshold
    if (percentage >= 80 && percentage < 100) {
      await _sendAlert(
        title: '⚠️ Budget Alert: $categoryName',
        body:
            'You\'ve spent ${percentage.toStringAsFixed(0)}% of your $categoryName budget',
        notificationId: budget.id.hashCode,
      );
    }

    // Alert when exceeded
    if (percentage >= 100) {
      await _sendAlert(
        title: '🚨 Budget Exceeded: $categoryName',
        body:
            'You\'ve exceeded your $categoryName budget by ${CurrencyFormatter.format(spent - budget.limit)}',
        notificationId: budget.id.hashCode + 1000,
        priority: Priority.high,
      );
    }

    // Alert at 50% threshold
    if (percentage >= 50 && percentage < 60) {
      await _sendAlert(
        title: '💡 Budget Update: $categoryName',
        body: 'You\'ve used half of your $categoryName budget',
        notificationId: budget.id.hashCode + 2000,
        priority: Priority.low,
      );
    }
  }

  /// Calculate spent amount for budget
  double _calculateSpent(Budget budget, List<Transaction> transactions) {
    final endDate =
        budget.endDate ?? DateTime.now().add(const Duration(days: 365));

    return transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.isAfter(budget.startDate) &&
            t.date.isBefore(endDate))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Send notification alert
  Future<void> _sendAlert({
    required String title,
    required String body,
    required int notificationId,
    Priority priority = Priority.defaultPriority,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'budget_alerts',
      'Budget Alerts',
      channelDescription:
          'Notifications for budget thresholds and overspending',
      importance: priority == Priority.high
          ? Importance.high
          : Importance.defaultImportance,
      priority: priority,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      notificationId,
      title,
      body,
      details,
    );
  }

  /// Send daily spending summary
  Future<void> sendDailySummary({
    required double totalSpent,
    required double totalIncome,
    required int transactionCount,
  }) async {
    final balance = totalIncome - totalSpent;
    final emoji = balance >= 0 ? '✅' : '⚠️';

    await _sendAlert(
      title: '$emoji Daily Summary',
      body:
          'Today: $transactionCount transactions, Spent: ${CurrencyFormatter.format(totalSpent)}, Balance: ${CurrencyFormatter.format(balance)}',
      notificationId: DateTime.now().day,
    );
  }

  /// Send weekly spending report
  Future<void> sendWeeklyReport({
    required double totalSpent,
    required double totalIncome,
    required String topCategory,
    required double topCategoryAmount,
  }) async {
    await _sendAlert(
      title: '📊 Weekly Report',
      body:
          'Spent: ${CurrencyFormatter.format(totalSpent)} | Income: ${CurrencyFormatter.format(totalIncome)} | Top: $topCategory (${CurrencyFormatter.format(topCategoryAmount)})',
      notificationId: 9999,
    );
  }

  /// Send goal progress notification
  Future<void> sendGoalProgress({
    required String goalName,
    required double progress,
    required double remaining,
  }) async {
    await _sendAlert(
      title: '🎯 Goal Progress: $goalName',
      body:
          '${progress.toStringAsFixed(0)}% complete! ${CurrencyFormatter.format(remaining)} remaining',
      notificationId: goalName.hashCode,
    );
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Cancel specific notification
  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }
}
