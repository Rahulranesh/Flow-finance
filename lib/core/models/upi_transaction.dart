import 'package:uuid/uuid.dart';

/// Model representing a UPI transaction
class UPITransaction {
  final String id;
  final String utrNumber; // Unique Transaction Reference
  final String upiId;
  final String? payerUpiId;
  final String? payeeUpiId;
  final double amount;
  final UPITransactionType type; // debit or credit
  final DateTime timestamp;
  final String? description;
  final String? bankReference;
  final String sourceApp; // GPay, PhonePe, Paytm, etc.
  final String? accountNumber;
  final String? bankName;
  final String? linkedTransactionId; // Link to app transaction
  final SyncStatus syncStatus;
  final String? rawSms;
  final String? senderId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UPITransaction({
    required this.id,
    required this.utrNumber,
    required this.upiId,
    this.payerUpiId,
    this.payeeUpiId,
    required this.amount,
    required this.type,
    required this.timestamp,
    this.description,
    this.bankReference,
    required this.sourceApp,
    this.accountNumber,
    this.bankName,
    this.linkedTransactionId,
    this.syncStatus = SyncStatus.pending,
    this.rawSms,
    this.senderId,
    required this.createdAt,
    this.updatedAt,
  });

  UPITransaction copyWith({
    String? id,
    String? utrNumber,
    String? upiId,
    String? payerUpiId,
    String? payeeUpiId,
    double? amount,
    UPITransactionType? type,
    DateTime? timestamp,
    String? description,
    String? bankReference,
    String? sourceApp,
    String? accountNumber,
    String? bankName,
    String? linkedTransactionId,
    SyncStatus? syncStatus,
    String? rawSms,
    String? senderId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UPITransaction(
      id: id ?? this.id,
      utrNumber: utrNumber ?? this.utrNumber,
      upiId: upiId ?? this.upiId,
      payerUpiId: payerUpiId ?? this.payerUpiId,
      payeeUpiId: payeeUpiId ?? this.payeeUpiId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      description: description ?? this.description,
      bankReference: bankReference ?? this.bankReference,
      sourceApp: sourceApp ?? this.sourceApp,
      accountNumber: accountNumber ?? this.accountNumber,
      bankName: bankName ?? this.bankName,
      linkedTransactionId: linkedTransactionId ?? this.linkedTransactionId,
      syncStatus: syncStatus ?? this.syncStatus,
      rawSms: rawSms ?? this.rawSms,
      senderId: senderId ?? this.senderId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'utrNumber': utrNumber,
      'upiId': upiId,
      'payerUpiId': payerUpiId,
      'payeeUpiId': payeeUpiId,
      'amount': amount,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'description': description,
      'bankReference': bankReference,
      'sourceApp': sourceApp,
      'accountNumber': accountNumber,
      'bankName': bankName,
      'linkedTransactionId': linkedTransactionId,
      'syncStatus': syncStatus.name,
      'rawSms': rawSms,
      'senderId': senderId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory UPITransaction.fromJson(Map<String, dynamic> json) {
    return UPITransaction(
      id: json['id'] as String,
      utrNumber: json['utrNumber'] as String,
      upiId: json['upiId'] as String,
      payerUpiId: json['payerUpiId'] as String?,
      payeeUpiId: json['payeeUpiId'] as String?,
      amount: (json['amount'] as num).toDouble(),
      type: UPITransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => UPITransactionType.debit,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      description: json['description'] as String?,
      bankReference: json['bankReference'] as String?,
      sourceApp: json['sourceApp'] as String,
      accountNumber: json['accountNumber'] as String?,
      bankName: json['bankName'] as String?,
      linkedTransactionId: json['linkedTransactionId'] as String?,
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == json['syncStatus'],
        orElse: () => SyncStatus.pending,
      ),
      rawSms: json['rawSms'] as String?,
      senderId: json['senderId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Create a new UPI transaction
  factory UPITransaction.create({
    required String utrNumber,
    required String upiId,
    String? payerUpiId,
    String? payeeUpiId,
    required double amount,
    required UPITransactionType type,
    required DateTime timestamp,
    String? description,
    String? bankReference,
    required String sourceApp,
    String? accountNumber,
    String? bankName,
    String? rawSms,
    String? senderId,
  }) {
    return UPITransaction(
      id: const Uuid().v4(),
      utrNumber: utrNumber,
      upiId: upiId,
      payerUpiId: payerUpiId,
      payeeUpiId: payeeUpiId,
      amount: amount,
      type: type,
      timestamp: timestamp,
      description: description,
      bankReference: bankReference,
      sourceApp: sourceApp,
      accountNumber: accountNumber,
      bankName: bankName,
      rawSms: rawSms,
      senderId: senderId,
      createdAt: DateTime.now(),
    );
  }

  /// Get signed amount (negative for debits)
  double get signedAmount => type == UPITransactionType.debit ? -amount : amount;

  /// Get display amount with sign
  String get displayAmount {
    final sign = type == UPITransactionType.debit ? '-' : '+';
    return '$sign₹${amount.toStringAsFixed(2)}';
  }

  /// Get counterparty UPI ID
  String? get counterpartyUpiId => type == UPITransactionType.debit ? payeeUpiId : payerUpiId;

  /// Check if this is a debit transaction
  bool get isDebit => type == UPITransactionType.debit;

  /// Check if this is a credit transaction
  bool get isCredit => type == UPITransactionType.credit;

  /// Get short UPI ID (without @)
  String get shortUpiId {
    final parts = upiId.split('@');
    return parts.isNotEmpty ? parts[0] : upiId;
  }

  /// Get UPI handle (provider)
  String? get upiHandle {
    final parts = upiId.split('@');
    return parts.length > 1 ? parts[1] : null;
  }

  /// Mark as synced
  UPITransaction markSynced(String? transactionId) {
    return copyWith(
      syncStatus: SyncStatus.synced,
      linkedTransactionId: transactionId,
      updatedAt: DateTime.now(),
    );
  }

  /// Mark as failed
  UPITransaction markFailed() {
    return copyWith(
      syncStatus: SyncStatus.failed,
      updatedAt: DateTime.now(),
    );
  }

  /// Mark as ignored
  UPITransaction markIgnored() {
    return copyWith(
      syncStatus: SyncStatus.ignored,
      updatedAt: DateTime.now(),
    );
  }
}

enum UPITransactionType {
  debit,
  credit,
}

enum SyncStatus {
  pending,
  synced,
  failed,
  ignored,
}

/// UPI transaction summary/statistics
class UPITransactionSummary {
  final int totalTransactions;
  final int debitCount;
  final int creditCount;
  final double totalDebit;
  final double totalCredit;
  final double netAmount;
  final Map<String, int> sourceAppDistribution;
  final Map<String, int> bankDistribution;
  final DateTime periodStart;
  final DateTime periodEnd;

  UPITransactionSummary({
    required this.totalTransactions,
    required this.debitCount,
    required this.creditCount,
    required this.totalDebit,
    required this.totalCredit,
    required this.netAmount,
    required this.sourceAppDistribution,
    required this.bankDistribution,
    required this.periodStart,
    required this.periodEnd,
  });

  factory UPITransactionSummary.fromTransactions(
    List<UPITransaction> transactions, {
    DateTime? periodStart,
    DateTime? periodEnd,
  }) {
    int debitCount = 0;
    int creditCount = 0;
    double totalDebit = 0;
    double totalCredit = 0;
    final sourceAppDist = <String, int>{};
    final bankDist = <String, int>{};

    for (final tx in transactions) {
      if (tx.type == UPITransactionType.debit) {
        debitCount++;
        totalDebit += tx.amount;
      } else {
        creditCount++;
        totalCredit += tx.amount;
      }

      sourceAppDist[tx.sourceApp] = (sourceAppDist[tx.sourceApp] ?? 0) + 1;
      
      if (tx.bankName != null) {
        bankDist[tx.bankName!] = (bankDist[tx.bankName!] ?? 0) + 1;
      }
    }

    return UPITransactionSummary(
      totalTransactions: transactions.length,
      debitCount: debitCount,
      creditCount: creditCount,
      totalDebit: totalDebit,
      totalCredit: totalCredit,
      netAmount: totalCredit - totalDebit,
      sourceAppDistribution: sourceAppDist,
      bankDistribution: bankDist,
      periodStart: periodStart ?? DateTime.now().subtract(const Duration(days: 30)),
      periodEnd: periodEnd ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalTransactions': totalTransactions,
      'debitCount': debitCount,
      'creditCount': creditCount,
      'totalDebit': totalDebit,
      'totalCredit': totalCredit,
      'netAmount': netAmount,
      'sourceAppDistribution': sourceAppDistribution,
      'bankDistribution': bankDistribution,
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
    };
  }
}

/// UPI app information
class UPIApp {
  final String id;
  final String name;
  final String packageName;
  final String? logoAsset;
  final bool supportsSms;
  final bool supportsNotifications;
  final bool supportsDeepLink;

  UPIApp({
    required this.id,
    required this.name,
    required this.packageName,
    this.logoAsset,
    this.supportsSms = true,
    this.supportsNotifications = true,
    this.supportsDeepLink = false,
  });

  static final List<UPIApp> supportedApps = [
    UPIApp(
      id: 'gpay',
      name: 'Google Pay',
      packageName: 'com.google.android.apps.nbu.paisa.user',
      supportsDeepLink: true,
    ),
    UPIApp(
      id: 'phonepe',
      name: 'PhonePe',
      packageName: 'com.phonepe.app',
      supportsDeepLink: true,
    ),
    UPIApp(
      id: 'paytm',
      name: 'Paytm',
      packageName: 'net.one97.paytm',
      supportsDeepLink: true,
    ),
    UPIApp(
      id: 'amazonpay',
      name: 'Amazon Pay',
      packageName: 'in.amazon.mShop.android.shopping',
      supportsDeepLink: false,
    ),
    UPIApp(
      id: 'bhim',
      name: 'BHIM',
      packageName: 'in.org.npci.upiapp',
      supportsDeepLink: true,
    ),
    UPIApp(
      id: 'cred',
      name: 'CRED',
      packageName: 'com.dreamplug.androidapp',
      supportsDeepLink: false,
    ),
  ];
}
