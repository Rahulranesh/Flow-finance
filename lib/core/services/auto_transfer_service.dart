import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/settings_repository.dart';

/// Service for automated transfers and savings features
class AutoTransferService {
  final SettingsRepository _settingsRepository;
  AutoTransferService(this._settingsRepository) {
    _loadData();
  }

  final List<AutoTransferRule> _rules = [];
  final List<RoundUpRule> _roundUpRules = [];
  final List<TransferRecord> _transferHistory = [];

  // Getters
  List<AutoTransferRule> get rules => List.unmodifiable(_rules);
  List<RoundUpRule> get roundUpRules => List.unmodifiable(_roundUpRules);
  List<TransferRecord> get transferHistory => List.unmodifiable(_transferHistory);

  void _loadData() async {
    try {
      final rulesString = await _settingsRepository.getString('auto_transfer_rules');
      if (rulesString != null) {
        final decoded = jsonDecode(rulesString);
        if (decoded is List) {
          _rules.clear();
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              _rules.add(AutoTransferRule.fromJson(item));
            }
          }
        }
      }

      final roundUpsString = await _settingsRepository.getString('auto_transfer_roundups');
      if (roundUpsString != null) {
        final decoded = jsonDecode(roundUpsString);
        if (decoded is List) {
          _roundUpRules.clear();
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              _roundUpRules.add(RoundUpRule.fromJson(item));
            }
          }
        }
      }

      final historyString = await _settingsRepository.getString('auto_transfer_history');
      if (historyString != null) {
        final decoded = jsonDecode(historyString);
        if (decoded is List) {
          _transferHistory.clear();
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              _transferHistory.add(TransferRecord.fromJson(item));
            }
          }
        }
      }
    } catch (e) {
      print('Error loading AutoTransferService data: $e');
    }
  }

  void _saveRules() async {
    final jsonString = jsonEncode(_rules.map((r) => r.toJson()).toList());
    await _settingsRepository.setString('auto_transfer_rules', jsonString);
  }

  void _saveRoundUpRules() async {
    final jsonString = jsonEncode(_roundUpRules.map((r) => r.toJson()).toList());
    await _settingsRepository.setString('auto_transfer_roundups', jsonString);
  }

  void _saveHistory() async {
    final jsonString = jsonEncode(_transferHistory.map((r) => r.toJson()).toList());
    await _settingsRepository.setString('auto_transfer_history', jsonString);
  }

  /// Add an auto-transfer rule
  void addAutoTransferRule(AutoTransferRule rule) {
    final index = _rules.indexWhere((r) => r.id == rule.id);
    if (index >= 0) {
      _rules[index] = rule;
    } else {
      _rules.add(rule);
    }
    _saveRules();
  }

  /// Remove an auto-transfer rule
  void removeAutoTransferRule(String ruleId) {
    _rules.removeWhere((r) => r.id == ruleId);
    _saveRules();
  }

  /// Add a round-up rule
  void addRoundUpRule(RoundUpRule rule) {
    final index = _roundUpRules.indexWhere((r) => r.id == rule.id);
    if (index >= 0) {
      _roundUpRules[index] = rule;
    } else {
      _roundUpRules.add(rule);
    }
    _saveRoundUpRules();
  }

  /// Remove a round-up rule
  void removeRoundUpRule(String ruleId) {
    _roundUpRules.removeWhere((r) => r.id == ruleId);
    _saveRoundUpRules();
  }

  /// Process a transaction and check for auto-transfers
  List<TransferRecommendation> processTransaction(Transaction transaction) {
    final recommendations = <TransferRecommendation>[];

    // Check auto-transfer rules
    for (final rule in _rules.where((r) => r.isActive)) {
      if (_matchesTrigger(transaction, rule.trigger)) {
        final amount = _calculateTransferAmount(transaction, rule);
        if (amount > 0) {
          recommendations.add(TransferRecommendation(
            id: const Uuid().v4(),
            sourceWalletId: rule.sourceWalletId,
            destinationWalletId: rule.destinationWalletId,
            amount: amount,
            reason: rule.name,
            ruleId: rule.id,
            triggeredBy: transaction.id,
          ));
        }
      }
    }

    // Check round-up rules
    for (final rule in _roundUpRules.where((r) => r.isActive)) {
      if (transaction.type == TransactionType.expense) {
        final roundUpAmount = _calculateRoundUp(transaction.amount, rule);
        if (roundUpAmount > 0) {
          recommendations.add(TransferRecommendation(
            id: const Uuid().v4(),
            sourceWalletId: rule.sourceWalletId,
            destinationWalletId: rule.savingsWalletId,
            amount: roundUpAmount,
            reason: '${rule.name}: Round-up from \$${transaction.amount}',
            ruleId: rule.id,
            triggeredBy: transaction.id,
          ));
        }
      }
    }

    return recommendations;
  }

  /// Execute a transfer recommendation
  Future<TransferRecord> executeTransfer(TransferRecommendation recommendation) async {
    final record = TransferRecord(
      id: recommendation.id,
      sourceWalletId: recommendation.sourceWalletId,
      destinationWalletId: recommendation.destinationWalletId,
      amount: recommendation.amount,
      reason: recommendation.reason,
      timestamp: DateTime.now(),
      status: TransferStatus.completed,
      ruleId: recommendation.ruleId,
      triggeredBy: recommendation.triggeredBy,
    );

    _transferHistory.add(record);
    _saveHistory();
    return record;
  }

  /// Get savings summary
  SavingsSummary getSavingsSummary({int days = 30}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final recentTransfers = _transferHistory.where(
      (t) => t.timestamp.isAfter(cutoffDate) && t.status == TransferStatus.completed,
    );

    final totalSaved = recentTransfers.fold(0.0, (sum, t) => sum + t.amount);
    final transferCount = recentTransfers.length;

    // Calculate by rule type
    final byRuleType = <String, double>{};
    for (final transfer in recentTransfers) {
      String ruleName = 'Unknown';
      final autoRuleIndex = _rules.indexWhere((r) => r.id == transfer.ruleId);
      if (autoRuleIndex >= 0) {
        ruleName = _rules[autoRuleIndex].name;
      } else {
        final roundRuleIndex = _roundUpRules.indexWhere((r) => r.id == transfer.ruleId);
        if (roundRuleIndex >= 0) {
          ruleName = _roundUpRules[roundRuleIndex].name;
        }
      }
      byRuleType[ruleName] = (byRuleType[ruleName] ?? 0) + transfer.amount;
    }

    return SavingsSummary(
      totalSaved: totalSaved,
      transferCount: transferCount,
      averagePerTransfer: transferCount > 0 ? totalSaved / transferCount : 0,
      byRuleType: byRuleType,
      periodDays: days,
    );
  }

  /// Get projected savings
  ProjectedSavings calculateProjectedSavings(int months) {
    final summary = getSavingsSummary(days: 90); // Use last 90 days for projection
    final monthlyAverage = summary.totalSaved / 3; // 3 months
    
    return ProjectedSavings(
      monthlyAverage: monthlyAverage,
      projectedAmount: monthlyAverage * months,
      months: months,
      confidence: summary.transferCount > 10 ? 0.8 : 0.5,
    );
  }

  /// Simulate round-ups for past transactions
  RoundUpSimulation simulateRoundUps(
    List<Transaction> transactions,
    RoundUpRule rule,
  ) {
    double totalRoundUp = 0;
    int transactionCount = 0;

    for (final transaction in transactions.where((t) => t.type == TransactionType.expense)) {
      final roundUp = _calculateRoundUp(transaction.amount, rule);
      if (roundUp > 0) {
        totalRoundUp += roundUp;
        transactionCount++;
      }
    }

    return RoundUpSimulation(
      ruleName: rule.name,
      totalRoundUp: totalRoundUp,
      transactionCount: transactionCount,
      averageRoundUp: transactionCount > 0 ? totalRoundUp / transactionCount : 0,
    );
  }

  /// Clear transfer history
  void clearHistory() {
    _transferHistory.clear();
    _saveHistory();
  }

  // Private methods

  bool _matchesTrigger(Transaction transaction, TransferTrigger trigger) {
    switch (trigger.type) {
      case TriggerType.incomeReceived:
        return transaction.type == TransactionType.income &&
               transaction.amount >= (trigger.minAmount ?? 0);
      case TriggerType.expenseMade:
        return transaction.type == TransactionType.expense &&
               transaction.amount >= (trigger.minAmount ?? 0);
      case TriggerType.categorySpending:
        return transaction.category == trigger.category &&
               transaction.type == TransactionType.expense;
      case TriggerType.dateBased:
        // Check if today matches the schedule
        return _matchesSchedule(trigger.schedule);
    }
  }

  bool _matchesSchedule(Schedule? schedule) {
    if (schedule == null) return false;
    
    final now = DateTime.now();
    
    switch (schedule.frequency) {
      case ScheduleFrequency.daily:
        return true;
      case ScheduleFrequency.weekly:
        return schedule.dayOfWeek == now.weekday;
      case ScheduleFrequency.monthly:
        return schedule.dayOfMonth == now.day;
      case ScheduleFrequency.yearly:
        return schedule.month == now.month && schedule.dayOfMonth == now.day;
    }
  }

  double _calculateTransferAmount(Transaction transaction, AutoTransferRule rule) {
    switch (rule.calculationType) {
      case CalculationType.fixedAmount:
        return rule.amount;
      case CalculationType.percentage:
        return transaction.amount * (rule.amount / 100);
      case CalculationType.remaining:
        return rule.amount;
    }
  }

  double _calculateRoundUp(double amount, RoundUpRule rule) {
    switch (rule.roundUpTo) {
      case RoundUpTo.nearestDollar:
        final rounded = amount.ceil();
        return rounded - amount;
      case RoundUpTo.nearestFive:
        final rounded = (amount / 5).ceil() * 5;
        return rounded - amount;
      case RoundUpTo.nearestTen:
        final rounded = (amount / 10).ceil() * 10;
        return rounded - amount;
      case RoundUpTo.custom:
        if (rule.customAmount == null) return 0;
        final multiplier = (amount / rule.customAmount!).ceil();
        final rounded = multiplier * rule.customAmount!;
        return rounded - amount;
    }
  }
}

/// Auto-transfer rule
class AutoTransferRule {
  final String id;
  final String name;
  final String? description;
  final TransferTrigger trigger;
  final String sourceWalletId;
  final String destinationWalletId;
  final CalculationType calculationType;
  final double amount;
  final bool isActive;
  final DateTime createdAt;

  AutoTransferRule({
    required this.id,
    required this.name,
    this.description,
    required this.trigger,
    required this.sourceWalletId,
    required this.destinationWalletId,
    required this.calculationType,
    required this.amount,
    this.isActive = true,
    required this.createdAt,
  });

  AutoTransferRule copyWith({
    String? id,
    String? name,
    String? description,
    TransferTrigger? trigger,
    String? sourceWalletId,
    String? destinationWalletId,
    CalculationType? calculationType,
    double? amount,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return AutoTransferRule(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      trigger: trigger ?? this.trigger,
      sourceWalletId: sourceWalletId ?? this.sourceWalletId,
      destinationWalletId: destinationWalletId ?? this.destinationWalletId,
      calculationType: calculationType ?? this.calculationType,
      amount: amount ?? this.amount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'trigger': trigger.toJson(),
      'sourceWalletId': sourceWalletId,
      'destinationWalletId': destinationWalletId,
      'calculationType': calculationType.name,
      'amount': amount,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AutoTransferRule.fromJson(Map<String, dynamic> json) {
    return AutoTransferRule(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      trigger: TransferTrigger.fromJson(json['trigger'] as Map<String, dynamic>),
      sourceWalletId: json['sourceWalletId'] as String,
      destinationWalletId: json['destinationWalletId'] as String,
      calculationType: CalculationType.values.firstWhere(
        (e) => e.name == json['calculationType'],
        orElse: () => CalculationType.fixedAmount,
      ),
      amount: (json['amount'] as num).toDouble(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Round-up rule
class RoundUpRule {
  final String id;
  final String name;
  final RoundUpTo roundUpTo;
  final double? customAmount;
  final String sourceWalletId;
  final String savingsWalletId;
  final bool isActive;
  final DateTime createdAt;

  RoundUpRule({
    required this.id,
    required this.name,
    required this.roundUpTo,
    this.customAmount,
    required this.sourceWalletId,
    required this.savingsWalletId,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'roundUpTo': roundUpTo.name,
      'customAmount': customAmount,
      'sourceWalletId': sourceWalletId,
      'savingsWalletId': savingsWalletId,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory RoundUpRule.fromJson(Map<String, dynamic> json) {
    return RoundUpRule(
      id: json['id'] as String,
      name: json['name'] as String,
      roundUpTo: RoundUpTo.values.firstWhere(
        (e) => e.name == json['roundUpTo'],
        orElse: () => RoundUpTo.nearestDollar,
      ),
      customAmount: json['customAmount'] != null ? (json['customAmount'] as num).toDouble() : null,
      sourceWalletId: json['sourceWalletId'] as String,
      savingsWalletId: json['savingsWalletId'] as String,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

enum RoundUpTo {
  nearestDollar,
  nearestFive,
  nearestTen,
  custom,
}

/// Transfer trigger
class TransferTrigger {
  final TriggerType type;
  final double? minAmount;
  final String? category;
  final Schedule? schedule;

  TransferTrigger({
    required this.type,
    this.minAmount,
    this.category,
    this.schedule,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'minAmount': minAmount,
      'category': category,
      'schedule': schedule?.toJson(),
    };
  }

  factory TransferTrigger.fromJson(Map<String, dynamic> json) {
    return TransferTrigger(
      type: TriggerType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TriggerType.incomeReceived,
      ),
      minAmount: json['minAmount'] != null ? (json['minAmount'] as num).toDouble() : null,
      category: json['category'] as String?,
      schedule: json['schedule'] != null
          ? Schedule.fromJson(json['schedule'] as Map<String, dynamic>)
          : null,
    );
  }
}

enum TriggerType {
  incomeReceived,
  expenseMade,
  categorySpending,
  dateBased,
}

enum CalculationType {
  fixedAmount,
  percentage,
  remaining,
}

/// Schedule for date-based triggers
class Schedule {
  final ScheduleFrequency frequency;
  final int? dayOfWeek;
  final int? dayOfMonth;
  final int? month;

  Schedule({
    required this.frequency,
    this.dayOfWeek,
    this.dayOfMonth,
    this.month,
  });

  Map<String, dynamic> toJson() {
    return {
      'frequency': frequency.name,
      'dayOfWeek': dayOfWeek,
      'dayOfMonth': dayOfMonth,
      'month': month,
    };
  }

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      frequency: ScheduleFrequency.values.firstWhere(
        (e) => e.name == json['frequency'],
        orElse: () => ScheduleFrequency.daily,
      ),
      dayOfWeek: json['dayOfWeek'] as int?,
      dayOfMonth: json['dayOfMonth'] as int?,
      month: json['month'] as int?,
    );
  }
}

enum ScheduleFrequency {
  daily,
  weekly,
  monthly,
  yearly,
}

/// Transfer recommendation
class TransferRecommendation {
  final String id;
  final String sourceWalletId;
  final String destinationWalletId;
  final double amount;
  final String reason;
  final String? ruleId;
  final String? triggeredBy;

  TransferRecommendation({
    required this.id,
    required this.sourceWalletId,
    required this.destinationWalletId,
    required this.amount,
    required this.reason,
    this.ruleId,
    this.triggeredBy,
  });
}

/// Transfer record
class TransferRecord {
  final String id;
  final String sourceWalletId;
  final String destinationWalletId;
  final double amount;
  final String reason;
  final DateTime timestamp;
  final TransferStatus status;
  final String? ruleId;
  final String? triggeredBy;

  TransferRecord({
    required this.id,
    required this.sourceWalletId,
    required this.destinationWalletId,
    required this.amount,
    required this.reason,
    required this.timestamp,
    required this.status,
    this.ruleId,
    this.triggeredBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceWalletId': sourceWalletId,
      'destinationWalletId': destinationWalletId,
      'amount': amount,
      'reason': reason,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'ruleId': ruleId,
      'triggeredBy': triggeredBy,
    };
  }

  factory TransferRecord.fromJson(Map<String, dynamic> json) {
    return TransferRecord(
      id: json['id'] as String,
      sourceWalletId: json['sourceWalletId'] as String,
      destinationWalletId: json['destinationWalletId'] as String,
      amount: (json['amount'] as num).toDouble(),
      reason: json['reason'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: TransferStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TransferStatus.completed,
      ),
      ruleId: json['ruleId'] as String?,
      triggeredBy: json['triggeredBy'] as String?,
    );
  }
}

enum TransferStatus {
  pending,
  completed,
  failed,
  cancelled,
}

/// Savings summary
class SavingsSummary {
  final double totalSaved;
  final int transferCount;
  final double averagePerTransfer;
  final Map<String, double> byRuleType;
  final int periodDays;

  SavingsSummary({
    required this.totalSaved,
    required this.transferCount,
    required this.averagePerTransfer,
    required this.byRuleType,
    required this.periodDays,
  });
}

/// Projected savings
class ProjectedSavings {
  final double monthlyAverage;
  final double projectedAmount;
  final int months;
  final double confidence;

  ProjectedSavings({
    required this.monthlyAverage,
    required this.projectedAmount,
    required this.months,
    required this.confidence,
  });
}

/// Round-up simulation
class RoundUpSimulation {
  final String ruleName;
  final double totalRoundUp;
  final int transactionCount;
  final double averageRoundUp;

  RoundUpSimulation({
    required this.ruleName,
    required this.totalRoundUp,
    required this.transactionCount,
    required this.averageRoundUp,
  });
}

/// Rule templates
class AutoTransferTemplates {
  static AutoTransferRule createSaveOnIncome({
    required String name,
    required String sourceWalletId,
    required String savingsWalletId,
    required double percentage,
  }) {
    return AutoTransferRule(
      id: const Uuid().v4(),
      name: name,
      trigger: TransferTrigger(type: TriggerType.incomeReceived),
      sourceWalletId: sourceWalletId,
      destinationWalletId: savingsWalletId,
      calculationType: CalculationType.percentage,
      amount: percentage,
      createdAt: DateTime.now(),
    );
  }

  static AutoTransferRule createWeeklySavings({
    required String name,
    required String sourceWalletId,
    required String savingsWalletId,
    required double amount,
    required int dayOfWeek,
  }) {
    return AutoTransferRule(
      id: const Uuid().v4(),
      name: name,
      trigger: TransferTrigger(
        type: TriggerType.dateBased,
        schedule: Schedule(
          frequency: ScheduleFrequency.weekly,
          dayOfWeek: dayOfWeek,
        ),
      ),
      sourceWalletId: sourceWalletId,
      destinationWalletId: savingsWalletId,
      calculationType: CalculationType.fixedAmount,
      amount: amount,
      createdAt: DateTime.now(),
    );
  }

  static RoundUpRule createRoundUpRule({
    required String name,
    required RoundUpTo roundUpTo,
    required String sourceWalletId,
    required String savingsWalletId,
    double? customAmount,
  }) {
    return RoundUpRule(
      id: const Uuid().v4(),
      name: name,
      roundUpTo: roundUpTo,
      customAmount: customAmount,
      sourceWalletId: sourceWalletId,
      savingsWalletId: savingsWalletId,
      createdAt: DateTime.now(),
    );
  }
}
