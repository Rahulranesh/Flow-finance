import 'package:flutter/foundation.dart' hide Category;
import '../../data/models/transaction_model.dart';

/// BLoC for managing budget state
class BudgetBloc extends ChangeNotifier {
  // State
  List<Budget> _budgets = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Budget> get budgets => _budgets;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Computed
  double get totalBudgetLimit => _budgets
      .where((b) => b.isActive)
      .fold(0, (sum, b) => sum + b.limit);

  Map<String, BudgetProgress> get budgetProgress {
    final Map<String, BudgetProgress> result = {};

    for (final budget in _budgets.where((b) => b.isActive)) {
      final category = _categories.firstWhere(
        (c) => c.id == budget.categoryId,
        orElse: () => Category.defaultCategories.first,
      );

      // Mock spent amount - in real app, calculate from transactions
      final spent = budget.limit * 0.65; // 65% spent as mock

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
      await Future.delayed(const Duration(milliseconds: 500));

      _categories = Category.defaultCategories;
      _budgets = _getMockBudgets();
    } catch (e) {
      _setError('Failed to load budgets');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addBudget(Budget budget) async {
    _setLoading(true);

    try {
      await Future.delayed(const Duration(milliseconds: 300));

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

  Future<void> deleteBudget(String id) async {
    _setLoading(true);

    try {
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

  List<Budget> _getMockBudgets() {
    return [
      Budget(
        id: '1',
        categoryId: 'food',
        limit: 800,
        period: BudgetPeriod.monthly,
        startDate: DateTime.now().subtract(const Duration(days: 15)),
      ),
      Budget(
        id: '2',
        categoryId: 'transport',
        limit: 400,
        period: BudgetPeriod.monthly,
        startDate: DateTime.now().subtract(const Duration(days: 15)),
      ),
      Budget(
        id: '3',
        categoryId: 'shopping',
        limit: 500,
        period: BudgetPeriod.monthly,
        startDate: DateTime.now().subtract(const Duration(days: 15)),
      ),
      Budget(
        id: '4',
        categoryId: 'entertainment',
        limit: 200,
        period: BudgetPeriod.monthly,
        startDate: DateTime.now().subtract(const Duration(days: 15)),
      ),
    ];
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
