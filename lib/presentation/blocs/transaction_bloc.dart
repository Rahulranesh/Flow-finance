import 'package:flutter/foundation.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../data/repositories/recurring_transaction_repository.dart';
import '../../core/services/smart_rules_engine.dart';
import '../../core/services/auto_transfer_service.dart';

/// BLoC for managing transaction state
class TransactionBloc extends ChangeNotifier {
  final TransactionRepository _repository;
  final WalletRepository _walletRepository;
  final SmartRulesEngine _smartRulesEngine;
  final AutoTransferService _autoTransferService;
  final RecurringTransactionRepository _recurringRepository;

  TransactionBloc(
    this._repository,
    this._walletRepository,
    this._smartRulesEngine,
    this._autoTransferService,
    this._recurringRepository,
  );

  // State
  List<Transaction> _transactions = [];
  List<Transaction> _filteredTransactions = [];
  TransactionFilter _currentFilter = TransactionFilter.all;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Transaction> get transactions => _filteredTransactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  TransactionFilter get currentFilter => _currentFilter;

  // Computed
  double get totalIncome => _transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0, (sum, t) => sum + t.amount);

  double get totalExpense => _transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpense;

  Map<String, double> get expensesByCategory {
    final Map<String, double> result = {};
    for (final transaction in _transactions.where(
      (t) => t.type == TransactionType.expense,
    )) {
      result[transaction.category] =
          (result[transaction.category] ?? 0) + transaction.amount;
    }
    return result;
  }

  // Actions
  Future<void> loadTransactions() async {
    _setLoading(true);
    _clearError();

    try {
      _transactions = await _repository.getAllTransactions();
      _applyFilter();
    } catch (e) {
      _setError('Failed to load transactions');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    _setLoading(true);

    try {
      await _repository.insertTransaction(transaction);
      // Apply smart rules
      final ruleResult = _smartRulesEngine.processTransaction(transaction);
      final processedTransaction = ruleResult.modifiedTransaction;
      // Update wallet balances based on transaction type
      if (processedTransaction.type == TransactionType.income) {
        await _walletRepository.addToBalance(processedTransaction.walletId!, processedTransaction.amount);
      } else if (processedTransaction.type == TransactionType.expense) {
        await _walletRepository.subtractFromBalance(processedTransaction.walletId!, processedTransaction.amount);
      }
      // Process auto-transfer recommendations
      final recommendations = _autoTransferService.processTransaction(processedTransaction);
      for (final rec in recommendations) {
        final rate = await _resolveExchangeRate(rec.sourceWalletId, rec.destinationWalletId);
        await _walletRepository.transferBetweenWallets(
          fromWalletId: rec.sourceWalletId,
          toWalletId: rec.destinationWalletId,
          amount: rec.amount,
          exchangeRate: rate,
        );
        // Record transfer execution
        await _autoTransferService.executeTransfer(rec);
      }
      _transactions.insert(0, processedTransaction);
      _applyFilter();
    } catch (e) {
      _setError('Failed to add transaction');
    } finally {
      _setLoading(false);
    }
  }

  Future<int> addTransactions(List<Transaction> transactions) async {
    _setLoading(true);

    try {
      final existingIds = _transactions.map((item) => item.id).toSet();
      int imported = 0;

      for (final transaction in transactions) {
        if (existingIds.contains(transaction.id)) continue;
        final ruleResult = _smartRulesEngine.processTransaction(transaction);
        final processedTransaction = ruleResult.modifiedTransaction;
        await _repository.insertTransaction(processedTransaction);
        _transactions.add(processedTransaction);
        existingIds.add(processedTransaction.id);
        imported++;
      }

      _applyFilter();
      return imported;
    } catch (e) {
      _setError('Failed to import transactions');
      return 0;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    _setLoading(true);

    try {
      final ruleResult = _smartRulesEngine.processTransaction(transaction);
      final processedTransaction = ruleResult.modifiedTransaction;
      await _repository.updateTransaction(processedTransaction);
      // Update wallet balances if amount or type changed
      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        final original = _transactions[index];
        if (original.type != processedTransaction.type ||
            original.amount != processedTransaction.amount) {
          if (original.type == TransactionType.income) {
            await _walletRepository.subtractFromBalance(
                original.walletId!, original.amount);
          } else if (original.type == TransactionType.expense) {
            await _walletRepository.addToBalance(
                original.walletId!, original.amount);
          }
          if (processedTransaction.type == TransactionType.income) {
            await _walletRepository.addToBalance(
                processedTransaction.walletId!, processedTransaction.amount);
          } else if (processedTransaction.type == TransactionType.expense) {
            await _walletRepository.subtractFromBalance(
                processedTransaction.walletId!, processedTransaction.amount);
          }
        }
        _transactions[index] = processedTransaction;
        _applyFilter();
      }
    } catch (e) {
      _setError('Failed to update transaction');
    } finally {
      _setLoading(false);
    }
  }

  Future<int> processDueRecurringTransactions() async {
    try {
      final due = await _recurringRepository.autoProcessDueTransactions();
      int processed = 0;
      for (final transaction in due) {
        await _repository.insertTransaction(transaction);
        final ruleResult = _smartRulesEngine.processTransaction(transaction);
        final processedTransaction = ruleResult.modifiedTransaction;
        if (processedTransaction.type == TransactionType.income) {
          await _walletRepository.addToBalance(
              processedTransaction.walletId!, processedTransaction.amount);
        } else if (processedTransaction.type == TransactionType.expense) {
          await _walletRepository.subtractFromBalance(
              processedTransaction.walletId!, processedTransaction.amount);
        }
        final recommendations =
            _autoTransferService.processTransaction(processedTransaction);
        for (final rec in recommendations) {
          final rate = await _resolveExchangeRate(rec.sourceWalletId, rec.destinationWalletId);
          await _walletRepository.transferBetweenWallets(
            fromWalletId: rec.sourceWalletId,
            toWalletId: rec.destinationWalletId,
            amount: rec.amount,
            exchangeRate: rate,
          );
          await _autoTransferService.executeTransfer(rec);
        }
        _transactions.insert(0, processedTransaction);
        processed++;
      }
      if (processed > 0) _applyFilter();
      return processed;
    } catch (e) {
      return 0;
    }
  }

  Future<void> deleteTransaction(String id) async {
    _setLoading(true);

    try {
      await _repository.deleteTransaction(id);
      // Reverse wallet balance update
      final deletedTx = _transactions.any((t) => t.id == id)
          ? _transactions.firstWhere((t) => t.id == id)
          : null;
      if (deletedTx != null) {
        if (deletedTx.type == TransactionType.income) {
          await _walletRepository.subtractFromBalance(deletedTx.walletId!, deletedTx.amount);
        } else if (deletedTx.type == TransactionType.expense) {
          await _walletRepository.addToBalance(deletedTx.walletId!, deletedTx.amount);
        }
      }
      _transactions.removeWhere((t) => t.id == id);
      _applyFilter();
    } catch (e) {
      _setError('Failed to delete transaction');
    } finally {
      _setLoading(false);
    }
  }

  void setFilter(TransactionFilter filter) {
    _currentFilter = filter;
    _applyFilter();
  }

  void search(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilter();
  }

  void clearSearch() {
    _searchQuery = '';
    _applyFilter();
  }

  // Private methods
  void _applyFilter() {
    var result = List<Transaction>.from(_transactions);

    // Apply type filter
    switch (_currentFilter) {
      case TransactionFilter.income:
        result = result.where((t) => t.type == TransactionType.income).toList();
        break;
      case TransactionFilter.expense:
        result =
            result.where((t) => t.type == TransactionType.expense).toList();
        break;
      case TransactionFilter.all:
        break;
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      result = result.where((t) {
        return t.title.toLowerCase().contains(_searchQuery) ||
            t.category.toLowerCase().contains(_searchQuery) ||
            t.note?.toLowerCase().contains(_searchQuery) == true;
      }).toList();
    }

    // Sort by date (newest first)
    result.sort((a, b) => b.date.compareTo(a.date));

    _filteredTransactions = result;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  /// Resolve exchange rate between two wallets.
  /// Returns null (same-currency) or the rate from source to destination.
  Future<double?> _resolveExchangeRate(String fromId, String toId) async {
    try {
      final from = await _walletRepository.getWalletById(fromId);
      final to = await _walletRepository.getWalletById(toId);
      if (from == null || to == null) return null;
      if (from.currency == to.currency) return null;
      // For cross-currency auto-transfers, default to 1:1
      // The user should set up rules using same-currency wallets
      // or manually adjust via wallet transfer screen
      return 1.0;
    } catch (_) {
      return null;
    }
  }
}

enum TransactionFilter {
  all,
  income,
  expense,
}
