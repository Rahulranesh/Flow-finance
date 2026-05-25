import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/settings_repository.dart';

/// Smart rules engine for automatic transaction processing
class SmartRulesEngine {
  final SettingsRepository _settingsRepository;
  final List<SmartRule> _rules = [];
  final List<RuleExecution> _executionHistory = [];

  SmartRulesEngine(this._settingsRepository) {
    _loadRules();
  }

  void _loadRules() async {
    final jsonString = await _settingsRepository.getString('smart_rules');
    if (jsonString != null) {
      final decoded = jsonDecode(jsonString);
      if (decoded is List) {
        importRules(decoded.map((e) => e as Map<String, dynamic>).toList());
      }
    }
  }

  void _saveRules() async {
    final jsonString = jsonEncode(exportRules());
    await _settingsRepository.setString('smart_rules', jsonString);
  }

  /// Add a new rule
  void addRule(SmartRule rule) {
    _rules.add(rule);
    _sortRules();
    _saveRules();
  }

  /// Remove a rule
  void removeRule(String ruleId) {
    _rules.removeWhere((r) => r.id == ruleId);
    _saveRules();
  }

  /// Update an existing rule
  void updateRule(SmartRule rule) {
    final index = _rules.indexWhere((r) => r.id == rule.id);
    if (index >= 0) {
      _rules[index] = rule;
      _sortRules();
      _saveRules();
    }
  }

  /// Get all rules
  List<SmartRule> getRules() => List.unmodifiable(_rules);

  /// Get rules by type
  List<SmartRule> getRulesByType(RuleType type) {
    return _rules.where((r) => r.type == type).toList();
  }

  /// Process a transaction against all rules
  RuleExecutionResult processTransaction(Transaction transaction) {
    final appliedRules = <SmartRule>[];
    Transaction modifiedTransaction = transaction;
    final actions = <RuleAction>[];

    for (final rule in _rules.where((r) => r.isActive)) {
      if (_matchesConditions(modifiedTransaction, rule.conditions)) {
        final result = _applyActions(modifiedTransaction, rule.actions);
        modifiedTransaction = result.transaction;
        actions.addAll(result.actions);
        appliedRules.add(rule);

        // Record execution
        _executionHistory.add(RuleExecution(
          id: const Uuid().v4(),
          ruleId: rule.id,
          transactionId: transaction.id,
          timestamp: DateTime.now(),
          success: true,
        ));

        // Stop if rule is set to stop processing
        if (rule.stopProcessing) {
          break;
        }
      }
    }

    return RuleExecutionResult(
      originalTransaction: transaction,
      modifiedTransaction: modifiedTransaction,
      appliedRules: appliedRules,
      actions: actions,
    );
  }

  /// Process multiple transactions
  List<RuleExecutionResult> processBatch(List<Transaction> transactions) {
    return transactions.map((t) => processTransaction(t)).toList();
  }

  /// Get execution history
  List<RuleExecution> getExecutionHistory({int limit = 100}) {
    return _executionHistory
        .sorted((a, b) => b.timestamp.compareTo(a.timestamp))
        .take(limit)
        .toList();
  }

  /// Get rule statistics
  RuleStatistics getRuleStatistics(String ruleId) {
    final executions = _executionHistory.where((e) => e.ruleId == ruleId);
    return RuleStatistics(
      ruleId: ruleId,
      totalExecutions: executions.length,
      lastExecuted: executions.isNotEmpty ? executions.last.timestamp : null,
    );
  }

  /// Clear execution history
  void clearHistory() {
    _executionHistory.clear();
  }

  /// Export rules
  List<Map<String, dynamic>> exportRules() {
    return _rules.map((r) => r.toJson()).toList();
  }

  /// Import rules
  void importRules(List<Map<String, dynamic>> rules) {
    for (final json in rules) {
      _rules.add(SmartRule.fromJson(json));
    }
    _sortRules();
  }

  // Private methods

  void _sortRules() {
    _rules.sort((a, b) => a.priority.compareTo(b.priority));
  }

  bool _matchesConditions(Transaction transaction, List<RuleCondition> conditions) {
    if (conditions.isEmpty) return true;

    for (final condition in conditions) {
      if (!_matchesCondition(transaction, condition)) {
        return false;
      }
    }
    return true;
  }

  bool _matchesCondition(Transaction transaction, RuleCondition condition) {
    dynamic value;
    
    switch (condition.field) {
      case TransactionField.amount:
        value = transaction.amount;
        break;
      case TransactionField.title:
        value = transaction.title;
        break;
      case TransactionField.category:
        value = transaction.category;
        break;
      case TransactionField.type:
        value = transaction.type.name;
        break;
      case TransactionField.note:
        value = transaction.note ?? '';
        break;
      case TransactionField.walletId:
        value = transaction.walletId ?? '';
        break;
    }

    return condition.evaluate(value);
  }

  _ActionResult _applyActions(Transaction transaction, List<RuleAction> actions) {
    Transaction modified = transaction;
    final appliedActions = <RuleAction>[];

    for (final action in actions) {
      switch (action.type) {
        case ActionType.setCategory:
          modified = modified.copyWith(category: action.value as String);
          break;
        case ActionType.setType:
          modified = modified.copyWith(
            type: TransactionType.values.firstWhere(
              (t) => t.name == action.value,
              orElse: () => transaction.type,
            ),
          );
          break;
        case ActionType.setWallet:
          modified = modified.copyWith(walletId: action.value as String);
          break;
        case ActionType.addTag:
          // Would need to add tags field to Transaction model
          break;
        case ActionType.setNote:
          modified = modified.copyWith(note: action.value as String);
          break;
        case ActionType.markAsBusiness:
          // Would need business flag in Transaction model
          break;
        case ActionType.markAsPersonal:
          // Would need personal flag in Transaction model
          break;
      }
      appliedActions.add(action);
    }

    return _ActionResult(modified, appliedActions);
  }
}

/// Smart rule definition
class SmartRule {
  final String id;
  final String name;
  final String? description;
  final RuleType type;
  final List<RuleCondition> conditions;
  final List<RuleAction> actions;
  final int priority;
  final bool isActive;
  final bool stopProcessing;
  final DateTime createdAt;
  final DateTime? lastExecuted;

  SmartRule({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.conditions,
    required this.actions,
    this.priority = 0,
    this.isActive = true,
    this.stopProcessing = false,
    required this.createdAt,
    this.lastExecuted,
  });

  SmartRule copyWith({
    String? id,
    String? name,
    String? description,
    RuleType? type,
    List<RuleCondition>? conditions,
    List<RuleAction>? actions,
    int? priority,
    bool? isActive,
    bool? stopProcessing,
    DateTime? createdAt,
    DateTime? lastExecuted,
  }) {
    return SmartRule(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      conditions: conditions ?? this.conditions,
      actions: actions ?? this.actions,
      priority: priority ?? this.priority,
      isActive: isActive ?? this.isActive,
      stopProcessing: stopProcessing ?? this.stopProcessing,
      createdAt: createdAt ?? this.createdAt,
      lastExecuted: lastExecuted ?? this.lastExecuted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'conditions': conditions.map((c) => c.toJson()).toList(),
      'actions': actions.map((a) => a.toJson()).toList(),
      'priority': priority,
      'isActive': isActive,
      'stopProcessing': stopProcessing,
      'createdAt': createdAt.toIso8601String(),
      'lastExecuted': lastExecuted?.toIso8601String(),
    };
  }

  factory SmartRule.fromJson(Map<String, dynamic> json) {
    return SmartRule(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: RuleType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => RuleType.categorization,
      ),
      conditions: (json['conditions'] as List)
          .map((c) => RuleCondition.fromJson(c as Map<String, dynamic>))
          .toList(),
      actions: (json['actions'] as List)
          .map((a) => RuleAction.fromJson(a as Map<String, dynamic>))
          .toList(),
      priority: json['priority'] as int,
      isActive: json['isActive'] as bool,
      stopProcessing: json['stopProcessing'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastExecuted: json['lastExecuted'] != null
          ? DateTime.parse(json['lastExecuted'] as String)
          : null,
    );
  }
}

enum RuleType {
  categorization,
  tagging,
  walletAssignment,
  typeAssignment,
  notification,
}

/// Rule condition
class RuleCondition {
  final TransactionField field;
  final ConditionOperator operator;
  final dynamic value;

  RuleCondition({
    required this.field,
    required this.operator,
    required this.value,
  });

  bool evaluate(dynamic fieldValue) {
    switch (operator) {
      case ConditionOperator.equals:
        return fieldValue.toString().toLowerCase() == value.toString().toLowerCase();
      case ConditionOperator.notEquals:
        return fieldValue.toString().toLowerCase() != value.toString().toLowerCase();
      case ConditionOperator.contains:
        return fieldValue.toString().toLowerCase().contains(value.toString().toLowerCase());
      case ConditionOperator.notContains:
        return !fieldValue.toString().toLowerCase().contains(value.toString().toLowerCase());
      case ConditionOperator.greaterThan:
        return (fieldValue as num) > (value as num);
      case ConditionOperator.lessThan:
        return (fieldValue as num) < (value as num);
      case ConditionOperator.greaterThanOrEqual:
        return (fieldValue as num) >= (value as num);
      case ConditionOperator.lessThanOrEqual:
        return (fieldValue as num) <= (value as num);
      case ConditionOperator.startsWith:
        return fieldValue.toString().toLowerCase().startsWith(value.toString().toLowerCase());
      case ConditionOperator.endsWith:
        return fieldValue.toString().toLowerCase().endsWith(value.toString().toLowerCase());
      case ConditionOperator.matchesRegex:
        return RegExp(value as String).hasMatch(fieldValue.toString());
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'field': field.name,
      'operator': operator.name,
      'value': value,
    };
  }

  factory RuleCondition.fromJson(Map<String, dynamic> json) {
    return RuleCondition(
      field: TransactionField.values.firstWhere(
        (f) => f.name == json['field'],
        orElse: () => TransactionField.title,
      ),
      operator: ConditionOperator.values.firstWhere(
        (o) => o.name == json['operator'],
        orElse: () => ConditionOperator.contains,
      ),
      value: json['value'],
    );
  }
}

enum TransactionField {
  amount,
  title,
  category,
  type,
  note,
  walletId,
}

enum ConditionOperator {
  equals,
  notEquals,
  contains,
  notContains,
  greaterThan,
  lessThan,
  greaterThanOrEqual,
  lessThanOrEqual,
  startsWith,
  endsWith,
  matchesRegex,
}

/// Rule action
class RuleAction {
  final ActionType type;
  final dynamic value;

  RuleAction({
    required this.type,
    required this.value,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'value': value,
    };
  }

  factory RuleAction.fromJson(Map<String, dynamic> json) {
    return RuleAction(
      type: ActionType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => ActionType.setCategory,
      ),
      value: json['value'],
    );
  }
}

enum ActionType {
  setCategory,
  setType,
  setWallet,
  addTag,
  setNote,
  markAsBusiness,
  markAsPersonal,
}

/// Rule execution record
class RuleExecution {
  final String id;
  final String ruleId;
  final String transactionId;
  final DateTime timestamp;
  final bool success;
  final String? errorMessage;

  RuleExecution({
    required this.id,
    required this.ruleId,
    required this.transactionId,
    required this.timestamp,
    required this.success,
    this.errorMessage,
  });
}

/// Rule execution result
class RuleExecutionResult {
  final Transaction originalTransaction;
  final Transaction modifiedTransaction;
  final List<SmartRule> appliedRules;
  final List<RuleAction> actions;

  RuleExecutionResult({
    required this.originalTransaction,
    required this.modifiedTransaction,
    required this.appliedRules,
    required this.actions,
  });

  bool get wasModified => appliedRules.isNotEmpty;
}

/// Rule statistics
class RuleStatistics {
  final String ruleId;
  final int totalExecutions;
  final DateTime? lastExecuted;

  RuleStatistics({
    required this.ruleId,
    required this.totalExecutions,
    this.lastExecuted,
  });
}

/// Extension for sorting
extension<T> on List<T> {
  List<T> sorted(int Function(T, T) compare) {
    return [...this]..sort(compare);
  }
}

/// Predefined rule templates
class RuleTemplates {
  static SmartRule createCategoryRule({
    required String name,
    required String keyword,
    required String category,
    int priority = 0,
  }) {
    return SmartRule(
      id: const Uuid().v4(),
      name: name,
      type: RuleType.categorization,
      conditions: [
        RuleCondition(
          field: TransactionField.title,
          operator: ConditionOperator.contains,
          value: keyword,
        ),
      ],
      actions: [
        RuleAction(type: ActionType.setCategory, value: category),
      ],
      priority: priority,
      createdAt: DateTime.now(),
    );
  }

  static SmartRule createAmountRule({
    required String name,
    required double minAmount,
    required String category,
  }) {
    return SmartRule(
      id: const Uuid().v4(),
      name: name,
      type: RuleType.categorization,
      conditions: [
        RuleCondition(
          field: TransactionField.amount,
          operator: ConditionOperator.greaterThanOrEqual,
          value: minAmount,
        ),
      ],
      actions: [
        RuleAction(type: ActionType.setCategory, value: category),
      ],
      createdAt: DateTime.now(),
    );
  }

  static SmartRule createWalletRule({
    required String name,
    required String keyword,
    required String walletId,
  }) {
    return SmartRule(
      id: const Uuid().v4(),
      name: name,
      type: RuleType.walletAssignment,
      conditions: [
        RuleCondition(
          field: TransactionField.title,
          operator: ConditionOperator.contains,
          value: keyword,
        ),
      ],
      actions: [
        RuleAction(type: ActionType.setWallet, value: walletId),
      ],
      createdAt: DateTime.now(),
    );
  }
}

class _ActionResult {
  final Transaction transaction;
  final List<RuleAction> actions;

  _ActionResult(this.transaction, this.actions);
}
