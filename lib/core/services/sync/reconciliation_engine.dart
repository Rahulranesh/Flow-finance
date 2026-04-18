import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../models/bank_account.dart' as bank;
import '../../models/bank_transaction.dart' as bank_tx;
import '../../models/upi_transaction.dart' as upi;
import '../../../data/models/transaction_model.dart' as app;

/// Engine for reconciling bank transactions with app transactions
class ReconciliationEngine {
  static final ReconciliationEngine _instance = ReconciliationEngine._internal();
  factory ReconciliationEngine() => _instance;
  ReconciliationEngine._internal();

  /// Reconcile all pending transactions for a user
  Future<ReconciliationResult> reconcileAll(String userId) async {
    // Implementation would:
    // 1. Get all pending bank transactions
    // 2. Get all app transactions
    // 3. Find matches
    // 4. Auto-categorize unmatched transactions
    // 5. Create app transactions for new bank transactions

    return ReconciliationResult(
      success: true,
      matched: 0,
      created: 0,
      ignored: 0,
      timestamp: DateTime.now(),
    );
  }

  /// Find matches between bank and app transactions
  List<TransactionMatch> findMatches(
    List<bank_tx.BankTransaction> bankTransactions,
    List<app.Transaction> appTransactions,
  ) {
    final matches = <TransactionMatch>[];

    for (final bankTx in bankTransactions.where((tx) => !tx.isReconciled)) {
      // Look for matching app transaction
      final match = _findBestMatch(bankTx, appTransactions);
      
      if (match != null) {
        matches.add(TransactionMatch(
          bankTransaction: bankTx,
          appTransaction: match,
          confidence: _calculateMatchConfidence(bankTx, match),
          reason: 'Amount and date match',
        ));
      }
    }

    return matches;
  }

  /// Find the best matching app transaction
  app.Transaction? _findBestMatch(bank_tx.BankTransaction bankTx, List<app.Transaction> appTransactions) {
    app.Transaction? bestMatch;
    double bestScore = 0;

    for (final appTx in appTransactions) {
      final score = _calculateMatchScore(bankTx, appTx);
      
      if (score > bestScore && score > 0.7) { // 70% threshold
        bestScore = score;
        bestMatch = appTx;
      }
    }

    return bestMatch;
  }

  /// Calculate match score between bank and app transaction
  double _calculateMatchScore(bank_tx.BankTransaction bankTx, app.Transaction appTx) {
    double score = 0;

    // Amount match (40% weight)
    if ((bankTx.amount - appTx.amount).abs() < 0.01) {
      score += 0.4;
    } else if ((bankTx.amount - appTx.amount).abs() < 1.0) {
      score += 0.2;
    }

    // Date match (30% weight)
    final dateDiff = bankTx.date.difference(appTx.date).inDays.abs();
    if (dateDiff == 0) {
      score += 0.3;
    } else if (dateDiff <= 1) {
      score += 0.15;
    }

    // Name/Description match (20% weight)
    if (_isNameSimilar(bankTx.cleanDescription, appTx.title)) {
      score += 0.2;
    }

    // Type match (10% weight)
    final bankType = bankTx.transactionType == bank_tx.TransactionType.debit
        ? app.TransactionType.expense
        : app.TransactionType.income;
    if (bankType == appTx.type) {
      score += 0.1;
    }

    return score;
  }

  /// Calculate confidence level for a match
  double _calculateMatchConfidence(bank_tx.BankTransaction bankTx, app.Transaction appTx) {
    return _calculateMatchScore(bankTx, appTx);
  }

  /// Check if names are similar
  bool _isNameSimilar(String name1, String name2) {
    final normalized1 = _normalizeName(name1);
    final normalized2 = _normalizeName(name2);

    // Exact match
    if (normalized1 == normalized2) return true;

    // Contains match
    if (normalized1.contains(normalized2) || normalized2.contains(normalized1)) {
      return true;
    }

    // Word overlap
    final words1 = normalized1.split(' ').toSet();
    final words2 = normalized2.split(' ').toSet();
    final intersection = words1.intersection(words2);
    
    return intersection.length >= words1.length * 0.5 ||
           intersection.length >= words2.length * 0.5;
  }

  /// Normalize name for comparison
  String _normalizeName(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Suggest category based on bank transaction
  String suggestCategory(bank_tx.BankTransaction transaction) {
    // Check categories from bank
    if (transaction.personalFinanceCategory != null) {
      return _mapPlaidCategory(transaction.personalFinanceCategory!);
    }

    // Check merchant name
    if (transaction.merchantName != null) {
      final category = _categorizeByMerchant(transaction.merchantName!);
      if (category != null) return category;
    }

    // Check transaction name
    final category = _categorizeByName(transaction.name);
    if (category != null) return category;

    // Default based on type
    return transaction.transactionType == bank_tx.TransactionType.debit
        ? 'Uncategorized'
        : 'Income';
  }

  /// Map Plaid category to app category
  String _mapPlaidCategory(String plaidCategory) {
    final mapping = {
      'FOOD_AND_DRINK': 'Food',
      'TRANSPORTATION': 'Transport',
      'TRAVEL': 'Travel',
      'ENTERTAINMENT': 'Entertainment',
      'SHOPPING': 'Shopping',
      'HEALTHCARE': 'Health',
      'PERSONAL_CARE': 'Personal',
      'EDUCATION': 'Education',
      'BILLS_AND_UTILITIES': 'Bills',
      'RENT_AND_UTILITIES': 'Rent',
      'INCOME': 'Income',
      'TRANSFER_IN': 'Transfer',
      'TRANSFER_OUT': 'Transfer',
      'LOAN_PAYMENTS': 'Loan',
      'BANK_FEES': 'Fees',
    };

    return mapping[plaidCategory] ?? 'Uncategorized';
  }

  /// Categorize by merchant name
  String? _categorizeByMerchant(String merchant) {
    final lower = merchant.toLowerCase();

    final patterns = {
      'Food': ['restaurant', 'cafe', 'coffee', 'mcdonalds', 'starbucks', 'doordash', 'uber eats', 'swiggy', 'zomato'],
      'Transport': ['uber', 'lyft', 'ola', 'rapido', 'fuel', 'petrol', 'diesel', 'metro', 'bus'],
      'Shopping': ['amazon', 'flipkart', 'myntra', 'ajio', 'meesho', 'snapdeal'],
      'Entertainment': ['netflix', 'spotify', 'prime video', 'hotstar', 'sony liv', 'zee5'],
      'Bills': ['electricity', 'water', 'gas', 'broadband', 'mobile', 'recharge'],
      'Health': ['pharmacy', 'hospital', 'clinic', 'medical', 'apollo', 'medplus'],
    };

    for (final entry in patterns.entries) {
      for (final pattern in entry.value) {
        if (lower.contains(pattern)) return entry.key;
      }
    }

    return null;
  }

  /// Categorize by transaction name
  String? _categorizeByName(String name) {
    return _categorizeByMerchant(name);
  }

  /// Suggest wallet based on bank account
  String? suggestWallet(bank.BankAccount bankAccount, List<dynamic> wallets) {
    // Check if account is already linked
    if (bankAccount.linkedWalletId != null) {
      return bankAccount.linkedWalletId;
    }

    // Try to match by currency
    final matchingWallets = wallets.where((w) {
      final walletCurrency = (w as dynamic).currency as String?;
      return walletCurrency == bankAccount.currency;
    }).toList();

    if (matchingWallets.length == 1) {
      return (matchingWallets.first as dynamic).id as String;
    }

    // Try to match by account type
    if (bankAccount.type == bank.BankAccountType.depository) {
      final checkingWallets = wallets.where((w) {
        final name = (w as dynamic).name as String? ?? '';
        return name.toLowerCase().contains('checking') ||
               name.toLowerCase().contains('bank') ||
               name.toLowerCase().contains('savings');
      });
      if (checkingWallets.isNotEmpty) {
        return (checkingWallets.first as dynamic).id as String;
      }
    }

    // Default to first wallet
    return wallets.isNotEmpty ? (wallets.first as dynamic).id as String : null;
  }

  /// Create app transaction from bank transaction
  Future<app.Transaction> createAppTransaction(bank_tx.BankTransaction bankTx) async {
    final category = suggestCategory(bankTx);
    
    return app.Transaction(
      id: const Uuid().v4(),
      amount: bankTx.amount,
      title: bankTx.cleanDescription,
      note: bankTx.originalDescription,
      category: category,
      type: bankTx.transactionType == bank_tx.TransactionType.debit
          ? app.TransactionType.expense
          : app.TransactionType.income,
      date: bankTx.date,
      walletId: bankTx.linkedAppTransactionId, // Should be wallet ID
    );
  }

  /// Create app transaction from UPI transaction
  Future<app.Transaction?> createAppTransactionFromUPITx(upi.UPITransaction upiTx) async {
    // Determine category based on UPI ID patterns
    String category = 'Uncategorized';
    final upiId = upiTx.counterpartyUpiId?.toLowerCase() ?? '';
    
    if (upiId.contains('food') || upiId.contains('restaurant') || upiId.contains('swiggy') || upiId.contains('zomato')) {
      category = 'Food';
    } else if (upiId.contains('uber') || upiId.contains('ola') || upiId.contains('rapido')) {
      category = 'Transport';
    } else if (upiId.contains('amazon') || upiId.contains('flipkart')) {
      category = 'Shopping';
    } else if (upiId.contains('recharge') || upiId.contains('bill')) {
      category = 'Bills';
    }

    return app.Transaction(
      id: const Uuid().v4(),
      amount: upiTx.amount,
      title: upiTx.description ?? upiTx.upiId,
      note: 'UPI ${upiTx.utrNumber}',
      category: category,
      type: upiTx.type == upi.UPITransactionType.debit
          ? app.TransactionType.expense
          : app.TransactionType.income,
      date: upiTx.timestamp,
      walletId: null, // Will be set based on user preference
    );
  }

  /// Apply smart categorization rules
  Future<void> applySmartCategorization(List<bank_tx.BankTransaction> transactions) async {
    for (final tx in transactions) {
      if (tx.categories.isEmpty) {
        final suggestedCategory = suggestCategory(tx);
        // Update transaction with suggested category
        // Implementation would update in database
      }
    }
  }

  /// Batch reconcile transactions
  Future<ReconciliationResult> batchReconcile(
    List<TransactionMatch> matches,
    bool autoCreateUnmatched,
  ) async {
    int matched = 0;
    int created = 0;
    int ignored = 0;

    for (final match in matches) {
      if (match.confidence > 0.9) {
        // High confidence - auto reconcile
        await _reconcileMatch(match);
        matched++;
      }
    }

    if (autoCreateUnmatched) {
      // Create transactions for unmatched bank transactions
      // Implementation would create app transactions
    }

    return ReconciliationResult(
      success: true,
      matched: matched,
      created: created,
      ignored: ignored,
      timestamp: DateTime.now(),
    );
  }

  Future<void> _reconcileMatch(TransactionMatch match) async {
    // Update bank transaction as reconciled
    // Link to app transaction
    // Implementation would update database
  }
}

/// Transaction match result
class TransactionMatch {
  final bank_tx.BankTransaction bankTransaction;
  final app.Transaction appTransaction;
  final double confidence;
  final String reason;

  TransactionMatch({
    required this.bankTransaction,
    required this.appTransaction,
    required this.confidence,
    required this.reason,
  });

  bool get isHighConfidence => confidence >= 0.9;
  bool get isMediumConfidence => confidence >= 0.7 && confidence < 0.9;
  bool get isLowConfidence => confidence < 0.7;
}

/// Reconciliation result
class ReconciliationResult {
  final bool success;
  final int matched;
  final int created;
  final int ignored;
  final DateTime timestamp;
  final String? error;

  ReconciliationResult({
    required this.success,
    required this.matched,
    required this.created,
    required this.ignored,
    required this.timestamp,
    this.error,
  });
}
