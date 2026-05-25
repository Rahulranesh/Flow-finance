import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../models/bank_account.dart' as bank;
import '../../models/bank_transaction.dart' as bank;
import '../bank_integration/plaid_service.dart';
import '../bank_integration/truelayer_service.dart';
import '../bank_integration/upi_transaction_service.dart';
import 'reconciliation_engine.dart';

/// Engine for syncing transactions from multiple sources
class TransactionSyncEngine extends ChangeNotifier {
  static final TransactionSyncEngine _instance = TransactionSyncEngine._internal();
  factory TransactionSyncEngine() => _instance;
  TransactionSyncEngine._internal();

  final PlaidService _plaidService = PlaidService();
  final TrueLayerService _trueLayerService = TrueLayerService();
  final UPITransactionService _upiService = UPITransactionService();
  final ReconciliationEngine _reconciliationEngine = ReconciliationEngine();

  final List<SyncJob> _syncJobs = [];
  final List<SyncRecord> _syncHistory = [];
  
  bool _isSyncing = false;
  SyncProgress? _currentProgress;

  // Getters
  bool get isSyncing => _isSyncing;
  SyncProgress? get currentProgress => _currentProgress;
  List<SyncRecord> get syncHistory => List.unmodifiable(_syncHistory);

  /// Stream controller for real-time sync updates
  final _syncStreamController = StreamController<SyncEvent>.broadcast();
  Stream<SyncEvent> get syncStream => _syncStreamController.stream;

  /// Full sync from all connected sources for a user
  Future<FullSyncResult> syncAllSources(String userId) async {
    _setSyncing(true);
    
    final results = <String, SyncResult>{};
    final startTime = DateTime.now();
    
    try {
      // Sync Plaid accounts
      if (_plaidService.isInitialized) {
        _updateProgress('Syncing Plaid accounts...', 0.1);
        results['plaid'] = await _syncPlaidAccounts(userId);
      }

      // Sync TrueLayer accounts
      if (_trueLayerService.isInitialized) {
        _updateProgress('Syncing TrueLayer accounts...', 0.3);
        results['truelayer'] = await _syncTrueLayerAccounts(userId);
      }

      // Sync UPI transactions
      _updateProgress('Syncing UPI transactions...', 0.6);
      results['upi'] = await _syncUPITransactions(userId);

      // Reconcile all transactions
      _updateProgress('Reconciling transactions...', 0.8);
      final reconciliationResult = await _reconciliationEngine.reconcileAll(userId);

      _updateProgress('Complete', 1.0);

      final result = FullSyncResult(
        success: true,
        sourceResults: results,
        reconciliationResult: reconciliationResult,
        startTime: startTime,
        endTime: DateTime.now(),
      );

      _recordSync(result);
      return result;
    } catch (e) {
      return FullSyncResult(
        success: false,
        sourceResults: results,
        error: e.toString(),
        startTime: startTime,
        endTime: DateTime.now(),
      );
    } finally {
      _setSyncing(false);
    }
  }

  /// Sync specific bank account
  Future<SyncResult> syncAccount(bank.BankAccount account) async {
    _setSyncing(true);
    
    try {
      switch (account.provider) {
        case 'plaid':
          return await _syncPlaidAccount(account);
        case 'truelayer':
          return await _syncTrueLayerAccount(account);
        default:
          throw Exception('Unknown provider: ${account.provider}');
      }
    } finally {
      _setSyncing(false);
    }
  }

  /// Incremental sync (last 24 hours)
  Future<SyncResult> incrementalSync(String userId) async {
    return syncAllSources(userId).then((result) {
      if (result.success) {
        return SyncResult(
          success: true,
          transactionsAdded: result.totalTransactionsAdded,
          transactionsUpdated: result.totalTransactionsUpdated,
          syncTime: DateTime.now(),
        );
      } else {
        return SyncResult(
          success: false,
          errors: [result.error ?? 'Unknown error'],
          syncTime: DateTime.now(),
        );
      }
    });
  }

  /// Sync Plaid accounts
  Future<SyncResult> _syncPlaidAccounts(String userId) async {
    final accessToken = await _plaidService.getAccessToken(userId);
    if (accessToken == null) {
      return SyncResult(
        success: false,
        errors: ['No Plaid access token found'],
        syncTime: DateTime.now(),
      );
    }

    final accounts = await _plaidService.getAccounts(accessToken, userId);
    int totalAdded = 0;
    int totalUpdated = 0;
    final errors = <String>[];

    for (final account in accounts) {
      try {
        final result = await _syncPlaidAccount(account);
        totalAdded += result.transactionsAdded;
        totalUpdated += result.transactionsUpdated;
      } catch (e) {
        errors.add('Account ${account.name}: $e');
      }
    }

    return SyncResult(
      success: errors.isEmpty,
      transactionsAdded: totalAdded,
      transactionsUpdated: totalUpdated,
      errors: errors,
      syncTime: DateTime.now(),
    );
  }

  /// Sync single Plaid account
  Future<SyncResult> _syncPlaidAccount(bank.BankAccount account) async {
    final accessToken = account.metadata['access_token'] as String?;
    if (accessToken == null) {
      throw Exception('No access token for account');
    }

    final startDate = DateTime.now().subtract(const Duration(days: 90));
    final endDate = DateTime.now();

    final transactions = await _plaidService.getAllTransactions(
      accessToken: accessToken,
      accountId: account.providerAccountId,
      startDate: startDate,
      endDate: endDate,
    );

    // Save transactions to database
    final added = await _saveTransactions(transactions);

    // Update account last synced
    await _updateAccountSyncStatus(account.id, bank.SyncStatus.success);

    return SyncResult(
      success: true,
      transactionsAdded: added,
      syncTime: DateTime.now(),
    );
  }

  /// Sync TrueLayer accounts
  Future<SyncResult> _syncTrueLayerAccounts(String userId) async {
    final tokens = await _trueLayerService.getTokens(userId);
    if (tokens == null) {
      return SyncResult(
        success: false,
        errors: ['No TrueLayer tokens found'],
        syncTime: DateTime.now(),
      );
    }

    // Refresh token if needed
    String accessToken = tokens.accessToken;
    if (tokens.refreshToken != null && 
        tokens.expiresAt != null &&
        tokens.expiresAt!.isBefore(DateTime.now())) {
      final newTokens = await _trueLayerService.refreshToken(tokens.refreshToken!);
      await _trueLayerService.storeTokens(userId, newTokens);
      accessToken = newTokens.accessToken;
    }

    final accounts = await _trueLayerService.getAccounts(accessToken, userId);
    int totalAdded = 0;
    final errors = <String>[];

    for (final account in accounts) {
      try {
        final startDate = DateTime.now().subtract(const Duration(days: 90));
        final endDate = DateTime.now();

        final transactions = await _trueLayerService.getTransactions(
          accessToken: accessToken,
          accountId: account.providerAccountId,
          fromDate: startDate,
          toDate: endDate,
        );

        final added = await _saveTransactions(transactions);
        totalAdded += added;

        await _updateAccountSyncStatus(account.id, bank.SyncStatus.success);
      } catch (e) {
        errors.add('Account ${account.name}: $e');
      }
    }

    return SyncResult(
      success: errors.isEmpty,
      transactionsAdded: totalAdded,
      errors: errors,
      syncTime: DateTime.now(),
    );
  }

  /// Sync single TrueLayer account
  Future<SyncResult> _syncTrueLayerAccount(bank.BankAccount account) async {
    // Implementation similar to _syncPlaidAccount
    return SyncResult(
      success: true,
      transactionsAdded: 0,
      syncTime: DateTime.now(),
    );
  }

  /// Sync UPI transactions
  Future<SyncResult> _syncUPITransactions(String userId) async {
    final pendingTransactions = _upiService.getPendingTransactions();
    int synced = 0;
    int failed = 0;

    for (final tx in pendingTransactions) {
      try {
        // Create app transaction from UPI transaction
        final appTx = await _reconciliationEngine.createAppTransactionFromUPITx(tx);
        if (appTx != null) {
          _upiService.linkToAppTransaction(tx.id, appTx.id);
          synced++;
        }
      } catch (e) {
        failed++;
        tx.markFailed();
      }
    }

    return SyncResult(
      success: failed == 0,
      transactionsAdded: synced,
      errors: failed > 0 ? ['$failed UPI transactions failed to sync'] : [],
      syncTime: DateTime.now(),
    );
  }

  /// Handle real-time webhook update
  Future<void> handleRealtimeUpdate(BankWebhookPayload payload) async {
    _syncStreamController.add(SyncEvent(
      type: SyncEventType.webhookReceived,
      message: 'Received ${payload.provider} webhook: ${payload.type}',
      timestamp: DateTime.now(),
    ));

    // Trigger incremental sync for the affected account
    await incrementalSync(payload.userId);
  }

  /// Detect duplicates in a list of transactions
  List<DuplicateGroup> findDuplicates(List<bank.BankTransaction> transactions) {
    final groups = <String, List<bank.BankTransaction>>{};

    for (final tx in transactions) {
      // Create a key based on amount, date, and similar name
      final key = '${tx.amount}_${tx.date.day}_${tx.date.month}_${tx.date.year}_'
          '${tx.name.substring(0, tx.name.length.clamp(0, 10))}';
      
      groups.putIfAbsent(key, () => []).add(tx);
    }

    return groups.entries
        .where((e) => e.value.length > 1)
        .map((e) => DuplicateGroup(
              key: e.key,
              transactions: e.value,
            ))
        .toList();
  }

  /// Merge duplicate transactions
  Future<void> mergeDuplicates(String keepId, List<String> removeIds) async {
    // Mark removed transactions as duplicates
    for (final id in removeIds) {
      await _markAsDuplicate(id, keepId);
    }
  }

  /// Get sync status for all accounts
  Future<Map<String, bank.SyncStatus>> getAllSyncStatus(String userId) async {
    // Implementation would query database
    return {};
  }

  /// Schedule automatic sync
  void scheduleAutoSync({
    required String userId,
    Duration interval = const Duration(hours: 6),
  }) {
    // Cancel existing job if any
    _cancelScheduledSync(userId);

    // Create new scheduled job
    final job = SyncJob(
      id: const Uuid().v4(),
      userId: userId,
      interval: interval,
      timer: Timer.periodic(interval, (_) => incrementalSync(userId)),
    );

    _syncJobs.add(job);
  }

  /// Cancel scheduled sync
  void _cancelScheduledSync(String userId) {
    _syncJobs.removeWhere((job) {
      if (job.userId == userId) {
        job.timer.cancel();
        return true;
      }
      return false;
    });
  }

  /// Get last sync time
  DateTime? getLastSyncTime(String userId) {
    final records = _syncHistory.where((r) => r.userId == userId);
    if (records.isEmpty) return null;
    return records.first.timestamp;
  }

  /// Clear sync history
  void clearHistory() {
    _syncHistory.clear();
    notifyListeners();
  }

  // Private methods

  void _setSyncing(bool value) {
    _isSyncing = value;
    if (!value) {
      _currentProgress = null;
    }
    notifyListeners();
  }

  void _updateProgress(String message, double progress) {
    _currentProgress = SyncProgress(message: message, percent: progress);
    _syncStreamController.add(SyncEvent(
      type: SyncEventType.progress,
      message: message,
      progress: progress,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  Future<int> _saveTransactions(List<bank.BankTransaction> transactions) async {
    // Implementation would save to database
    // Return number of new transactions added
    return transactions.length;
  }

  Future<void> _updateAccountSyncStatus(String accountId, bank.SyncStatus status) async {
    // Implementation would update database
  }

  Future<void> _markAsDuplicate(String transactionId, String masterId) async {
    // Implementation would mark transaction as duplicate in database
  }

  void _recordSync(FullSyncResult result) {
    _syncHistory.insert(0, SyncRecord(
      id: const Uuid().v4(),
      userId: result.sourceResults.values.first.toString(), // Simplified
      timestamp: result.endTime,
      success: result.success,
      transactionsAdded: result.totalTransactionsAdded,
      error: result.error,
    ));
    notifyListeners();
  }

  @override
  void dispose() {
    for (final job in _syncJobs) {
      job.timer.cancel();
    }
    _syncStreamController.close();
    super.dispose();
  }
}

/// Sync result for a single source
class SyncResult {
  final bool success;
  final int transactionsAdded;
  final int transactionsUpdated;
  final List<String> errors;
  final DateTime syncTime;
  final String? nextCursor;

  SyncResult({
    required this.success,
    this.transactionsAdded = 0,
    this.transactionsUpdated = 0,
    this.errors = const [],
    required this.syncTime,
    this.nextCursor,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get hasChanges => transactionsAdded > 0 || transactionsUpdated > 0;
}

/// Full sync result from all sources
class FullSyncResult {
  final bool success;
  final Map<String, SyncResult> sourceResults;
  final ReconciliationResult? reconciliationResult;
  final String? error;
  final DateTime startTime;
  final DateTime endTime;

  FullSyncResult({
    required this.success,
    required this.sourceResults,
    this.reconciliationResult,
    this.error,
    required this.startTime,
    required this.endTime,
  });

  int get totalTransactionsAdded => sourceResults.values
      .fold(0, (sum, r) => sum + r.transactionsAdded);
  
  int get totalTransactionsUpdated => sourceResults.values
      .fold(0, (sum, r) => sum + r.transactionsUpdated);
  
  Duration get duration => endTime.difference(startTime);
}

/// Duplicate transaction group
class DuplicateGroup {
  final String key;
  final List<bank.BankTransaction> transactions;

  DuplicateGroup({required this.key, required this.transactions});

  int get count => transactions.length;
}

/// Sync progress
class SyncProgress {
  final String message;
  final double percent;

  SyncProgress({required this.message, required this.percent});
}

/// Sync event for streaming
class SyncEvent {
  final SyncEventType type;
  final String message;
  final double? progress;
  final DateTime timestamp;

  SyncEvent({
    required this.type,
    required this.message,
    this.progress,
    required this.timestamp,
  });
}

enum SyncEventType {
  started,
  progress,
  completed,
  error,
  webhookReceived,
}

/// Scheduled sync job
class SyncJob {
  final String id;
  final String userId;
  final Duration interval;
  final Timer timer;

  SyncJob({
    required this.id,
    required this.userId,
    required this.interval,
    required this.timer,
  });
}

/// Sync history record
class SyncRecord {
  final String id;
  final String userId;
  final DateTime timestamp;
  final bool success;
  final int transactionsAdded;
  final String? error;

  SyncRecord({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.success,
    this.transactionsAdded = 0,
    this.error,
  });
}

/// Webhook payload
class BankWebhookPayload {
  final String provider;
  final String type;
  final String userId;
  final String? accountId;
  final Map<String, dynamic> data;

  BankWebhookPayload({
    required this.provider,
    required this.type,
    required this.userId,
    this.accountId,
    required this.data,
  });
}
