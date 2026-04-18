import 'package:drift/drift.dart';
import '../database/database.dart' as db;
import '../models/wallet_model.dart';

/// Repository for wallet data operations
class WalletRepository {
  final db.AppDatabase _database;

  WalletRepository(this._database);

  /// Get all wallets
  Future<List<Wallet>> getAllWallets() async {
    final dbWallets = await _database.getAllWallets();
    return dbWallets.map(_mapToModel).toList();
  }

  /// Get active wallets (not archived)
  Future<List<Wallet>> getActiveWallets() async {
    final dbWallets = await _database.getActiveWallets();
    return dbWallets.map(_mapToModel).toList();
  }

  /// Get default wallet
  Future<Wallet?> getDefaultWallet() async {
    final dbWallet = await _database.getDefaultWallet();
    return dbWallet != null ? _mapToModel(dbWallet) : null;
  }

  /// Get wallet by ID
  Future<Wallet?> getWalletById(String id) async {
    final dbWallet = await _database.getWalletById(id);
    return dbWallet != null ? _mapToModel(dbWallet) : null;
  }

  /// Insert a new wallet
  Future<void> insertWallet(Wallet wallet) async {
    await _database.insertWallet(_mapToCompanion(wallet));
  }

  /// Update an existing wallet
  Future<void> updateWallet(Wallet wallet) async {
    await _database.updateWallet(_mapToCompanion(wallet));
  }

  /// Delete a wallet
  Future<void> deleteWallet(String id) async {
    await _database.deleteWallet(id);
  }

  /// Set wallet as default
  Future<void> setDefaultWallet(String id) async {
    await _database.setDefaultWallet(id);
  }

  /// Archive/unarchive wallet
  Future<void> setWalletArchived(String id, bool archived) async {
    final wallet = await getWalletById(id);
    if (wallet != null) {
      await updateWallet(wallet.copyWith(isArchived: archived));
    }
  }

  /// Update wallet balance
  Future<void> updateBalance(String id, double newBalance) async {
    final wallet = await getWalletById(id);
    if (wallet != null) {
      await updateWallet(wallet.copyWith(balance: newBalance));
    }
  }

  /// Add amount to wallet balance
  Future<void> addToBalance(String id, double amount) async {
    final wallet = await getWalletById(id);
    if (wallet != null) {
      await updateWallet(wallet.copyWith(balance: wallet.balance + amount));
    }
  }

  /// Subtract amount from wallet balance
  Future<void> subtractFromBalance(String id, double amount) async {
    final wallet = await getWalletById(id);
    if (wallet != null) {
      await updateWallet(wallet.copyWith(balance: wallet.balance - amount));
    }
  }

  /// Transfer between wallets
  Future<void> transferBetweenWallets({
    required String fromWalletId,
    required String toWalletId,
    required double amount,
    double? exchangeRate,
    String? note,
  }) async {
    final fromWallet = await getWalletById(fromWalletId);
    final toWallet = await getWalletById(toWalletId);

    if (fromWallet == null || toWallet == null) {
      throw Exception('One or both wallets not found');
    }

    if (fromWallet.balance < amount) {
      throw Exception('Insufficient balance in source wallet');
    }

    // Calculate converted amount
    final convertedAmount = exchangeRate != null ? amount * exchangeRate : amount;

    // Update balances
    await subtractFromBalance(fromWalletId, amount);
    await addToBalance(toWalletId, convertedAmount);

    // Record transfer
    final transfer = WalletTransfer(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fromWalletId: fromWalletId,
      toWalletId: toWalletId,
      amount: amount,
      exchangeRate: exchangeRate,
      note: note,
      date: DateTime.now(),
      createdAt: DateTime.now(),
    );

    await _database.insertWalletTransfer(_mapTransferToCompanion(transfer));
  }

  /// Get total balance across all wallets
  Future<double> getTotalBalance() async {
    final wallets = await getActiveWallets();
    double total = 0.0;
    for (final wallet in wallets) {
      total += wallet.balance;
    }
    return total;
  }

  /// Get total balance by currency
  Future<Map<String, double>> getBalancesByCurrency() async {
    final wallets = await getActiveWallets();
    final balances = <String, double>{};

    for (final wallet in wallets) {
      balances[wallet.currency] = (balances[wallet.currency] ?? 0.0) + wallet.balance;
    }

    return balances;
  }

  /// Get wallet transfer history
  Future<List<WalletTransfer>> getWalletTransfers(String walletId) async {
    final dbTransfers = await _database.getWalletTransfersByWallet(walletId);
    return dbTransfers.map(_mapTransferToModel).toList();
  }

  /// Map database model to domain model
  Wallet _mapToModel(db.Wallet dbWallet) {
    return Wallet(
      id: dbWallet.id,
      name: dbWallet.name,
      type: WalletType.values.firstWhere(
        (e) => e.name == dbWallet.type,
        orElse: () => WalletType.cash,
      ),
      currency: dbWallet.currency,
      balance: dbWallet.balance,
      colorValue: dbWallet.colorValue,
      iconName: dbWallet.iconName,
      isDefault: dbWallet.isDefault,
      isArchived: dbWallet.isArchived,
      note: dbWallet.note,
      createdAt: dbWallet.createdAt,
      updatedAt: dbWallet.updatedAt,
    );
  }

  /// Map domain model to database companion
  db.WalletsCompanion _mapToCompanion(Wallet wallet) {
    return db.WalletsCompanion(
      id: Value(wallet.id),
      name: Value(wallet.name),
      type: Value(wallet.type.name),
      currency: Value(wallet.currency),
      balance: Value(wallet.balance),
      colorValue: Value(wallet.colorValue),
      iconName: Value(wallet.iconName),
      isDefault: Value(wallet.isDefault),
      isArchived: Value(wallet.isArchived),
      note: Value(wallet.note),
      createdAt: Value(wallet.createdAt),
      updatedAt: Value(wallet.updatedAt),
    );
  }

  /// Map database transfer to domain model
  WalletTransfer _mapTransferToModel(db.WalletTransfer dbTransfer) {
    return WalletTransfer(
      id: dbTransfer.id,
      fromWalletId: dbTransfer.fromWalletId,
      toWalletId: dbTransfer.toWalletId,
      amount: dbTransfer.amount,
      exchangeRate: dbTransfer.exchangeRate,
      note: dbTransfer.note,
      date: dbTransfer.date,
      createdAt: dbTransfer.createdAt,
    );
  }

  /// Map domain transfer to database companion
  db.WalletTransfersCompanion _mapTransferToCompanion(WalletTransfer transfer) {
    return db.WalletTransfersCompanion(
      id: Value(transfer.id),
      fromWalletId: Value(transfer.fromWalletId),
      toWalletId: Value(transfer.toWalletId),
      amount: Value(transfer.amount),
      exchangeRate: Value(transfer.exchangeRate),
      note: Value(transfer.note),
      date: Value(transfer.date),
      createdAt: Value(transfer.createdAt),
    );
  }
}
