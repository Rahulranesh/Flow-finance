import 'package:uuid/uuid.dart';

/// Model representing a transaction from a bank
class BankTransaction {
  final String id;
  final String bankAccountId;
  final String providerTransactionId;
  final String? provider;
  final double amount;
  final String currency;
  final String? isoCurrencyCode;
  final DateTime date;
  final DateTime? authorizedDate;
  final String name;
  final String? merchantName;
  final String? originalDescription;
  final List<String> categories;
  final String? personalFinanceCategory;
  final TransactionLocation? location;
  final PaymentMeta? paymentMeta;
  final String? checkNumber;
  final String? accountOwner;
  final TransactionType transactionType;
  final TransactionStatus status;
  final String? website;
  final String? logoUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? linkedAppTransactionId;
  final bool isReconciled;
  final ReconciliationStatus reconciliationStatus;
  final Map<String, dynamic> metadata;

  BankTransaction({
    required this.id,
    required this.bankAccountId,
    required this.providerTransactionId,
    this.provider,
    required this.amount,
    required this.currency,
    this.isoCurrencyCode,
    required this.date,
    this.authorizedDate,
    required this.name,
    this.merchantName,
    this.originalDescription,
    this.categories = const [],
    this.personalFinanceCategory,
    this.location,
    this.paymentMeta,
    this.checkNumber,
    this.accountOwner,
    required this.transactionType,
    this.status = TransactionStatus.posted,
    this.website,
    this.logoUrl,
    required this.createdAt,
    this.updatedAt,
    this.linkedAppTransactionId,
    this.isReconciled = false,
    this.reconciliationStatus = ReconciliationStatus.pending,
    this.metadata = const {},
  });

  BankTransaction copyWith({
    String? id,
    String? bankAccountId,
    String? providerTransactionId,
    String? provider,
    double? amount,
    String? currency,
    String? isoCurrencyCode,
    DateTime? date,
    DateTime? authorizedDate,
    String? name,
    String? merchantName,
    String? originalDescription,
    List<String>? categories,
    String? personalFinanceCategory,
    TransactionLocation? location,
    PaymentMeta? paymentMeta,
    String? checkNumber,
    String? accountOwner,
    TransactionType? transactionType,
    TransactionStatus? status,
    String? website,
    String? logoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? linkedAppTransactionId,
    bool? isReconciled,
    ReconciliationStatus? reconciliationStatus,
    Map<String, dynamic>? metadata,
  }) {
    return BankTransaction(
      id: id ?? this.id,
      bankAccountId: bankAccountId ?? this.bankAccountId,
      providerTransactionId: providerTransactionId ?? this.providerTransactionId,
      provider: provider ?? this.provider,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      isoCurrencyCode: isoCurrencyCode ?? this.isoCurrencyCode,
      date: date ?? this.date,
      authorizedDate: authorizedDate ?? this.authorizedDate,
      name: name ?? this.name,
      merchantName: merchantName ?? this.merchantName,
      originalDescription: originalDescription ?? this.originalDescription,
      categories: categories ?? this.categories,
      personalFinanceCategory: personalFinanceCategory ?? this.personalFinanceCategory,
      location: location ?? this.location,
      paymentMeta: paymentMeta ?? this.paymentMeta,
      checkNumber: checkNumber ?? this.checkNumber,
      accountOwner: accountOwner ?? this.accountOwner,
      transactionType: transactionType ?? this.transactionType,
      status: status ?? this.status,
      website: website ?? this.website,
      logoUrl: logoUrl ?? this.logoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      linkedAppTransactionId: linkedAppTransactionId ?? this.linkedAppTransactionId,
      isReconciled: isReconciled ?? this.isReconciled,
      reconciliationStatus: reconciliationStatus ?? this.reconciliationStatus,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bankAccountId': bankAccountId,
      'providerTransactionId': providerTransactionId,
      'provider': provider,
      'amount': amount,
      'currency': currency,
      'isoCurrencyCode': isoCurrencyCode,
      'date': date.toIso8601String(),
      'authorizedDate': authorizedDate?.toIso8601String(),
      'name': name,
      'merchantName': merchantName,
      'originalDescription': originalDescription,
      'categories': categories,
      'personalFinanceCategory': personalFinanceCategory,
      'location': location?.toJson(),
      'paymentMeta': paymentMeta?.toJson(),
      'checkNumber': checkNumber,
      'accountOwner': accountOwner,
      'transactionType': transactionType.name,
      'status': status.name,
      'website': website,
      'logoUrl': logoUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'linkedAppTransactionId': linkedAppTransactionId,
      'isReconciled': isReconciled,
      'reconciliationStatus': reconciliationStatus.name,
      'metadata': metadata,
    };
  }

  factory BankTransaction.fromJson(Map<String, dynamic> json) {
    return BankTransaction(
      id: json['id'] as String,
      bankAccountId: json['bankAccountId'] as String,
      providerTransactionId: json['providerTransactionId'] as String,
      provider: json['provider'] as String?,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      isoCurrencyCode: json['isoCurrencyCode'] as String?,
      date: DateTime.parse(json['date'] as String),
      authorizedDate: json['authorizedDate'] != null
          ? DateTime.parse(json['authorizedDate'] as String)
          : null,
      name: json['name'] as String,
      merchantName: json['merchantName'] as String?,
      originalDescription: json['originalDescription'] as String?,
      categories: (json['categories'] as List<dynamic>?)?.cast<String>() ?? [],
      personalFinanceCategory: json['personalFinanceCategory'] as String?,
      location: json['location'] != null
          ? TransactionLocation.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      paymentMeta: json['paymentMeta'] != null
          ? PaymentMeta.fromJson(json['paymentMeta'] as Map<String, dynamic>)
          : null,
      checkNumber: json['checkNumber'] as String?,
      accountOwner: json['accountOwner'] as String?,
      transactionType: TransactionType.values.firstWhere(
        (e) => e.name == json['transactionType'],
        orElse: () => TransactionType.debit,
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TransactionStatus.posted,
      ),
      website: json['website'] as String?,
      logoUrl: json['logoUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      linkedAppTransactionId: json['linkedAppTransactionId'] as String?,
      isReconciled: json['isReconciled'] as bool? ?? false,
      reconciliationStatus: ReconciliationStatus.values.firstWhere(
        (e) => e.name == json['reconciliationStatus'],
        orElse: () => ReconciliationStatus.pending,
      ),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Create from Plaid transaction
  factory BankTransaction.fromPlaid(
    Map<String, dynamic> plaidData,
    String bankAccountId,
    String provider,
  ) {
    return BankTransaction(
      id: const Uuid().v4(),
      bankAccountId: bankAccountId,
      providerTransactionId: plaidData['transaction_id'] as String,
      provider: provider,
      amount: (plaidData['amount'] as num).toDouble(),
      currency: plaidData['iso_currency_code'] as String? ?? 'USD',
      isoCurrencyCode: plaidData['iso_currency_code'] as String?,
      date: DateTime.parse(plaidData['date'] as String),
      authorizedDate: plaidData['authorized_date'] != null
          ? DateTime.parse(plaidData['authorized_date'] as String)
          : null,
      name: plaidData['name'] as String,
      merchantName: plaidData['merchant_name'] as String?,
      originalDescription: plaidData['original_description'] as String?,
      categories: (plaidData['category'] as List<dynamic>?)?.cast<String>() ?? [],
      personalFinanceCategory: plaidData['personal_finance_category']?['primary'] as String?,
      location: plaidData['location'] != null
          ? TransactionLocation.fromPlaid(plaidData['location'] as Map<String, dynamic>)
          : null,
      paymentMeta: plaidData['payment_meta'] != null
          ? PaymentMeta.fromPlaid(plaidData['payment_meta'] as Map<String, dynamic>)
          : null,
      checkNumber: plaidData['check_number'] as String?,
      transactionType: _parseTransactionType(plaidData['transaction_type'] as String?),
      website: plaidData['website'] as String?,
      logoUrl: plaidData['logo_url'] as String?,
      createdAt: DateTime.now(),
    );
  }

  /// Create from TrueLayer transaction
  factory BankTransaction.fromTrueLayer(
    Map<String, dynamic> tlData,
    String bankAccountId,
  ) {
    final amount = (tlData['amount'] as num).toDouble();
    
    return BankTransaction(
      id: const Uuid().v4(),
      bankAccountId: bankAccountId,
      providerTransactionId: tlData['transaction_id'] as String,
      provider: 'truelayer',
      amount: amount.abs(),
      currency: tlData['currency'] as String,
      date: DateTime.parse(tlData['timestamp'] as String),
      name: tlData['description'] as String,
      merchantName: tlData['merchant_name'] as String?,
      transactionType: amount < 0 ? TransactionType.debit : TransactionType.credit,
      status: tlData['status'] == 'pending'
          ? TransactionStatus.pending
          : TransactionStatus.posted,
      createdAt: DateTime.now(),
    );
  }

  static TransactionType _parseTransactionType(String? type) {
    switch (type?.toLowerCase()) {
      case 'credit':
        return TransactionType.credit;
      case 'debit':
      default:
        return TransactionType.debit;
    }
  }

  /// Get signed amount (negative for debits)
  double get signedAmount =>
      transactionType == TransactionType.debit ? -amount.abs() : amount.abs();

  /// Get display amount with sign
  String get displayAmount {
    final sign = transactionType == TransactionType.debit ? '-' : '+';
    return '$sign${currency} ${amount.toStringAsFixed(2)}';
  }

  /// Get primary category
  String? get primaryCategory => categories.isNotEmpty ? categories.first : null;

  /// Check if this is a pending transaction
  bool get isPending => status == TransactionStatus.pending;

  /// Get clean description
  String get cleanDescription =>
      merchantName ?? name.replaceAll(RegExp(r'\s+'), ' ').trim();
}

enum TransactionType {
  credit,
  debit,
}

enum TransactionStatus {
  posted,
  pending,
  cancelled,
}

enum ReconciliationStatus {
  pending,
  matched,
  manual,
  ignored,
}

/// Transaction location data
class TransactionLocation {
  final String? address;
  final String? city;
  final String? region;
  final String? postalCode;
  final String? country;
  final double? lat;
  final double? lon;
  final String? storeNumber;

  TransactionLocation({
    this.address,
    this.city,
    this.region,
    this.postalCode,
    this.country,
    this.lat,
    this.lon,
    this.storeNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'city': city,
      'region': region,
      'postalCode': postalCode,
      'country': country,
      'lat': lat,
      'lon': lon,
      'storeNumber': storeNumber,
    };
  }

  factory TransactionLocation.fromJson(Map<String, dynamic> json) {
    return TransactionLocation(
      address: json['address'] as String?,
      city: json['city'] as String?,
      region: json['region'] as String?,
      postalCode: json['postalCode'] as String?,
      country: json['country'] as String?,
      lat: json['lat'] as double?,
      lon: json['lon'] as double?,
      storeNumber: json['storeNumber'] as String?,
    );
  }

  factory TransactionLocation.fromPlaid(Map<String, dynamic> json) {
    return TransactionLocation(
      address: json['address'] as String?,
      city: json['city'] as String?,
      region: json['region'] as String?,
      postalCode: json['postal_code'] as String?,
      country: json['country'] as String?,
      lat: json['lat'] as double?,
      lon: json['lon'] as double?,
      storeNumber: json['store_number'] as String?,
    );
  }
}

/// Payment metadata
class PaymentMeta {
  final String? referenceNumber;
  final String? ppdId;
  final String? payee;
  final String? payer;
  final String? paymentMethod;
  final String? paymentProcessor;
  final String? reason;

  PaymentMeta({
    this.referenceNumber,
    this.ppdId,
    this.payee,
    this.payer,
    this.paymentMethod,
    this.paymentProcessor,
    this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'referenceNumber': referenceNumber,
      'ppdId': ppdId,
      'payee': payee,
      'payer': payer,
      'paymentMethod': paymentMethod,
      'paymentProcessor': paymentProcessor,
      'reason': reason,
    };
  }

  factory PaymentMeta.fromJson(Map<String, dynamic> json) {
    return PaymentMeta(
      referenceNumber: json['referenceNumber'] as String?,
      ppdId: json['ppdId'] as String?,
      payee: json['payee'] as String?,
      payer: json['payer'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      paymentProcessor: json['paymentProcessor'] as String?,
      reason: json['reason'] as String?,
    );
  }

  factory PaymentMeta.fromPlaid(Map<String, dynamic> json) {
    return PaymentMeta(
      referenceNumber: json['reference_number'] as String?,
      ppdId: json['ppd_id'] as String?,
      payee: json['payee'] as String?,
      payer: json['payer'] as String?,
      paymentMethod: json['payment_method'] as String?,
      paymentProcessor: json['payment_processor'] as String?,
      reason: json['reason'] as String?,
    );
  }
}

/// Sync result for batch operations
class SyncResult {
  final bool success;
  final int transactionsAdded;
  final int transactionsUpdated;
  final List<String> errors;
  final DateTime syncTime;
  final String? nextCursor;

  SyncResult({
    required this.success,
    this.transactionsAdded = 0,
    this.transactionsUpdated = 0,
    this.errors = const [],
    required this.syncTime,
    this.nextCursor,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get hasChanges => transactionsAdded > 0 || transactionsUpdated > 0;
}
