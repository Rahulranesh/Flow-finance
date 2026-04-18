import 'package:uuid/uuid.dart';

/// Model representing a connected bank account
class BankAccount {
  final String id;
  final String userId;
  final String provider; // plaid, truelayer, aa_finvu, etc.
  final String providerAccountId;
  final String institutionId;
  final String institutionName;
  final String? institutionLogo;
  final String name;
  final String? officialName;
  final BankAccountType type;
  final BankAccountSubtype subtype;
  final String mask; // Last 4 digits
  final double? currentBalance;
  final double? availableBalance;
  final String? currency;
  final String? limit;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastSyncedAt;
  final SyncStatus syncStatus;
  final String? linkedWalletId;
  final Map<String, dynamic> metadata;

  BankAccount({
    required this.id,
    required this.userId,
    required this.provider,
    required this.providerAccountId,
    required this.institutionId,
    required this.institutionName,
    this.institutionLogo,
    required this.name,
    this.officialName,
    required this.type,
    required this.subtype,
    required this.mask,
    this.currentBalance,
    this.availableBalance,
    this.currency,
    this.limit,
    this.isActive = true,
    required this.createdAt,
    this.lastSyncedAt,
    this.syncStatus = SyncStatus.pending,
    this.linkedWalletId,
    this.metadata = const {},
  });

  BankAccount copyWith({
    String? id,
    String? userId,
    String? provider,
    String? providerAccountId,
    String? institutionId,
    String? institutionName,
    String? institutionLogo,
    String? name,
    String? officialName,
    BankAccountType? type,
    BankAccountSubtype? subtype,
    String? mask,
    double? currentBalance,
    double? availableBalance,
    String? currency,
    String? limit,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastSyncedAt,
    SyncStatus? syncStatus,
    String? linkedWalletId,
    Map<String, dynamic>? metadata,
  }) {
    return BankAccount(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      provider: provider ?? this.provider,
      providerAccountId: providerAccountId ?? this.providerAccountId,
      institutionId: institutionId ?? this.institutionId,
      institutionName: institutionName ?? this.institutionName,
      institutionLogo: institutionLogo ?? this.institutionLogo,
      name: name ?? this.name,
      officialName: officialName ?? this.officialName,
      type: type ?? this.type,
      subtype: subtype ?? this.subtype,
      mask: mask ?? this.mask,
      currentBalance: currentBalance ?? this.currentBalance,
      availableBalance: availableBalance ?? this.availableBalance,
      currency: currency ?? this.currency,
      limit: limit ?? this.limit,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      linkedWalletId: linkedWalletId ?? this.linkedWalletId,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'provider': provider,
      'providerAccountId': providerAccountId,
      'institutionId': institutionId,
      'institutionName': institutionName,
      'institutionLogo': institutionLogo,
      'name': name,
      'officialName': officialName,
      'type': type.name,
      'subtype': subtype.name,
      'mask': mask,
      'currentBalance': currentBalance,
      'availableBalance': availableBalance,
      'currency': currency,
      'limit': limit,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'syncStatus': syncStatus.name,
      'linkedWalletId': linkedWalletId,
      'metadata': metadata,
    };
  }

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'] as String,
      userId: json['userId'] as String,
      provider: json['provider'] as String,
      providerAccountId: json['providerAccountId'] as String,
      institutionId: json['institutionId'] as String,
      institutionName: json['institutionName'] as String,
      institutionLogo: json['institutionLogo'] as String?,
      name: json['name'] as String,
      officialName: json['officialName'] as String?,
      type: BankAccountType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => BankAccountType.depository,
      ),
      subtype: BankAccountSubtype.values.firstWhere(
        (e) => e.name == json['subtype'],
        orElse: () => BankAccountSubtype.checking,
      ),
      mask: json['mask'] as String,
      currentBalance: json['currentBalance'] as double?,
      availableBalance: json['availableBalance'] as double?,
      currency: json['currency'] as String?,
      limit: json['limit'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.parse(json['lastSyncedAt'] as String)
          : null,
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == json['syncStatus'],
        orElse: () => SyncStatus.pending,
      ),
      linkedWalletId: json['linkedWalletId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Create a new bank account
  factory BankAccount.create({
    required String userId,
    required String provider,
    required String providerAccountId,
    required String institutionId,
    required String institutionName,
    String? institutionLogo,
    required String name,
    String? officialName,
    required BankAccountType type,
    required BankAccountSubtype subtype,
    required String mask,
    double? currentBalance,
    double? availableBalance,
    String? currency,
    String? linkedWalletId,
  }) {
    return BankAccount(
      id: const Uuid().v4(),
      userId: userId,
      provider: provider,
      providerAccountId: providerAccountId,
      institutionId: institutionId,
      institutionName: institutionName,
      institutionLogo: institutionLogo,
      name: name,
      officialName: officialName,
      type: type,
      subtype: subtype,
      mask: mask,
      currentBalance: currentBalance,
      availableBalance: availableBalance,
      currency: currency,
      createdAt: DateTime.now(),
      linkedWalletId: linkedWalletId,
    );
  }

  /// Get display name
  String get displayName => officialName ?? name;

  /// Get masked account number
  String get maskedAccount => '****$mask';

  /// Get full display string
  String get fullDisplay => '$institutionName - $displayName ($maskedAccount)';
}

enum BankAccountType {
  depository,
  credit,
  loan,
  investment,
  other,
}

enum BankAccountSubtype {
  checking,
  savings,
  moneyMarket,
  certificateOfDeposit,
  creditCard,
  lineOfCredit,
  mortgage,
  auto,
  student,
  personal,
  retirement,
  brokerage,
  other,
}

enum SyncStatus {
  pending,
  syncing,
  success,
  error,
  disconnected,
}

/// Bank institution information
class BankInstitution {
  final String id;
  final String name;
  final String? logo;
  final String? primaryColor;
  final String? url;
  final List<String> countryCodes;
  final List<String> supportedFeatures;

  BankInstitution({
    required this.id,
    required this.name,
    this.logo,
    this.primaryColor,
    this.url,
    this.countryCodes = const [],
    this.supportedFeatures = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo': logo,
      'primaryColor': primaryColor,
      'url': url,
      'countryCodes': countryCodes,
      'supportedFeatures': supportedFeatures,
    };
  }

  factory BankInstitution.fromJson(Map<String, dynamic> json) {
    return BankInstitution(
      id: json['id'] as String,
      name: json['name'] as String,
      logo: json['logo'] as String?,
      primaryColor: json['primaryColor'] as String?,
      url: json['url'] as String?,
      countryCodes: (json['countryCodes'] as List<dynamic>?)?.cast<String>() ?? [],
      supportedFeatures: (json['supportedFeatures'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}
