import 'package:flutter/foundation.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';

/// BLoC for managing transaction state
class TransactionBloc extends ChangeNotifier {
  final TransactionRepository _repository;

  TransactionBloc(this._repository);

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
      _transactions.insert(0, transaction);
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
        await _repository.insertTransaction(transaction);
        _transactions.add(transaction);
        existingIds.add(transaction.id);
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
      await _repository.updateTransaction(transaction);
      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = transaction;
        _applyFilter();
      }
    } catch (e) {
      _setError('Failed to update transaction');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteTransaction(String id) async {
    _setLoading(true);

    try {
      await _repository.deleteTransaction(id);
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
}

enum TransactionFilter {
  all,
  income,
  expense,
}
