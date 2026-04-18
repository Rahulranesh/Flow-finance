import 'package:flutter/foundation.dart';
import '../../data/models/wallet_model.dart';
import '../../data/repositories/wallet_repository.dart';

/// BLoC for managing wallet state
class WalletBloc extends ChangeNotifier {
  final WalletRepository _repository;

  WalletBloc(this._repository);

  // State
  List<Wallet> _wallets = [];
  Wallet? _selectedWallet;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Wallet> get wallets => _wallets;
  List<Wallet> get activeWallets => _wallets.where((w) => !w.isArchived).toList();
  Wallet? get selectedWallet => _selectedWallet;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Computed
  double get totalBalance => activeWallets.fold(0.0, (sum, w) => sum + w.balance);

  Map<String, double> get balancesByCurrency {
    final balances = <String, double>{};
    for (final wallet in activeWallets) {
      balances[wallet.currency] = (balances[wallet.currency] ?? 0.0) + wallet.balance;
    }
    return balances;
  }

  Wallet? get defaultWallet {
    return activeWallets.firstWhere(
      (w) => w.isDefault,
      orElse: () => activeWallets.isNotEmpty ? activeWallets.first : null as Wallet,
    );
  }

  // Actions
  Future<void> loadWallets() async {
    _setLoading(true);
    _clearError();

    try {
      _wallets = await _repository.getAllWallets();
      if (_wallets.isEmpty) {
        // Create default wallet on first run
        await _createDefaultWallet();
        _wallets = await _repository.getAllWallets();
      }
      _selectedWallet = defaultWallet;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load wallets: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addWallet(Wallet wallet) async {
    _setLoading(true);

    try {
      await _repository.insertWallet(wallet);
      _wallets.add(wallet);
      notifyListeners();
    } catch (e) {
      _setError('Failed to add wallet: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateWallet(Wallet wallet) async {
    _setLoading(true);

    try {
      await _repository.updateWallet(wallet);
      final index = _wallets.indexWhere((w) => w.id == wallet.id);
      if (index != -1) {
        _wallets[index] = wallet;
        if (_selectedWallet?.id == wallet.id) {
          _selectedWallet = wallet;
        }
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update wallet: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteWallet(String id) async {
    _setLoading(true);

    try {
      await _repository.deleteWallet(id);
      _wallets.removeWhere((w) => w.id == id);
      if (_selectedWallet?.id == id) {
        _selectedWallet = defaultWallet;
      }
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete wallet: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> setDefaultWallet(String id) async {
    try {
      await _repository.setDefaultWallet(id);
      _wallets = _wallets.map((w) => w.copyWith(isDefault: w.id == id)).toList();
      notifyListeners();
    } catch (e) {
      _setError('Failed to set default wallet: $e');
    }
  }

  Future<void> archiveWallet(String id) async {
    try {
      await _repository.setWalletArchived(id, true);
      final index = _wallets.indexWhere((w) => w.id == id);
      if (index != -1) {
        _wallets[index] = _wallets[index].copyWith(isArchived: true);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to archive wallet: $e');
    }
  }

  Future<void> unarchiveWallet(String id) async {
    try {
      await _repository.setWalletArchived(id, false);
      final index = _wallets.indexWhere((w) => w.id == id);
      if (index != -1) {
        _wallets[index] = _wallets[index].copyWith(isArchived: false);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to unarchive wallet: $e');
    }
  }

  Future<void> transferBetweenWallets({
    required String fromWalletId,
    required String toWalletId,
    required double amount,
    double? exchangeRate,
    String? note,
  }) async {
    _setLoading(true);

    try {
      await _repository.transferBetweenWallets(
        fromWalletId: fromWalletId,
        toWalletId: toWalletId,
        amount: amount,
        exchangeRate: exchangeRate,
        note: note,
      );
      await loadWallets(); // Reload to get updated balances
    } catch (e) {
      _setError('Failed to transfer: $e');
    } finally {
      _setLoading(false);
    }
  }

  void selectWallet(Wallet? wallet) {
    _selectedWallet = wallet;
    notifyListeners();
  }

  Future<void> _createDefaultWallet() async {
    final defaultWallet = Wallet(
      id: 'default',
      name: 'Cash',
      type: WalletType.cash,
      currency: 'USD',
      balance: 0.0,
      colorValue: 0xFF5B8DEF,
      isDefault: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _repository.insertWallet(defaultWallet);
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

  void clearError() {
    _clearError();
    notifyListeners();
  }
}
