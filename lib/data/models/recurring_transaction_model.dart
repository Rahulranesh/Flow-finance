import 'package:flutter/material.dart';
import 'transaction_model.dart';

/// Frequency options for recurring transactions
enum RecurringFrequency {
  daily,
  weekly,
  biweekly,
  monthly,
  quarterly,
  yearly,
}

extension RecurringFrequencyExtension on RecurringFrequency {
  String get displayName {
    switch (this) {
      case RecurringFrequency.daily:
        return 'Daily';
      case RecurringFrequency.weekly:
        return 'Weekly';
      case RecurringFrequency.biweekly:
        return 'Bi-weekly';
      case RecurringFrequency.monthly:
        return 'Monthly';
      case RecurringFrequency.quarterly:
        return 'Quarterly';
      case RecurringFrequency.yearly:
        return 'Yearly';
    }
  }

  String get shortName {
    switch (this) {
      case RecurringFrequency.daily:
        return 'day';
      case RecurringFrequency.weekly:
        return 'week';
      case RecurringFrequency.biweekly:
        return '2 weeks';
      case RecurringFrequency.monthly:
        return 'month';
      case RecurringFrequency.quarterly:
        return 'quarter';
      case RecurringFrequency.yearly:
        return 'year';
    }
  }

  /// Get the next occurrence date based on current date
  DateTime getNextDate(DateTime from) {
    switch (this) {
      case RecurringFrequency.daily:
        return from.add(const Duration(days: 1));
      case RecurringFrequency.weekly:
        return from.add(const Duration(days: 7));
      case RecurringFrequency.biweekly:
        return from.add(const Duration(days: 14));
      case RecurringFrequency.monthly:
        return DateTime(from.year, from.month + 1, from.day);
      case RecurringFrequency.quarterly:
        return DateTime(from.year, from.month + 3, from.day);
      case RecurringFrequency.yearly:
        return DateTime(from.year + 1, from.month, from.day);
    }
  }

  /// Get the previous occurrence date based on current date
  DateTime getPreviousDate(DateTime from) {
    switch (this) {
      case RecurringFrequency.daily:
        return from.subtract(const Duration(days: 1));
      case RecurringFrequency.weekly:
        return from.subtract(const Duration(days: 7));
      case RecurringFrequency.biweekly:
        return from.subtract(const Duration(days: 14));
      case RecurringFrequency.monthly:
        return DateTime(from.year, from.month - 1, from.day);
      case RecurringFrequency.quarterly:
        return DateTime(from.year, from.month - 3, from.day);
      case RecurringFrequency.yearly:
        return DateTime(from.year - 1, from.month, from.day);
    }
  }
}

/// End condition types for recurring transactions
enum EndConditionType {
  never,
  afterCount,
  onDate,
}

/// Model for recurring transactions
class RecurringTransaction {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String category;
  final String? walletId;
  final String? note;

  // Recurrence settings
  final RecurringFrequency frequency;
  final DateTime startDate;
  final EndConditionType endCondition;
  final int? occurrenceCount; // For 'afterCount' end condition
  final DateTime? endDate; // For 'onDate' end condition

  // Tracking
  final DateTime createdAt;
  final DateTime? lastProcessed;
  final int processedCount;
  final bool isActive;
  final DateTime? nextDueDate;

  const RecurringTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    this.walletId,
    this.note,
    required this.frequency,
    required this.startDate,
    this.endCondition = EndConditionType.never,
    this.occurrenceCount,
    this.endDate,
    required this.createdAt,
    this.lastProcessed,
    this.processedCount = 0,
    this.isActive = true,
    this.nextDueDate,
  });

  /// Check if this recurring transaction has ended
  bool get hasEnded {
    if (!isActive) return true;

    switch (endCondition) {
      case EndConditionType.never:
        return false;
      case EndConditionType.afterCount:
        return occurrenceCount != null && processedCount >= occurrenceCount!;
      case EndConditionType.onDate:
        return endDate != null && DateTime.now().isAfter(endDate!);
    }
  }

  /// Get the next due date for this recurring transaction
  DateTime get calculatedNextDueDate {
    if (hasEnded) return DateTime.now();

    DateTime baseDate = lastProcessed ?? startDate;
    DateTime nextDate = frequency.getNextDate(baseDate);

    // If next date is in the past, keep advancing until we find a future date
    while (nextDate.isBefore(DateTime.now())) {
      nextDate = frequency.getNextDate(nextDate);
    }

    return nextDate;
  }

  /// Check if transaction is due today
  bool get isDueToday {
    final next = nextDueDate ?? calculatedNextDueDate;
    final now = DateTime.now();
    return next.year == now.year &&
           next.month == now.month &&
           next.day == now.day;
  }

  /// Check if transaction is overdue
  bool get isOverdue {
    final next = nextDueDate ?? calculatedNextDueDate;
    return next.isBefore(DateTime.now()) && !isDueToday;
  }

  /// Get days until next occurrence
  int get daysUntilDue {
    final next = nextDueDate ?? calculatedNextDueDate;
    return next.difference(DateTime.now()).inDays;
  }

  /// Get estimated monthly amount
  double get estimatedMonthlyAmount {
    switch (frequency) {
      case RecurringFrequency.daily:
        return amount * 30;
      case RecurringFrequency.weekly:
        return amount * 4.33; // Average weeks per month
      case RecurringFrequency.biweekly:
        return amount * 2.17;
      case RecurringFrequency.monthly:
        return amount;
      case RecurringFrequency.quarterly:
        return amount / 3;
      case RecurringFrequency.yearly:
        return amount / 12;
    }
  }

  /// Convert to a regular transaction
  Transaction toTransaction({DateTime? date}) {
    return Transaction(
      id: '${id}_$processedCount',
      title: title,
      amount: amount,
      type: type,
      category: category,
      date: date ?? DateTime.now(),
      note: note,
      walletId: walletId,
    );
  }

  RecurringTransaction copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    String? category,
    String? walletId,
    String? note,
    RecurringFrequency? frequency,
    DateTime? startDate,
    EndConditionType? endCondition,
    int? occurrenceCount,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? lastProcessed,
    int? processedCount,
    bool? isActive,
    DateTime? nextDueDate,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      walletId: walletId ?? this.walletId,
      note: note ?? this.note,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endCondition: endCondition ?? this.endCondition,
      occurrenceCount: occurrenceCount ?? this.occurrenceCount,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      lastProcessed: lastProcessed ?? this.lastProcessed,
      processedCount: processedCount ?? this.processedCount,
      isActive: isActive ?? this.isActive,
      nextDueDate: nextDueDate ?? this.nextDueDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.name,
      'category': category,
      'walletId': walletId,
      'note': note,
      'frequency': frequency.name,
      'startDate': startDate.toIso8601String(),
      'endCondition': endCondition.name,
      'occurrenceCount': occurrenceCount,
      'endDate': endDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'lastProcessed': lastProcessed?.toIso8601String(),
      'processedCount': processedCount,
      'isActive': isActive,
      'nextDueDate': nextDueDate?.toIso8601String(),
    };
  }

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) {
    return RecurringTransaction(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.expense,
      ),
      category: json['category'] as String,
      walletId: json['walletId'] as String?,
      note: json['note'] as String?,
      frequency: RecurringFrequency.values.firstWhere(
        (e) => e.name == json['frequency'],
        orElse: () => RecurringFrequency.monthly,
      ),
      startDate: DateTime.parse(json['startDate'] as String),
      endCondition: EndConditionType.values.firstWhere(
        (e) => e.name == json['endCondition'],
        orElse: () => EndConditionType.never,
      ),
      occurrenceCount: json['occurrenceCount'] as int?,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastProcessed: json['lastProcessed'] != null
          ? DateTime.parse(json['lastProcessed'] as String)
          : null,
      processedCount: json['processedCount'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      nextDueDate: json['nextDueDate'] != null
          ? DateTime.parse(json['nextDueDate'] as String)
          : null,
    );
  }

  @override
  String toString() {
    return 'RecurringTransaction(id: $id, title: $title, amount: $amount, frequency: $frequency)';
  }
}

/// Summary statistics for recurring transactions
class RecurringTransactionSummary {
  final double totalMonthlyIncome;
  final double totalMonthlyExpense;
  final double netMonthly;
  final int activeCount;
  final int dueTodayCount;
  final int overdueCount;

  const RecurringTransactionSummary({
    required this.totalMonthlyIncome,
    required this.totalMonthlyExpense,
    required this.netMonthly,
    required this.activeCount,
    required this.dueTodayCount,
    required this.overdueCount,
  });

  factory RecurringTransactionSummary.fromList(List<RecurringTransaction> transactions) {
    double income = 0;
    double expense = 0;
    int active = 0;
    int dueToday = 0;
    int overdue = 0;

    for (final t in transactions) {
      if (!t.hasEnded) {
        active++;
        final monthly = t.estimatedMonthlyAmount;

        if (t.type == TransactionType.income) {
          income += monthly;
        } else {
          expense += monthly;
        }

        if (t.isDueToday) dueToday++;
        if (t.isOverdue) overdue++;
      }
    }

    return RecurringTransactionSummary(
      totalMonthlyIncome: income,
      totalMonthlyExpense: expense,
      netMonthly: income - expense,
      activeCount: active,
      dueTodayCount: dueToday,
      overdueCount: overdue,
    );
  }
}
