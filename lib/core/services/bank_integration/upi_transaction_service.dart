import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/upi_transaction.dart';
import 'upi_sms_parser.dart';

/// Service for tracking UPI transactions via SMS and notifications
class UPITransactionService extends ChangeNotifier {
  static final UPITransactionService _instance = UPITransactionService._internal();
  factory UPITransactionService() => _instance;
  UPITransactionService._internal();

  final UPISmsParser _smsParser = UPISmsParser();
  final List<UPITransaction> _transactions = [];
  final List<UPITransactionListener> _listeners = [];
  
  bool _isSmsPermissionGranted = false;
  bool _isNotificationPermissionGranted = false;
  bool _isAutoSyncEnabled = true;
  
  // Getters
  List<UPITransaction> get transactions => List.unmodifiable(_transactions);
  bool get isSmsPermissionGranted => _isSmsPermissionGranted;
  bool get isNotificationPermissionGranted => _isNotificationPermissionGranted;
  bool get isAutoSyncEnabled => _isAutoSyncEnabled;
  
  // Stream controllers
  final _transactionStreamController = StreamController<UPITransaction>.broadcast();
  Stream<UPITransaction> get transactionStream => _transactionStreamController.stream;

  /// Initialize the service
  Future<void> initialize() async {
    // Load saved transactions
    await _loadTransactions();
    
    // Check permissions
    await checkPermissions();
    
    // Start listening if permissions granted
    if (_isSmsPermissionGranted || _isNotificationPermissionGranted) {
      startListening();
    }
  }

  /// Check SMS and notification permissions
  Future<void> checkPermissions() async {
    // Note: Actual permission checks would use permission_handler
    // This is a placeholder for the real implementation
    _isSmsPermissionGranted = false;
    _isNotificationPermissionGranted = false;
    notifyListeners();
  }

  /// Request SMS permission
  Future<bool> requestSmsPermission() async {
    // Implementation would use permission_handler
    // For now, simulate success
    _isSmsPermissionGranted = true;
    notifyListeners();
    return true;
  }

  /// Request notification permission
  Future<bool> requestNotificationPermission() async {
    // Implementation would use permission_handler
    _isNotificationPermissionGranted = true;
    notifyListeners();
    return true;
  }

  /// Start listening for UPI transactions
  void startListening() {
    if (!_isSmsPermissionGranted && !_isNotificationPermissionGranted) {
      return;
    }
    
    // In real implementation:
    // - Set up SMS listener using telephony plugin
    // - Set up notification listener
    // - Register broadcast receivers on Android
    
    debugPrint('UPI Transaction Service: Started listening');
  }

  /// Stop listening
  void stopListening() {
    // Unregister listeners
    debugPrint('UPI Transaction Service: Stopped listening');
  }

  /// Process incoming SMS
  void processIncomingSms(String sender, String body, DateTime timestamp) {
    if (!_smsParser.isUpiTransaction(body)) {
      return;
    }

    final transaction = _smsParser.parseSms(body, sender);
    if (transaction != null) {
      _addTransaction(transaction);
    }
  }

  /// Process notification from UPI apps
  void processNotification(String packageName, String title, String content) {
    // Map package names to source apps
    final sourceApp = _getSourceAppFromPackage(packageName);

    // Try to extract transaction details from notification
    final amount = _smsParser.extractAmount(content);
    final upiId = _smsParser.extractUpiId(content);
    
    if (amount != null && upiId != null) {
      final isDebit = content.toLowerCase().contains('sent') ||
                      content.toLowerCase().contains('paid') ||
                      content.toLowerCase().contains('debited');
      
      final transaction = UPITransaction.create(
        utrNumber: _generateTempUtr(),
        upiId: upiId,
        payerUpiId: isDebit ? null : upiId,
        payeeUpiId: isDebit ? upiId : null,
        amount: amount,
        type: isDebit ? UPITransactionType.debit : UPITransactionType.credit,
        timestamp: DateTime.now(),
        description: title,
        sourceApp: sourceApp,
        rawSms: content,
        senderId: packageName,
      );
      
      _addTransaction(transaction);
    }
  }

  /// Scan historical SMS for UPI transactions
  Future<List<UPITransaction>> scanHistoricalSms({int daysBack = 30}) async {
    if (!_isSmsPermissionGranted) {
      throw Exception('SMS permission not granted');
    }

    final transactions = <UPITransaction>[];

    // In real implementation:
    // - Query SMS inbox using telephony plugin
    // - Filter by date and sender
    // - Parse each message
    
    // Simulate scanning
    debugPrint('Scanning SMS from last $daysBack days...');
    
    return transactions;
  }

  /// Import transactions from SMS backup
  Future<List<UPITransaction>> importFromSmsBackup(String backupData) async {
    final transactions = <UPITransaction>[];
    
    try {
      // Parse backup format (JSON/XML)
      final messages = _parseSmsBackup(backupData);
      
      for (final message in messages) {
        final transaction = _smsParser.parseSms(message.body, message.sender);
        if (transaction != null) {
          transactions.add(transaction);
        }
      }
      
      // Add all transactions
      for (final tx in transactions) {
        _addTransaction(tx);
      }
    } catch (e) {
      debugPrint('Error importing SMS backup: $e');
    }
    
    return transactions;
  }

  /// Add a transaction
  void _addTransaction(UPITransaction transaction) {
    // Check for duplicates
    if (_isDuplicate(transaction)) {
      return;
    }

    _transactions.add(transaction);
    _transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    // Notify listeners
    _transactionStreamController.add(transaction);
    for (final listener in _listeners) {
      listener.onTransactionReceived(transaction);
    }
    
    // Auto-sync if enabled
    if (_isAutoSyncEnabled) {
      _autoSyncTransaction(transaction);
    }
    
    notifyListeners();
    _saveTransactions();
  }

  /// Check if transaction is a duplicate
  bool _isDuplicate(UPITransaction transaction) {
    return _transactions.any((tx) =>
      tx.utrNumber == transaction.utrNumber ||
      (tx.amount == transaction.amount &&
       tx.upiId == transaction.upiId &&
       tx.timestamp.difference(transaction.timestamp).inMinutes.abs() < 5)
    );
  }

  /// Remove a transaction
  void removeTransaction(String id) {
    _transactions.removeWhere((tx) => tx.id == id);
    notifyListeners();
    _saveTransactions();
  }

  /// Update transaction
  void updateTransaction(UPITransaction transaction) {
    final index = _transactions.indexWhere((tx) => tx.id == transaction.id);
    if (index >= 0) {
      _transactions[index] = transaction;
      notifyListeners();
      _saveTransactions();
    }
  }

  /// Link transaction to app transaction
  void linkToAppTransaction(String upiTransactionId, String appTransactionId) {
    final index = _transactions.indexWhere((tx) => tx.id == upiTransactionId);
    if (index >= 0) {
      _transactions[index] = _transactions[index].markSynced(appTransactionId);
      notifyListeners();
      _saveTransactions();
    }
  }

  /// Get transactions by type
  List<UPITransaction> getTransactionsByType(UPITransactionType type) {
    return _transactions.where((tx) => tx.type == type).toList();
  }

  /// Get transactions by source app
  List<UPITransaction> getTransactionsBySource(String sourceApp) {
    return _transactions.where((tx) => tx.sourceApp == sourceApp).toList();
  }

  /// Get transactions by date range
  List<UPITransaction> getTransactionsByDateRange(DateTime start, DateTime end) {
    return _transactions.where((tx) =>
      tx.timestamp.isAfter(start) && tx.timestamp.isBefore(end)
    ).toList();
  }

  /// Get pending transactions (not synced)
  List<UPITransaction> getPendingTransactions() {
    return _transactions.where((tx) => tx.syncStatus == SyncStatus.pending).toList();
  }

  /// Get transaction summary
  UPITransactionSummary getSummary({DateTime? startDate, DateTime? endDate}) {
    final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now();
    
    final filtered = getTransactionsByDateRange(start, end);
    return UPITransactionSummary.fromTransactions(filtered, periodStart: start, periodEnd: end);
  }

  /// Get monthly statistics
  Map<String, UPITransactionSummary> getMonthlyStats(int months) {
    final stats = <String, UPITransactionSummary>{};
    final now = DateTime.now();
    
    for (int i = 0; i < months; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 0);
      
      final monthName = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      final filtered = getTransactionsByDateRange(start, end);
      
      if (filtered.isNotEmpty) {
        stats[monthName] = UPITransactionSummary.fromTransactions(
          filtered,
          periodStart: start,
          periodEnd: end,
        );
      }
    }
    
    return stats;
  }

  /// Set auto-sync enabled
  void setAutoSyncEnabled(bool enabled) {
    _isAutoSyncEnabled = enabled;
    notifyListeners();
  }

  /// Register listener
  void registerListener(UPITransactionListener listener) {
    _listeners.add(listener);
  }

  /// Unregister listener
  void unregisterListener(UPITransactionListener listener) {
    _listeners.remove(listener);
  }

  /// Clear all transactions
  void clearAll() {
    _transactions.clear();
    notifyListeners();
    _saveTransactions();
  }

  /// Export transactions
  String exportTransactions() {
    final data = _transactions.map((tx) => tx.toJson()).toList();
    return data.toString();
  }

  // Private methods

  String _getSourceAppFromPackage(String packageName) {
    final app = UPIApp.supportedApps.firstWhere(
      (app) => app.packageName == packageName,
      orElse: () => UPIApp(id: 'unknown', name: 'Unknown', packageName: packageName),
    );
    return app.name;
  }

  String _generateTempUtr() {
    return 'TEMP-${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _autoSyncTransaction(UPITransaction transaction) async {
    // In real implementation:
    // - Create corresponding app transaction
    // - Update wallet balance
    // - Apply smart categorization
    
    for (final listener in _listeners) {
      await listener.onTransactionForSync(transaction);
    }
  }

  Future<void> _loadTransactions() async {
    // Load from local storage
    // Implementation would use shared preferences or database
  }

  Future<void> _saveTransactions() async {
    // Save to local storage
  }

  List<SmsMessage> _parseSmsBackup(String backupData) {
    // Parse SMS backup format
    return [];
  }

  @override
  void dispose() {
    _transactionStreamController.close();
    stopListening();
    super.dispose();
  }
}

/// Listener interface for UPI transactions
abstract class UPITransactionListener {
  void onTransactionReceived(UPITransaction transaction);
  Future<void> onTransactionForSync(UPITransaction transaction);
}

/// UPI service configuration
class UPIServiceConfig {
  final bool enableSmsReading;
  final bool enableNotificationListening;
  final bool enableAutoSync;
  final int scanDaysBack;
  final List<String> enabledSourceApps;

  UPIServiceConfig({
    this.enableSmsReading = true,
    this.enableNotificationListening = true,
    this.enableAutoSync = true,
    this.scanDaysBack = 90,
    this.enabledSourceApps = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'enableSmsReading': enableSmsReading,
      'enableNotificationListening': enableNotificationListening,
      'enableAutoSync': enableAutoSync,
      'scanDaysBack': scanDaysBack,
      'enabledSourceApps': enabledSourceApps,
    };
  }

  factory UPIServiceConfig.fromJson(Map<String, dynamic> json) {
    return UPIServiceConfig(
      enableSmsReading: json['enableSmsReading'] as bool? ?? true,
      enableNotificationListening: json['enableNotificationListening'] as bool? ?? true,
      enableAutoSync: json['enableAutoSync'] as bool? ?? true,
      scanDaysBack: json['scanDaysBack'] as int? ?? 90,
      enabledSourceApps: (json['enabledSourceApps'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}
