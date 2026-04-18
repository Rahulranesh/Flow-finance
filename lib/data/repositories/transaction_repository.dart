import '../database/database.dart';
import '../models/transaction_model.dart';

/// Repository for transaction data operations
class TransactionRepository {
  final AppDatabase _database;

  TransactionRepository(this._database);

  /// Get all transactions
  Future<List<Transaction>> getAllTransactions() async {
    final dbTransactions = await _database.getAllTransactions();
    return dbTransactions.map(_mapToModel).toList();
  }

  /// Get transaction by ID
  Future<Transaction?> getTransactionById(String id) async {
    final dbTransaction = await _database.getTransactionById(id);
    return dbTransaction != null ? _mapToModel(dbTransaction) : null;
  }

  /// Get transactions by date range
  Future<List<Transaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final dbTransactions = await _database.getTransactionsByDateRange(start, end);
    return dbTransactions.map(_mapToModel).toList();
  }

  /// Get transactions by type
  Future<List<Transaction>> getTransactionsByType(TransactionType type) async {
    final dbTransactions = await _database.getTransactionsByType(type.name);
    return dbTransactions.map(_mapToModel).toList();
  }

  /// Get transactions by category
  Future<List<Transaction>> getTransactionsByCategory(String categoryId) async {
    final dbTransactions = await _database.getTransactionsByCategory(categoryId);
    return dbTransactions.map(_mapToModel).toList();
  }

  /// Watch all transactions as stream
  Stream<List<Transaction>> watchAllTransactions() {
    return _database.watchAllTransactions().map(
          (list) => list.map(_mapToModel).toList(),
        );
  }

  /// Insert a new transaction
  Future<void> insertTransaction(Transaction transaction) async {
    await _database.insertTransaction(_mapToCompanion(transaction));
  }

  /// Update an existing transaction
  Future<void> updateTransaction(Transaction transaction) async {
    await _database.updateTransaction(_mapToCompanion(transaction));
  }

  /// Delete a transaction
  Future<void> deleteTransaction(String id) async {
    await _database.deleteTransaction(id);
  }

  /// Get total income
  Future<double> getTotalIncome() => _database.getTotalIncome();

  /// Get total expense
  Future<double> getTotalExpense() => _database.getTotalExpense();

  /// Get expenses by category
  Future<Map<String, double>> getExpensesByCategory() =>
      _database.getExpensesByCategory();

  /// Map database model to domain model
  Transaction _mapToModel(db.Transaction dbTransaction) {
    return Transaction(
      id: dbTransaction.id,
      title: dbTransaction.title,
      amount: dbTransaction.amount,
      type: TransactionType.values.firstWhere(
        (e) => e.name == dbTransaction.type,
        orElse: () => TransactionType.expense,
      ),
      category: dbTransaction.category,
      date: dbTransaction.date,
      note: dbTransaction.note,
      paymentMethod: dbTransaction.paymentMethod,
      isRecurring: dbTransaction.isRecurring,
      recurringId: dbTransaction.recurringId,
    );
  }

  /// Map domain model to database companion
  TransactionsCompanion _mapToCompanion(Transaction transaction) {
    return TransactionsCompanion(
      id: Value(transaction.id),
      title: Value(transaction.title),
      amount: Value(transaction.amount),
      type: Value(transaction.type.name),
      category: Value(transaction.category),
      date: Value(transaction.date),
      note: Value(transaction.note),
      paymentMethod: Value(transaction.paymentMethod),
      isRecurring: Value(transaction.isRecurring),
      recurringId: Value(transaction.recurringId),
    );
  }
}
