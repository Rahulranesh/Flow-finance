import 'package:flutter/foundation.dart' hide Category;
import 'dart:async';
import '../../core/services/budget_alert_service.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/budget_repository.dart';
import '../../data/repositories/transaction_repository.dart';

/// BLoC for managing budget state
class BudgetBloc extends ChangeNotifier {
  final BudgetRepository _repository;
  final TransactionRepository _transactionRepository;
  final BudgetAlertService _alertService = BudgetAlertService();
  StreamSubscription<List<Transaction>>? _transactionsSubscription;

  BudgetBloc(this._repository, this._transactionRepository) {
    _transactionsSubscription =
        _transactionRepository.watchAllTransactions().listen(
      (transactions) {
        _transactions = transactions;
        notifyListeners();
      },
    );
  }

  // State
  List<Budget> _budgets = [];
  List<Category> _categories = [];
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Budget> get budgets => _budgets;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Computed
  double get totalBudgetLimit =>
      _budgets.where((b) => b.isActive).fold(0, (sum, b) => sum + b.limit);

  Map<String, BudgetProgress> get budgetProgress {
    final Map<String, BudgetProgress> result = {};

    for (final budget in _budgets.where((b) => b.isActive)) {
      final category = _categories.firstWhere(
        (c) => c.id == budget.categoryId,
        orElse: () => Category.defaultCategories.first,
      );

      final spent = _calculateSpentForCategory(category, budget);

      result[budget.id] = BudgetProgress(
        budget: budget,
        category: category,
        spent: spent,
        remaining: budget.limit - spent,
        percentage: (spent / budget.limit).clamp(0.0, 1.0),
      );
    }

    return result;
  }

  List<BudgetWithCategory> get budgetsWithCategories {
    return _budgets.where((b) => b.isActive).map((budget) {
      final category = _categories.firstWhere(
        (c) => c.id == budget.categoryId,
        orElse: () => Category.defaultCategories.first,
      );
      return BudgetWithCategory(budget: budget, category: category);
    }).toList();
  }

  // Actions
  Future<void> loadBudgets() async {
    _setLoading(true);
    _clearError();

    try {
      _categories = Category.defaultCategories;
      _budgets = await _repository.getAllBudgets();
      _transactions = await _transactionRepository.getAllTransactions();
    } catch (e) {
      _setError('Failed to load budgets');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addBudget(Budget budget) async {
    _setLoading(true);

    try {
      await _repository.insertBudget(budget);
      _budgets.add(budget);
      notifyListeners();
    } catch (e) {
      _setError('Failed to add budget');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateBudget(Budget budget) async {
    _setLoading(true);

    try {
      await _repository.updateBudget(budget);
      final index = _budgets.indexWhere((b) => b.id == budget.id);
      if (index != -1) {
        _budgets[index] = budget;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update budget');
    } finally {
      _setLoading(false);
    }
  }

  /// Check budget spending and trigger alerts if needed
  Future<void> checkBudgetAlerts(List<Transaction> transactions) async {
    for (final budget in _budgets.where((b) => b.isActive)) {
      final category = _categories.firstWhere(
        (c) => c.id == budget.categoryId,
        orElse: () => Category.defaultCategories.first,
      );

      await _alertService.checkBudgetAlerts(
        budget: budget,
        transactions: transactions,
        categoryName: category.name,
      );
    }
  }

  Future<void> deleteBudget(String id) async {
    _setLoading(true);

    try {
      await _repository.deleteBudget(id);
      _budgets.removeWhere((b) => b.id == id);
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete budget');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> toggleBudgetStatus(String id) async {
    try {
      final index = _budgets.indexWhere((b) => b.id == id);
      if (index != -1) {
        final budget = _budgets[index];
        _budgets[index] = budget.copyWith(isActive: !budget.isActive);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to toggle budget status');
    }
  }

  // Private methods
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

  double _calculateSpentForCategory(Category category, Budget budget) {
    return _transactions.where((transaction) {
      if (transaction.type != TransactionType.expense) return false;
      if (transaction.date.isBefore(budget.startDate)) return false;
      if (budget.endDate != null && transaction.date.isAfter(budget.endDate!)) {
        return false;
      }

      final normalizedTransaction = _normalizeCategory(transaction.category);
      return normalizedTransaction == _normalizeCategory(category.id) ||
          normalizedTransaction == _normalizeCategory(category.name);
    }).fold<double>(0, (sum, item) => sum + item.amount);
  }

  String _normalizeCategory(String value) {
    return value
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  @override
  void dispose() {
    _transactionsSubscription?.cancel();
    super.dispose();
  }
}

/// Budget progress data class
class BudgetProgress {
  final Budget budget;
  final Category category;
  final double spent;
  final double remaining;
  final double percentage;

  const BudgetProgress({
    required this.budget,
    required this.category,
    required this.spent,
    required this.remaining,
    required this.percentage,
  });

  bool get isOverBudget => spent > budget.limit;
  bool get isNearLimit => percentage >= 0.8 && !isOverBudget;
  bool get isOnTrack => percentage < 0.8;

  String get statusText {
    if (isOverBudget) return 'Over Budget';
    if (isNearLimit) return 'Near Limit';
    return 'On Track';
  }
}

/// Budget with category data class
class BudgetWithCategory {
  final Budget budget;
  final Category category;

  const BudgetWithCategory({
    required this.budget,
    required this.category,
  });
}
