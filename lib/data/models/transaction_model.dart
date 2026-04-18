import 'package:flutter/material.dart';

/// Transaction model representing a financial transaction
@immutable
class Transaction {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String category;
  final DateTime date;
  final String? note;
  final String? paymentMethod;
  final List<String>? tags;
  final bool isRecurring;
  final String? recurringId;

  const Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.note,
    this.paymentMethod,
    this.tags,
    this.isRecurring = false,
    this.recurringId,
  });

  /// Create a copy of this transaction with modified fields
  Transaction copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    String? category,
    DateTime? date,
    String? note,
    String? paymentMethod,
    List<String>? tags,
    bool? isRecurring,
    String? recurringId,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      tags: tags ?? this.tags,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringId: recurringId ?? this.recurringId,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.name,
      'category': category,
      'date': date.toIso8601String(),
      'note': note,
      'paymentMethod': paymentMethod,
      'tags': tags,
      'isRecurring': isRecurring,
      'recurringId': recurringId,
    };
  }

  /// Create from JSON
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.expense,
      ),
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurringId: json['recurringId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Transaction(id: $id, title: $title, amount: $amount, type: $type)';
  }
}

enum TransactionType {
  income,
  expense,
  transfer,
}

/// Category model
@immutable
class Category {
  final String id;
  final String name;
  final String iconName;
  final Color color;
  final double? budgetLimit;
  final bool isDefault;

  const Category({
    required this.id,
    required this.name,
    required this.iconName,
    required this.color,
    this.budgetLimit,
    this.isDefault = false,
  });

  /// Predefined categories
  static List<Category> get defaultCategories => [
        const Category(
          id: 'food',
          name: 'Food & Dining',
          iconName: 'restaurant',
          color: Color(0xFFF59E0B),
          isDefault: true,
        ),
        const Category(
          id: 'transport',
          name: 'Transportation',
          iconName: 'directions_car',
          color: Color(0xFF3B82F6),
          isDefault: true,
        ),
        const Category(
          id: 'shopping',
          name: 'Shopping',
          iconName: 'shopping_bag',
          color: Color(0xFFEC4899),
          isDefault: true,
        ),
        const Category(
          id: 'entertainment',
          name: 'Entertainment',
          iconName: 'movie',
          color: Color(0xFF8B5CF6),
          isDefault: true,
        ),
        const Category(
          id: 'bills',
          name: 'Bills & Utilities',
          iconName: 'receipt',
          color: Color(0xFFEF4444),
          isDefault: true,
        ),
        const Category(
          id: 'health',
          name: 'Health & Fitness',
          iconName: 'favorite',
          color: Color(0xFF10B981),
          isDefault: true,
        ),
        const Category(
          id: 'education',
          name: 'Education',
          iconName: 'school',
          color: Color(0xFF14B8A6),
          isDefault: true,
        ),
        const Category(
          id: 'salary',
          name: 'Salary',
          iconName: 'work',
          color: Color(0xFF22C55E),
          isDefault: true,
        ),
        const Category(
          id: 'freelance',
          name: 'Freelance',
          iconName: 'laptop',
          color: Color(0xFF6366F1),
          isDefault: true,
        ),
        const Category(
          id: 'investment',
          name: 'Investment',
          iconName: 'trending_up',
          color: Color(0xFF06B6D4),
          isDefault: true,
        ),
      ];

  Category copyWith({
    String? id,
    String? name,
    String? iconName,
    Color? color,
    double? budgetLimit,
    bool? isDefault,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
      budgetLimit: budgetLimit ?? this.budgetLimit,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconName': iconName,
      'color': color.value,
      'budgetLimit': budgetLimit,
      'isDefault': isDefault,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      iconName: json['iconName'] as String,
      color: Color(json['color'] as int),
      budgetLimit: json['budgetLimit'] != null
          ? (json['budgetLimit'] as num).toDouble()
          : null,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }
}

/// Budget model
@immutable
class Budget {
  final String id;
  final String categoryId;
  final double limit;
  final BudgetPeriod period;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;

  const Budget({
    required this.id,
    required this.categoryId,
    required this.limit,
    this.period = BudgetPeriod.monthly,
    required this.startDate,
    this.endDate,
    this.isActive = true,
  });

  Budget copyWith({
    String? id,
    String? categoryId,
    double? limit,
    BudgetPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      limit: limit ?? this.limit,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'limit': limit,
      'period': period.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      limit: (json['limit'] as num).toDouble(),
      period: BudgetPeriod.values.firstWhere(
        (e) => e.name == json['period'],
        orElse: () => BudgetPeriod.monthly,
      ),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

enum BudgetPeriod {
  daily,
  weekly,
  monthly,
  yearly,
}

/// User settings model
@immutable
class UserSettings {
  final String currency;
  final String language;
  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final bool biometricEnabled;
  final String? userName;
  final String? userEmail;

  const UserSettings({
    this.currency = 'USD',
    this.language = 'en',
    this.themeMode = ThemeMode.system,
    this.notificationsEnabled = true,
    this.biometricEnabled = false,
    this.userName,
    this.userEmail,
  });

  UserSettings copyWith({
    String? currency,
    String? language,
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    bool? biometricEnabled,
    String? userName,
    String? userEmail,
  }) {
    return UserSettings(
      currency: currency ?? this.currency,
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currency': currency,
      'language': language,
      'themeMode': themeMode.name,
      'notificationsEnabled': notificationsEnabled,
      'biometricEnabled': biometricEnabled,
      'userName': userName,
      'userEmail': userEmail,
    };
  }

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      currency: json['currency'] as String? ?? 'USD',
      language: json['language'] as String? ?? 'en',
      themeMode: ThemeMode.values.firstWhere(
        (e) => e.name == json['themeMode'],
        orElse: () => ThemeMode.system,
      ),
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      biometricEnabled: json['biometricEnabled'] as bool? ?? false,
      userName: json['userName'] as String?,
      userEmail: json['userEmail'] as String?,
    );
  }
}
