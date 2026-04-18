import 'package:flutter/material.dart';

/// Types of wallets/accounts
enum WalletType {
  cash,
  bank,
  creditCard,
  savings,
  investment,
  digital,
  other,
}

/// Extension to get display name for wallet type
extension WalletTypeExtension on WalletType {
  String get displayName {
    switch (this) {
      case WalletType.cash:
        return 'Cash';
      case WalletType.bank:
        return 'Bank Account';
      case WalletType.creditCard:
        return 'Credit Card';
      case WalletType.savings:
        return 'Savings';
      case WalletType.investment:
        return 'Investment';
      case WalletType.digital:
        return 'Digital Wallet';
      case WalletType.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case WalletType.cash:
        return Icons.money;
      case WalletType.bank:
        return Icons.account_balance;
      case WalletType.creditCard:
        return Icons.credit_card;
      case WalletType.savings:
        return Icons.savings;
      case WalletType.investment:
        return Icons.trending_up;
      case WalletType.digital:
        return Icons.phone_android;
      case WalletType.other:
        return Icons.wallet;
    }
  }
}

/// Wallet model representing a financial account
@immutable
class Wallet {
  final String id;
  final String name;
  final WalletType type;
  final String currency;
  final double balance;
  final int colorValue;
  final String? iconName;
  final bool isDefault;
  final bool isArchived;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    this.balance = 0.0,
    required this.colorValue,
    this.iconName,
    this.isDefault = false,
    this.isArchived = false,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy of this wallet with modified fields
  Wallet copyWith({
    String? id,
    String? name,
    WalletType? type,
    String? currency,
    double? balance,
    int? colorValue,
    String? iconName,
    bool? isDefault,
    bool? isArchived,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      balance: balance ?? this.balance,
      colorValue: colorValue ?? this.colorValue,
      iconName: iconName ?? this.iconName,
      isDefault: isDefault ?? this.isDefault,
      isArchived: isArchived ?? this.isArchived,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'currency': currency,
      'balance': balance,
      'colorValue': colorValue,
      'iconName': iconName,
      'isDefault': isDefault,
      'isArchived': isArchived,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] as String,
      name: json['name'] as String,
      type: WalletType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => WalletType.cash,
      ),
      currency: json['currency'] as String,
      balance: (json['balance'] as num).toDouble(),
      colorValue: json['colorValue'] as int,
      iconName: json['iconName'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Get color from color value
  Color get color => Color(colorValue);

  /// Get icon data
  IconData get icon => iconName != null
      ? _getIconFromName(iconName!)
      : type.icon;

  static IconData _getIconFromName(String name) {
    // Map common icon names to IconData
    switch (name) {
      case 'money':
        return Icons.money;
      case 'account_balance':
        return Icons.account_balance;
      case 'credit_card':
        return Icons.credit_card;
      case 'savings':
        return Icons.savings;
      case 'trending_up':
        return Icons.trending_up;
      case 'phone_android':
        return Icons.phone_android;
      case 'wallet':
        return Icons.wallet;
      default:
        return Icons.account_balance_wallet;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Wallet && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Wallet(id: $id, name: $name, type: ${type.displayName}, balance: $balance $currency)';
  }
}

/// Wallet transfer model for recording transfers between wallets
@immutable
class WalletTransfer {
  final String id;
  final String fromWalletId;
  final String toWalletId;
  final double amount;
  final double? exchangeRate;
  final String? note;
  final DateTime date;
  final DateTime createdAt;

  const WalletTransfer({
    required this.id,
    required this.fromWalletId,
    required this.toWalletId,
    required this.amount,
    this.exchangeRate,
    this.note,
    required this.date,
    required this.createdAt,
  });

  /// Create a copy of this transfer with modified fields
  WalletTransfer copyWith({
    String? id,
    String? fromWalletId,
    String? toWalletId,
    double? amount,
    double? exchangeRate,
    String? note,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return WalletTransfer(
      id: id ?? this.id,
      fromWalletId: fromWalletId ?? this.fromWalletId,
      toWalletId: toWalletId ?? this.toWalletId,
      amount: amount ?? this.amount,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      note: note ?? this.note,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromWalletId': fromWalletId,
      'toWalletId': toWalletId,
      'amount': amount,
      'exchangeRate': exchangeRate,
      'note': note,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory WalletTransfer.fromJson(Map<String, dynamic> json) {
    return WalletTransfer(
      id: json['id'] as String,
      fromWalletId: json['fromWalletId'] as String,
      toWalletId: json['toWalletId'] as String,
      amount: (json['amount'] as num).toDouble(),
      exchangeRate: json['exchangeRate'] != null
          ? (json['exchangeRate'] as num).toDouble()
          : null,
      note: json['note'] as String?,
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Calculate converted amount based on exchange rate
  double get convertedAmount {
    if (exchangeRate != null) {
      return amount * exchangeRate!;
    }
    return amount;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WalletTransfer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Predefined wallet colors
class WalletColors {
  static const List<int> colors = [
    0xFF5B8DEF, // Blue
    0xFF6DD230, // Green
    0xFFF5A623, // Orange
    0xFFE02020, // Red
    0xFF9013FE, // Purple
    0xFF50E3C2, // Teal
    0xFFB8E986, // Light Green
    0xFFFF7A45, // Coral
    0xFF7ED321, // Lime
    0xFF4A90E2, // Royal Blue
    0xFFBD10E0, // Magenta
    0xFFFFC107, // Amber
  ];

  static Color getRandomColor() {
    return Color(colors[DateTime.now().millisecond % colors.length]);
  }
}
