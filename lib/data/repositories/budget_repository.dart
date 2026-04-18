import 'package:drift/drift.dart';
import '../database/database.dart' as db;
import '../models/transaction_model.dart';

/// Repository for budget data operations
class BudgetRepository {
  final db.AppDatabase _database;

  BudgetRepository(this._database);

  /// Get all budgets
  Future<List<Budget>> getAllBudgets() async {
    final dbBudgets = await _database.getAllBudgets();
    return dbBudgets.map(_mapToModel).toList();
  }

  /// Get active budgets
  Future<List<Budget>> getActiveBudgets() async {
    final dbBudgets = await _database.getActiveBudgets();
    return dbBudgets.map(_mapToModel).toList();
  }

  /// Get budget by ID
  Future<Budget?> getBudgetById(String id) async {
    final dbBudgets = await _database.getAllBudgets();
    return dbBudgets
        .where((b) => b.id == id)
        .map(_mapToModel)
        .firstOrNull;
  }

  /// Insert a new budget
  Future<void> insertBudget(Budget budget) async {
    await _database.insertBudget(_mapToCompanion(budget));
  }

  /// Update an existing budget
  Future<void> updateBudget(Budget budget) async {
    await _database.updateBudget(_mapToCompanion(budget));
  }

  /// Delete a budget
  Future<void> deleteBudget(String id) async {
    await _database.deleteBudget(id);
  }

  /// Toggle budget active status
  Future<void> toggleBudgetStatus(String id, bool isActive) async {
    final budget = await getBudgetById(id);
    if (budget != null) {
      await updateBudget(budget.copyWith(isActive: isActive));
    }
  }

  /// Map database model to domain model
  Budget _mapToModel(db.Budget dbBudget) {
    return Budget(
      id: dbBudget.id,
      categoryId: dbBudget.categoryId,
      limit: dbBudget.limit,
      period: BudgetPeriod.values.firstWhere(
        (e) => e.name == dbBudget.period,
        orElse: () => BudgetPeriod.monthly,
      ),
      startDate: dbBudget.startDate,
      endDate: dbBudget.endDate,
      isActive: dbBudget.isActive,
    );
  }

  /// Map domain model to database companion
  db.BudgetsCompanion _mapToCompanion(Budget budget) {
    return db.BudgetsCompanion(
      id: Value(budget.id),
      categoryId: Value(budget.categoryId),
      limit: Value(budget.limit),
      period: Value(budget.period.name),
      startDate: Value(budget.startDate),
      endDate: Value(budget.endDate),
      isActive: Value(budget.isActive),
    );
  }
}
