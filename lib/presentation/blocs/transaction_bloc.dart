import 'package:flutter/foundation.dart';
import '../../data/models/transaction_model.dart';

/// BLoC for managing transaction state
class TransactionBloc extends ChangeNotifier {
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
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      _transactions = _getMockTransactions();
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
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 300));

      _transactions.insert(0, transaction);
      _applyFilter();
    } catch (e) {
      _setError('Failed to add transaction');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    _setLoading(true);

    try {
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
        result = result.where((t) => t.type == TransactionType.expense).toList();
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

  // Mock data for development
  List<Transaction> _getMockTransactions() {
    return [
      Transaction(
        id: '1',
        title: 'Grocery Shopping',
        amount: 125.50,
        type: TransactionType.expense,
        category: 'Food',
        date: DateTime.now(),
        note: 'Weekly groceries',
      ),
      Transaction(
        id: '2',
        title: 'Salary',
        amount: 5000.00,
        type: TransactionType.income,
        category: 'Salary',
        date: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Transaction(
        id: '3',
        title: 'Netflix Subscription',
        amount: 15.99,
        type: TransactionType.expense,
        category: 'Entertainment',
        date: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Transaction(
        id: '4',
        title: 'Gas Station',
        amount: 45.00,
        type: TransactionType.expense,
        category: 'Transport',
        date: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Transaction(
        id: '5',
        title: 'Freelance Work',
        amount: 850.00,
        type: TransactionType.income,
        category: 'Freelance',
        date: DateTime.now().subtract(const Duration(days: 4)),
      ),
    ];
  }
}

enum TransactionFilter {
  all,
  income,
  expense,
}
