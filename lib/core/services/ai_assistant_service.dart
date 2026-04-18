import '../../data/models/transaction_model.dart';
import 'ai_insights_service.dart';

/// AI Assistant for natural language financial queries
class AIAssistantService {
  final AIInsightsService _insightsService = AIInsightsService();

  /// Process a natural language query and return a response
  AIQueryResponse processQuery(String query, List<Transaction> transactions) {
    final normalizedQuery = query.toLowerCase().trim();

    // Try to match against known query patterns
    for (final pattern in _queryPatterns) {
      if (pattern.matches(normalizedQuery)) {
        return pattern.execute(normalizedQuery, transactions, _insightsService);
      }
    }

    // Fallback to generic response
    return AIQueryResponse(
      type: ResponseType.unknown,
      message: "I'm not sure how to answer that. Try asking about your spending, income, or budget.",
      suggestions: [
        "How much did I spend on food last month?",
        "What's my biggest expense category?",
        "How much money do I have left this month?",
      ],
    );
  }

  /// Get smart alerts based on transaction patterns
  List<SmartAlert> generateSmartAlerts(List<Transaction> transactions) {
    final alerts = <SmartAlert>[];

    // Check for unusual spending
    final anomalies = _insightsService.detectAnomalies(transactions);
    for (final anomaly in anomalies.where((a) => a.severity == AnomalySeverity.high)) {
      alerts.add(SmartAlert(
        type: AlertType.unusualSpending,
        title: 'Unusual Spending Detected',
        message: anomaly.reason,
        severity: AlertSeverity.warning,
        relatedTransaction: anomaly.transaction,
        timestamp: DateTime.now(),
      ));
    }

    // Check for duplicate transactions
    final duplicates = _findDuplicateTransactions(transactions);
    for (final duplicate in duplicates) {
      alerts.add(SmartAlert(
        type: AlertType.duplicateTransaction,
        title: 'Possible Duplicate Transaction',
        message: 'We noticed a similar transaction: ${duplicate.title} for \$${duplicate.amount}',
        severity: AlertSeverity.info,
        relatedTransaction: duplicate,
        timestamp: DateTime.now(),
      ));
    }

    // Check budget thresholds
    final categorySpending = _calculateCategorySpending(transactions, days: 30);
    categorySpending.forEach((category, amount) {
      // If spending is approaching a typical monthly amount
      final avgMonthly = _calculateAverageMonthlySpending(transactions, category);
      if (avgMonthly > 0 && amount > avgMonthly * 0.9) {
        alerts.add(SmartAlert(
          type: AlertType.budgetWarning,
          title: 'Budget Warning',
          message: 'You\'ve spent \$${amount.toStringAsFixed(0)} on $category, approaching your typical monthly amount of \$${avgMonthly.toStringAsFixed(0)}',
          severity: AlertSeverity.info,
          timestamp: DateTime.now(),
        ));
      }
    });

    // Subscription renewal reminders
    final subscriptions = _detectSubscriptions(transactions);
    for (final sub in subscriptions) {
      final daysUntilRenewal = sub.nextRenewal.difference(DateTime.now()).inDays;
      if (daysUntilRenewal <= 7 && daysUntilRenewal > 0) {
        alerts.add(SmartAlert(
          type: AlertType.subscriptionRenewal,
          title: 'Subscription Renewal',
          message: '${sub.name} will renew in $daysUntilRenewal days for \$${sub.amount.toStringAsFixed(2)}',
          severity: AlertSeverity.info,
          timestamp: DateTime.now(),
        ));
      }
    }

    return alerts..sort((a, b) => b.severity.index.compareTo(a.severity.index));
  }

  /// Get spending insights summary
  String generateSpendingSummary(List<Transaction> transactions, {int days = 30}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final recentTransactions = transactions.where((t) => t.date.isAfter(cutoffDate)).toList();

    if (recentTransactions.isEmpty) {
      return "I don't see any transactions in the last $days days.";
    }

    final totalSpent = recentTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalIncome = recentTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);

    final netSavings = totalIncome - totalSpent;
    final dailyAverage = totalSpent / days;

    // Find top category
    final categorySpending = _calculateCategorySpending(transactions, days: days);
    String topCategory = 'Unknown';
    double topAmount = 0;
    categorySpending.forEach((cat, amount) {
      if (amount > topAmount) {
        topAmount = amount;
        topCategory = cat;
      }
    });

    return "In the last $days days, you spent \$${totalSpent.toStringAsFixed(2)} "
        "(averaging \$${dailyAverage.toStringAsFixed(2)}/day). "
        "Your biggest expense was $topCategory at \$${topAmount.toStringAsFixed(2)}. "
        "You saved \$${netSavings.toStringAsFixed(2)}.";
  }

  // Private helper methods

  List<Transaction> _findDuplicateTransactions(List<Transaction> transactions) {
    final duplicates = <Transaction>[];
    final seen = <String>{};

    for (final t in transactions) {
      // Create a key based on amount, title similarity, and date proximity
      final key = '${t.amount.toStringAsFixed(2)}_${t.title.toLowerCase()}';
      
      if (seen.contains(key)) {
        // Check if dates are within 3 days
        final existing = transactions.firstWhere((tr) => 
          '${tr.amount.toStringAsFixed(2)}_${tr.title.toLowerCase()}' == key);
        
        if (t.date.difference(existing.date).inDays.abs() <= 3) {
          duplicates.add(t);
        }
      } else {
        seen.add(key);
      }
    }

    return duplicates;
  }

  Map<String, double> _calculateCategorySpending(List<Transaction> transactions, {required int days}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final spending = <String, double>{};

    for (final t in transactions.where((t) => 
        t.type == TransactionType.expense && t.date.isAfter(cutoffDate))) {
      spending[t.category] = (spending[t.category] ?? 0) + t.amount;
    }

    return spending;
  }

  double _calculateAverageMonthlySpending(List<Transaction> transactions, String category) {
    final categoryTransactions = transactions.where((t) => 
        t.category == category && t.type == TransactionType.expense).toList();
    
    if (categoryTransactions.isEmpty) return 0;

    final days = _calculateDateRange(transactions);
    final total = categoryTransactions.fold(0.0, (sum, t) => sum + t.amount);
    
    return (total / days) * 30; // Convert to monthly average
  }

  int _calculateDateRange(List<Transaction> transactions) {
    if (transactions.isEmpty) return 1;
    final dates = transactions.map((t) => t.date).toList();
    final earliest = dates.reduce((a, b) => a.isBefore(b) ? a : b);
    final latest = dates.reduce((a, b) => a.isAfter(b) ? a : b);
    return latest.difference(earliest).inDays + 1;
  }

  List<SubscriptionInfo> _detectSubscriptions(List<Transaction> transactions) {
    final subscriptions = <SubscriptionInfo>[];
    final merchantTransactions = <String, List<Transaction>>{};

    // Group by similar titles
    for (final t in transactions.where((t) => t.type == TransactionType.expense)) {
      final key = t.title.toLowerCase().trim();
      merchantTransactions.putIfAbsent(key, () => []);
      merchantTransactions[key]!.add(t);
    }

    // Find recurring patterns (same amount, monthly-ish frequency)
    merchantTransactions.forEach((merchant, txs) {
      if (txs.length >= 2) {
        final amounts = txs.map((t) => t.amount).toSet();
        if (amounts.length == 1) {
          // Same amount - likely a subscription
          final amount = amounts.first;
          final dates = txs.map((t) => t.date).toList()..sort();
          
          // Check if roughly monthly
          if (dates.length >= 2) {
            final avgDaysBetween = dates.last.difference(dates.first).inDays / (dates.length - 1);
            if (avgDaysBetween >= 25 && avgDaysBetween <= 35) {
              // Predict next renewal
              final lastDate = dates.last;
              final nextRenewal = DateTime(lastDate.year, lastDate.month + 1, lastDate.day);
              
              subscriptions.add(SubscriptionInfo(
                name: merchant,
                amount: amount,
                frequency: 'Monthly',
                nextRenewal: nextRenewal,
              ));
            }
          }
        }
      }
    });

    return subscriptions;
  }

  // Query patterns
  late final List<QueryPattern> _queryPatterns = [
    // Spending queries
    QueryPattern(
      keywords: ['spend', 'spent', 'spending', 'pay', 'paid', 'cost'],
      handler: (query, transactions, insights) {
        // Extract category if mentioned
        final categoryMatch = _extractCategory(query, transactions);
        final timeRange = _extractTimeRange(query);
        
        final cutoffDate = DateTime.now().subtract(Duration(days: timeRange.days));
        var filtered = transactions.where((t) => 
            t.type == TransactionType.expense && t.date.isAfter(cutoffDate));
        
        if (categoryMatch != null) {
          filtered = filtered.where((t) => 
              t.category.toLowerCase() == categoryMatch.toLowerCase());
        }

        final total = filtered.fold(0.0, (sum, t) => sum + t.amount);
        
        String message;
        if (categoryMatch != null) {
          message = "You spent \$${total.toStringAsFixed(2)} on $categoryMatch in the last ${timeRange.label}.";
        } else {
          message = "You spent \$${total.toStringAsFixed(2)} in the last ${timeRange.label}.";
        }

        return AIQueryResponse(
          type: ResponseType.spendingSummary,
          message: message,
          data: {'amount': total, 'category': categoryMatch, 'period': timeRange.label},
        );
      },
    ),

    // Income queries
    QueryPattern(
      keywords: ['earn', 'earned', 'income', 'salary', 'make', 'received'],
      handler: (query, transactions, insights) {
        final timeRange = _extractTimeRange(query);
        final cutoffDate = DateTime.now().subtract(Duration(days: timeRange.days));
        
        final total = transactions
            .where((t) => t.type == TransactionType.income && t.date.isAfter(cutoffDate))
            .fold(0.0, (sum, t) => sum + t.amount);

        return AIQueryResponse(
          type: ResponseType.incomeSummary,
          message: "You earned \$${total.toStringAsFixed(2)} in the last ${timeRange.label}.",
          data: {'amount': total, 'period': timeRange.label},
        );
      },
    ),

    // Balance queries
    QueryPattern(
      keywords: ['balance', 'left', 'remain', 'available', 'have', 'money'],
      handler: (query, transactions, insights) {
        final timeRange = _extractTimeRange(query);
        final cutoffDate = DateTime.now().subtract(Duration(days: timeRange.days));
        
        final income = transactions
            .where((t) => t.type == TransactionType.income && t.date.isAfter(cutoffDate))
            .fold(0.0, (sum, t) => sum + t.amount);
        
        final expenses = transactions
            .where((t) => t.type == TransactionType.expense && t.date.isAfter(cutoffDate))
            .fold(0.0, (sum, t) => sum + t.amount);

        final net = income - expenses;

        return AIQueryResponse(
          type: ResponseType.balance,
          message: "Your net ${net >= 0 ? 'savings' : 'deficit'} for the last ${timeRange.label} is \$${net.abs().toStringAsFixed(2)}.",
          data: {'net': net, 'income': income, 'expenses': expenses},
        );
      },
    ),

    // Top/Biggest queries
    QueryPattern(
      keywords: ['biggest', 'largest', 'top', 'most', 'highest'],
      handler: (query, transactions, insights) {
        final timeRange = _extractTimeRange(query);
        final cutoffDate = DateTime.now().subtract(Duration(days: timeRange.days));
        
        final expenses = transactions
            .where((t) => t.type == TransactionType.expense && t.date.isAfter(cutoffDate))
            .toList();

        if (expenses.isEmpty) {
          return AIQueryResponse(
            type: ResponseType.unknown,
            message: "No expenses found in the last ${timeRange.label}.",
          );
        }

        // Check if asking for category or transaction
        if (query.contains('category') || query.contains('categories')) {
          final categoryTotals = <String, double>{};
          for (final t in expenses) {
            categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
          }
          
          final sorted = categoryTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          
          final top = sorted.first;
          return AIQueryResponse(
            type: ResponseType.topCategory,
            message: "Your biggest spending category was ${top.key} at \$${top.value.toStringAsFixed(2)}.",
            data: {'category': top.key, 'amount': top.value},
          );
        } else {
          final biggest = expenses.reduce((a, b) => a.amount > b.amount ? a : b);
          return AIQueryResponse(
            type: ResponseType.topTransaction,
            message: "Your biggest expense was ${biggest.title} for \$${biggest.amount.toStringAsFixed(2)}.",
            data: {'transaction': biggest},
          );
        }
      },
    ),

    // Affordability queries
    QueryPattern(
      keywords: ['afford', 'buy', 'purchase', 'can i', 'should i'],
      handler: (query, transactions, insights) {
        // Try to extract amount
        final amountMatch = RegExp(r'\$?(\d+(?:,\d{3})*(?:\.\d{2})?)').firstMatch(query);
        if (amountMatch == null) {
          return AIQueryResponse(
            type: ResponseType.unknown,
            message: "I couldn't determine the amount you're asking about. Try mentioning a specific dollar amount.",
          );
        }

        final amount = double.parse(amountMatch.group(1)!.replaceAll(',', ''));
        final forecast = insights.predictSpending(transactions, daysAhead: 30);
        final monthlyIncome = _calculateMonthlyIncome(transactions);
        
        final remainingBudget = monthlyIncome - forecast.predictedAmount;
        final canAfford = remainingBudget >= amount;

        String message;
        if (canAfford) {
          message = "Based on your spending patterns, you should have \$${remainingBudget.toStringAsFixed(2)} left this month. A \$${amount.toStringAsFixed(2)} purchase seems manageable.";
        } else {
          message = "Based on your spending patterns, you might be tight on budget. You have about \$${remainingBudget.toStringAsFixed(2)} projected remaining, and this purchase is \$${amount.toStringAsFixed(2)}.";
        }

        return AIQueryResponse(
          type: ResponseType.affordability,
          message: message,
          data: {'canAfford': canAfford, 'amount': amount, 'remainingBudget': remainingBudget},
        );
      },
    ),

    // Summary queries
    QueryPattern(
      keywords: ['summary', 'overview', 'how am i doing', 'financial health'],
      handler: (query, transactions, insights) {
        final summary = generateSpendingSummary(transactions);
        return AIQueryResponse(
          type: ResponseType.summary,
          message: summary,
        );
      },
    ),
  ];

  String? _extractCategory(String query, List<Transaction> transactions) {
    final categories = transactions.map((t) => t.category).toSet();
    for (final category in categories) {
      if (query.contains(category.toLowerCase())) {
        return category;
      }
    }
    return null;
  }

  TimeRange _extractTimeRange(String query) {
    if (query.contains('year') || query.contains('annual')) {
      return TimeRange(days: 365, label: 'year');
    }
    if (query.contains('month')) {
      return TimeRange(days: 30, label: 'month');
    }
    if (query.contains('week')) {
      return TimeRange(days: 7, label: 'week');
    }
    if (query.contains('today')) {
      return TimeRange(days: 1, label: 'today');
    }
    // Default to last 30 days
    return TimeRange(days: 30, label: '30 days');
  }

  double _calculateMonthlyIncome(List<Transaction> transactions) {
    final income = transactions.where((t) => t.type == TransactionType.income);
    if (income.isEmpty) return 0;
    
    final totalIncome = income.fold(0.0, (sum, t) => sum + t.amount);
    final days = _calculateDateRange(transactions);
    return (totalIncome / days) * 30;
  }
}

// Supporting classes

class QueryPattern {
  final List<String> keywords;
  final AIQueryResponse Function(String, List<Transaction>, AIInsightsService) handler;

  QueryPattern({required this.keywords, required this.handler});

  bool matches(String query) {
    return keywords.any((keyword) => query.contains(keyword));
  }

  AIQueryResponse execute(String query, List<Transaction> transactions, AIInsightsService insights) {
    return handler(query, transactions, insights);
  }
}

class TimeRange {
  final int days;
  final String label;

  TimeRange({required this.days, required this.label});
}

class AIQueryResponse {
  final ResponseType type;
  final String message;
  final Map<String, dynamic>? data;
  final List<String>? suggestions;

  AIQueryResponse({
    required this.type,
    required this.message,
    this.data,
    this.suggestions,
  });
}

enum ResponseType {
  spendingSummary,
  incomeSummary,
  balance,
  topCategory,
  topTransaction,
  affordability,
  summary,
  unknown,
}

class SmartAlert {
  final AlertType type;
  final String title;
  final String message;
  final AlertSeverity severity;
  final Transaction? relatedTransaction;
  final DateTime timestamp;

  SmartAlert({
    required this.type,
    required this.title,
    required this.message,
    required this.severity,
    this.relatedTransaction,
    required this.timestamp,
  });
}

enum AlertType {
  unusualSpending,
  duplicateTransaction,
  budgetWarning,
  subscriptionRenewal,
}

enum AlertSeverity {
  info,
  warning,
  critical,
}

class SubscriptionInfo {
  final String name;
  final double amount;
  final String frequency;
  final DateTime nextRenewal;

  SubscriptionInfo({
    required this.name,
    required this.amount,
    required this.frequency,
    required this.nextRenewal,
  });
}
