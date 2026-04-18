import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;


part 'database.g.dart';

/// Transaction table definition
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  RealColumn get amount => real()();
  TextColumn get type => text()(); // 'income', 'expense', 'transfer'
  TextColumn get category => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  TextColumn get paymentMethod => text().nullable()();
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
  TextColumn get recurringId => text().nullable()();
  TextColumn get walletId => text().nullable()();
  TextColumn get currency => text().withDefault(const Constant('USD'))();
  RealColumn get exchangeRate => real().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Budget table definition
class Budgets extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text()();
  RealColumn get limit => real()();
  TextColumn get period => text().withDefault(const Constant('monthly'))(); // 'daily', 'weekly', 'monthly', 'yearly'
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Category table definition
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get iconName => text()();
  IntColumn get colorValue => integer()();
  RealColumn get budgetLimit => real().nullable()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Settings table definition
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {key};
}

/// Wallet table definition
class Wallets extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // 'cash', 'bank', 'creditCard', 'savings', 'investment', 'digital', 'other'
  TextColumn get currency => text().withDefault(const Constant('USD'))();
  RealColumn get balance => real().withDefault(const Constant(0.0))();
  IntColumn get colorValue => integer()();
  TextColumn get iconName => text().nullable()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Wallet transfer table definition
class WalletTransfers extends Table {
  TextColumn get id => text()();
  TextColumn get fromWalletId => text()();
  TextColumn get toWalletId => text()();
  RealColumn get amount => real()();
  RealColumn get exchangeRate => real().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Main database class
@DriftDatabase(tables: [Transactions, Budgets, Categories, Settings, Wallets, WalletTransfers])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _insertDefaultCategories();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Handle migrations here
    },
  );

  /// Insert default categories on first run
  Future<void> _insertDefaultCategories() async {
    final defaultCategories = [
      CategoriesCompanion.insert(
        id: 'food',
        name: 'Food & Dining',
        iconName: 'restaurant',
        colorValue: 0xFFF59E0B,
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        id: 'transport',
        name: 'Transportation',
        iconName: 'directions_car',
        colorValue: 0xFF3B82F6,
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        id: 'shopping',
        name: 'Shopping',
        iconName: 'shopping_bag',
        colorValue: 0xFFEC4899,
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        id: 'entertainment',
        name: 'Entertainment',
        iconName: 'movie',
        colorValue: 0xFF8B5CF6,
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        id: 'bills',
        name: 'Bills & Utilities',
        iconName: 'receipt',
        colorValue: 0xFFEF4444,
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        id: 'health',
        name: 'Health & Fitness',
        iconName: 'favorite',
        colorValue: 0xFF10B981,
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        id: 'education',
        name: 'Education',
        iconName: 'school',
        colorValue: 0xFF14B8A6,
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        id: 'salary',
        name: 'Salary',
        iconName: 'work',
        colorValue: 0xFF22C55E,
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        id: 'freelance',
        name: 'Freelance',
        iconName: 'laptop',
        colorValue: 0xFF6366F1,
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        id: 'investment',
        name: 'Investment',
        iconName: 'trending_up',
        colorValue: 0xFF06B6D4,
        isDefault: const Value(true),
      ),
    ];

    await batch((batch) {
      batch.insertAll(categories, defaultCategories);
    });
  }

  // Transaction queries
  Future<List<Transaction>> getAllTransactions() => select(transactions).get();

  Future<Transaction?> getTransactionById(String id) =>
      (select(transactions)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Transaction>> getTransactionsByDateRange(DateTime start, DateTime end) {
    return (select(transactions)
          ..where((t) => t.date.isBetweenValues(start, end)))
        .get();
  }

  Future<List<Transaction>> getTransactionsByType(String type) {
    return (select(transactions)..where((t) => t.type.equals(type))).get();
  }

  Future<List<Transaction>> getTransactionsByCategory(String categoryId) {
    return (select(transactions)..where((t) => t.category.equals(categoryId))).get();
  }

  Stream<List<Transaction>> watchAllTransactions() => select(transactions).watch();

  Future<int> insertTransaction(TransactionsCompanion transaction) =>
      into(transactions).insert(transaction);

  Future<bool> updateTransaction(TransactionsCompanion transaction) =>
      update(transactions).replace(transaction);

  Future<int> deleteTransaction(String id) =>
      (delete(transactions)..where((t) => t.id.equals(id))).go();

  // Budget queries
  Future<List<Budget>> getAllBudgets() => select(budgets).get();

  Future<List<Budget>> getActiveBudgets() {
    return (select(budgets)..where((b) => b.isActive.equals(true))).get();
  }

  Future<int> insertBudget(BudgetsCompanion budget) => into(budgets).insert(budget);

  Future<bool> updateBudget(BudgetsCompanion budget) => update(budgets).replace(budget);

  Future<int> deleteBudget(String id) =>
      (delete(budgets)..where((b) => b.id.equals(id))).go();

  // Category queries
  Future<List<Category>> getAllCategories() => select(categories).get();

  Future<Category?> getCategoryById(String id) =>
      (select(categories)..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<int> insertCategory(CategoriesCompanion category) =>
      into(categories).insert(category);

  Future<bool> updateCategory(CategoriesCompanion category) =>
      update(categories).replace(category);

  Future<int> deleteCategory(String id) =>
      (delete(categories)..where((c) => c.id.equals(id))).go();

  // Settings queries
  Future<String?> getSetting(String key) async {
    final result = await (select(settings)..where((s) => s.key.equals(key))).getSingleOrNull();
    return result?.value;
  }

  Future<void> setSetting(String key, String value) async {
    await into(settings).insertOnConflictUpdate(
      SettingsCompanion(key: Value(key), value: Value(value)),
    );
  }

  Future<int> deleteSetting(String key) =>
      (delete(settings)..where((s) => s.key.equals(key))).go();

  // Statistics queries
  Future<double> getTotalIncome() async {
    final result = await customSelect(
      'SELECT SUM(amount) as total FROM transactions WHERE type = ?',
      variables: [Variable('income')],
    ).getSingleOrNull();
    final total = result?.data['total'];
    return total != null ? (total as num).toDouble() : 0.0;
  }

  Future<double> getTotalExpense() async {
    final result = await customSelect(
      'SELECT SUM(amount) as total FROM transactions WHERE type = ?',
      variables: [Variable('expense')],
    ).getSingleOrNull();
    final total = result?.data['total'];
    return total != null ? (total as num).toDouble() : 0.0;
  }

  Future<Map<String, double>> getExpensesByCategory() async {
    final result = await customSelect(
      'SELECT category, SUM(amount) as total FROM transactions WHERE type = ? GROUP BY category',
      variables: [Variable('expense')],
    ).get();

    return Map.fromEntries(
      result.map((row) => MapEntry(
        row.data['category'] as String,
        (row.data['total'] as num?)?.toDouble() ?? 0.0,
      )),
    );
  }

  // Wallet queries
  Future<List<Wallet>> getAllWallets() => select(wallets).get();

  Future<List<Wallet>> getActiveWallets() {
    return (select(wallets)..where((w) => w.isArchived.equals(false))).get();
  }

  Future<Wallet?> getDefaultWallet() {
    return (select(wallets)..where((w) => w.isDefault.equals(true))).getSingleOrNull();
  }

  Future<Wallet?> getWalletById(String id) {
    return (select(wallets)..where((w) => w.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertWallet(WalletsCompanion wallet) => into(wallets).insert(wallet);

  Future<bool> updateWallet(WalletsCompanion wallet) => update(wallets).replace(wallet);

  Future<int> deleteWallet(String id) =>
      (delete(wallets)..where((w) => w.id.equals(id))).go();

  Future<void> setDefaultWallet(String id) async {
    // Clear existing default
    await (update(wallets)..where((w) => w.isDefault.equals(true))).write(
      const WalletsCompanion(isDefault: Value(false)),
    );
    // Set new default
    await (update(wallets)..where((w) => w.id.equals(id))).write(
      const WalletsCompanion(isDefault: Value(true)),
    );
  }

  // Wallet transfer queries
  Future<List<WalletTransfer>> getAllWalletTransfers() => select(walletTransfers).get();

  Future<List<WalletTransfer>> getWalletTransfersByWallet(String walletId) {
    return (select(walletTransfers)
          ..where((t) => t.fromWalletId.equals(walletId) | t.toWalletId.equals(walletId)))
        .get();
  }

  Future<int> insertWalletTransfer(WalletTransfersCompanion transfer) =>
      into(walletTransfers).insert(transfer);

  Future<int> deleteWalletTransfer(String id) =>
      (delete(walletTransfers)..where((t) => t.id.equals(id))).go();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'flow_finance.db'));
    return NativeDatabase(file);
  });
}
