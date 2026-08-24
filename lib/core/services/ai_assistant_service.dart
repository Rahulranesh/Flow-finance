import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/transaction_model.dart';
import 'ai_insights_service.dart';

/// AI Assistant for natural language financial queries
class AIAssistantService {
  final AIInsightsService _insightsService = AIInsightsService();

  /// Process query using Google Gemini Flash via REST API (with fallback to local AI)
  Future<AIQueryResponse> processQueryAsync(
      String query, List<Transaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('gemini_api_key');

    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        final contextSnippet = transactions.take(30).map((t) {
          final date = t.date.toIso8601String().split('T')[0];
          return '$date: ${t.title} ${t.amount} (${t.category})';
        }).join('; ');

        final prompt = 'You are Flow Finance AI, a smart personal finance advisor. '
            'Recent user transactions: [$contextSnippet]. '
            'Answer this query concisely: $query';

        final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/'
          'gemini-1.5-flash:generateContent?key=$apiKey',
        );

        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ]
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final first = candidates.first as Map<String, dynamic>?;
            final content = first?['content'] as Map<String, dynamic>?;
            final parts = content?['parts'] as List?;
            String? text;
            if (parts != null && parts.isNotEmpty) {
              final part = parts.first as Map<String, dynamic>?;
              text = part?['text'] as String?;
            }
            if (text != null && text.isNotEmpty) {
              return AIQueryResponse(
                type: ResponseType.summary,
                message: text,
              );
            }
          }
        }
      } catch (_) {
        // Fallback to local on-device statistical AI engine
      }
    }

    return processQuery(query, transactions);
  }

  /// Process a natural language query and return a response
  AIQueryResponse processQuery(String query, List<Transaction> transactions) {
    final normalizedQuery = query.toLowerCase().trim();

    for (final pattern in _queryPatterns) {
      if (pattern.matches(normalizedQuery)) {
        return pattern.execute(normalizedQuery, transactions, _insightsService);
      }
    }

    return AIQueryResponse(
      type: ResponseType.unknown,
      message:
          "I'm not sure how to answer that. Try asking about your spending, income, or budget.",
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

    final anomalies = _insightsService.detectAnomalies(transactions);
    for (final anomaly
        in anomalies.where((a) => a.severity == AnomalySeverity.high)) {
      alerts.add(SmartAlert(
        type: AlertType.unusualSpending,
        title: 'Unusual Spending Detected',
        message: anomaly.reason,
        severity: AlertSeverity.warning,
        relatedTransaction: anomaly.transaction,
        timestamp: DateTime.now(),
      ));
    }

    final duplicates = _findDuplicateTransactions(transactions);
    for (final duplicate in duplicates) {
      alerts.add(SmartAlert(
        type: AlertType.duplicateTransaction,
        title: 'Possible Duplicate Transaction',
        message:
            'We noticed a similar transaction: ${duplicate.title} for ${duplicate.amount}',
        severity: AlertSeverity.info,
        relatedTransaction: duplicate,
        timestamp: DateTime.now(),
      ));
    }

    final categorySpending =
        _calculateCategorySpending(transactions, days: 30);
    categorySpending.forEach((category, amount) {
      final avgMonthly =
          _calculateAverageMonthlySpending(transactions, category);
      if (avgMonthly > 0 && amount > avgMonthly * 0.9) {
        alerts.add(SmartAlert(
          type: AlertType.budgetWarning,
          title: 'Budget Warning',
          message:
              "You've spent ${amount.toStringAsFixed(0)} on $category, approaching your typical monthly amount of ${avgMonthly.toStringAsFixed(0)}",
          severity: AlertSeverity.info,
          timestamp: DateTime.now(),
        ));
      }
    });

    final subscriptions = _detectSubscriptions(transactions);
    for (final sub in subscriptions) {
      final daysUntilRenewal =
          sub.nextRenewal.difference(DateTime.now()).inDays;
      if (daysUntilRenewal <= 7 && daysUntilRenewal > 0) {
        alerts.add(SmartAlert(
          type: AlertType.subscriptionRenewal,
          title: 'Subscription Renewal',
          message:
              '${sub.name} will renew in $daysUntilRenewal days for ${sub.amount.toStringAsFixed(2)}',
          severity: AlertSeverity.info,
          timestamp: DateTime.now(),
        ));
      }
    }

    return alerts
      ..sort((a, b) => b.severity.index.compareTo(a.severity.index));
  }

  /// Get spending insights summary
  String generateSpendingSummary(List<Transaction> transactions,
      {int days = 30}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final recent =
        transactions.where((t) => t.date.isAfter(cutoffDate)).toList();

    if (recent.isEmpty) {
      return "I don't see any transactions in the last $days days.";
    }

    final totalSpent = recent
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalIncome = recent
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);

    final netSavings = totalIncome - totalSpent;
    final dailyAverage = totalSpent / days;

    final categorySpending =
        _calculateCategorySpending(transactions, days: days);
    String topCategory = 'Unknown';
    double topAmount = 0;
    categorySpending.forEach((cat, amount) {
      if (amount > topAmount) {
        topAmount = amount;
        topCategory = cat;
      }
    });

    return "In the last $days days, you spent ${totalSpent.toStringAsFixed(2)} "
        "(averaging ${dailyAverage.toStringAsFixed(2)}/day). "
        "Your biggest expense was $topCategory at ${topAmount.toStringAsFixed(2)}. "
        "You saved ${netSavings.toStringAsFixed(2)}.";
  }

  // ─── Private helpers ───────────────────────────────────────────────────────

  List<Transaction> _findDuplicateTransactions(
      List<Transaction> transactions) {
    final duplicates = <Transaction>[];
    final seen = <String>{};

    for (final t in transactions) {
      final key =
          '${t.amount.toStringAsFixed(2)}_${t.title.toLowerCase()}';
      if (seen.contains(key)) {
        final existing = transactions.firstWhere((tr) =>
            '${tr.amount.toStringAsFixed(2)}_${tr.title.toLowerCase()}' ==
            key);
        if (t.date.difference(existing.date).inDays.abs() <= 3) {
          duplicates.add(t);
        }
      } else {
        seen.add(key);
      }
    }

    return duplicates;
  }

  Map<String, double> _calculateCategorySpending(
      List<Transaction> transactions,
      {required int days}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final spending = <String, double>{};

    for (final t in transactions.where((t) =>
        t.type == TransactionType.expense && t.date.isAfter(cutoffDate))) {
      spending[t.category] = (spending[t.category] ?? 0) + t.amount;
    }

    return spending;
  }

  double _calculateAverageMonthlySpending(
      List<Transaction> transactions, String category) {
    final categoryTxs = transactions
        .where((t) =>
            t.category == category && t.type == TransactionType.expense)
        .toList();

    if (categoryTxs.isEmpty) return 0;

    final days = _calculateDateRange(transactions);
    final total = categoryTxs.fold(0.0, (sum, t) => sum + t.amount);
    return (total / days) * 30;
  }

  int _calculateDateRange(List<Transaction> transactions) {
    if (transactions.isEmpty) return 1;
    final dates = transactions.map((t) => t.date).toList();
    final earliest = dates.reduce((a, b) => a.isBefore(b) ? a : b);
    final latest = dates.reduce((a, b) => a.isAfter(b) ? a : b);
    return latest.difference(earliest).inDays + 1;
  }

  List<SubscriptionInfo> _detectSubscriptions(
      List<Transaction> transactions) {
    final subscriptions = <SubscriptionInfo>[];
    final merchantTxs = <String, List<Transaction>>{};

    for (final t
        in transactions.where((t) => t.type == TransactionType.expense)) {
      final key = t.title.toLowerCase().trim();
      merchantTxs.putIfAbsent(key, () => []);
      merchantTxs[key]!.add(t);
    }

    merchantTxs.forEach((merchant, txs) {
      if (txs.length >= 2) {
        final amounts = txs.map((t) => t.amount).toSet();
        if (amounts.length == 1) {
          final amount = amounts.first;
          final dates = txs.map((t) => t.date).toList()..sort();
          if (dates.length >= 2) {
            final avg = dates.last.difference(dates.first).inDays /
                (dates.length - 1);
            if (avg >= 25 && avg <= 35) {
              final last = dates.last;
              subscriptions.add(SubscriptionInfo(
                name: merchant,
                amount: amount,
                frequency: 'Monthly',
                nextRenewal:
                    DateTime(last.year, last.month + 1, last.day),
              ));
            }
          }
        }
      }
    });

    return subscriptions;
  }

  double _calculateMonthlyIncome(List<Transaction> transactions) {
    final income =
        transactions.where((t) => t.type == TransactionType.income);
    if (income.isEmpty) return 0;
    final total = income.fold(0.0, (sum, t) => sum + t.amount);
    final days = _calculateDateRange(transactions);
    return (total / days) * 30;
  }

  String? _extractCategory(String query, List<Transaction> transactions) {
    final categories = transactions.map((t) => t.category).toSet();
    for (final category in categories) {
      if (query.contains(category.toLowerCase())) return category;
    }
    return null;
  }

  TimeRange _extractTimeRange(String query) {
    if (query.contains('year') || query.contains('annual')) {
      return TimeRange(days: 365, label: 'year');
    }
    if (query.contains('month')) return TimeRange(days: 30, label: 'month');
    if (query.contains('week')) return TimeRange(days: 7, label: 'week');
    if (query.contains('today')) return TimeRange(days: 1, label: 'today');
    return TimeRange(days: 30, label: '30 days');
  }

  // ─── Query patterns ────────────────────────────────────────────────────────

  late final List<QueryPattern> _queryPatterns = [
    QueryPattern(
      keywords: ['spend', 'spent', 'spending', 'pay', 'paid', 'cost'],
      handler: (query, transactions, insights) {
        final categoryMatch = _extractCategory(query, transactions);
        final timeRange = _extractTimeRange(query);
        final cutoffDate =
            DateTime.now().subtract(Duration(days: timeRange.days));
        var filtered = transactions.where(
            (t) => t.type == TransactionType.expense && t.date.isAfter(cutoffDate));
        if (categoryMatch != null) {
          filtered = filtered.where((t) =>
              t.category.toLowerCase() == categoryMatch.toLowerCase());
        }
        final total = filtered.fold(0.0, (sum, t) => sum + t.amount);
        final msg = categoryMatch != null
            ? "You spent ${total.toStringAsFixed(2)} on $categoryMatch in the last ${timeRange.label}."
            : "You spent ${total.toStringAsFixed(2)} in the last ${timeRange.label}.";
        return AIQueryResponse(
          type: ResponseType.spendingSummary,
          message: msg,
          data: {
            'amount': total,
            'category': categoryMatch,
            'period': timeRange.label
          },
        );
      },
    ),
    QueryPattern(
      keywords: ['earn', 'earned', 'income', 'salary', 'make', 'received'],
      handler: (query, transactions, insights) {
        final timeRange = _extractTimeRange(query);
        final cutoffDate =
            DateTime.now().subtract(Duration(days: timeRange.days));
        final total = transactions
            .where((t) =>
                t.type == TransactionType.income &&
                t.date.isAfter(cutoffDate))
            .fold(0.0, (sum, t) => sum + t.amount);
        return AIQueryResponse(
          type: ResponseType.incomeSummary,
          message:
              "You earned ${total.toStringAsFixed(2)} in the last ${timeRange.label}.",
          data: {'amount': total, 'period': timeRange.label},
        );
      },
    ),
    QueryPattern(
      keywords: ['balance', 'left', 'remain', 'available', 'have', 'money'],
      handler: (query, transactions, insights) {
        final timeRange = _extractTimeRange(query);
        final cutoffDate =
            DateTime.now().subtract(Duration(days: timeRange.days));
        final income = transactions
            .where((t) =>
                t.type == TransactionType.income &&
                t.date.isAfter(cutoffDate))
            .fold(0.0, (sum, t) => sum + t.amount);
        final expenses = transactions
            .where((t) =>
                t.type == TransactionType.expense &&
                t.date.isAfter(cutoffDate))
            .fold(0.0, (sum, t) => sum + t.amount);
        final net = income - expenses;
        return AIQueryResponse(
          type: ResponseType.balance,
          message:
              "Your net ${net >= 0 ? 'savings' : 'deficit'} for the last ${timeRange.label} is ${net.abs().toStringAsFixed(2)}.",
          data: {'net': net, 'income': income, 'expenses': expenses},
        );
      },
    ),
    QueryPattern(
      keywords: ['biggest', 'largest', 'top', 'most', 'highest'],
      handler: (query, transactions, insights) {
        final timeRange = _extractTimeRange(query);
        final cutoffDate =
            DateTime.now().subtract(Duration(days: timeRange.days));
        final expenses = transactions
            .where((t) =>
                t.type == TransactionType.expense &&
                t.date.isAfter(cutoffDate))
            .toList();
        if (expenses.isEmpty) {
          return AIQueryResponse(
            type: ResponseType.unknown,
            message: "No expenses found in the last ${timeRange.label}.",
          );
        }
        if (query.contains('category') || query.contains('categories')) {
          final totals = <String, double>{};
          for (final t in expenses) {
            totals[t.category] = (totals[t.category] ?? 0) + t.amount;
          }
          final sorted = totals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final top = sorted.first;
          return AIQueryResponse(
            type: ResponseType.topCategory,
            message:
                "Your biggest spending category was ${top.key} at ${top.value.toStringAsFixed(2)}.",
            data: {'category': top.key, 'amount': top.value},
          );
        } else {
          final biggest =
              expenses.reduce((a, b) => a.amount > b.amount ? a : b);
          return AIQueryResponse(
            type: ResponseType.topTransaction,
            message:
                "Your biggest expense was ${biggest.title} for ${biggest.amount.toStringAsFixed(2)}.",
            data: {'transaction': biggest},
          );
        }
      },
    ),
    QueryPattern(
      keywords: ['afford', 'buy', 'purchase', 'can i', 'should i'],
      handler: (query, transactions, insights) {
        final amountMatch =
            RegExp(r'\$?(\d+(?:,\d{3})*(?:\.\d{2})?)').firstMatch(query);
        if (amountMatch == null) {
          return AIQueryResponse(
            type: ResponseType.unknown,
            message:
                "I couldn't determine the amount. Try mentioning a specific number.",
          );
        }
        final amount =
            double.parse(amountMatch.group(1)!.replaceAll(',', ''));
        final forecast =
            insights.predictSpending(transactions, daysAhead: 30);
        final monthlyIncome = _calculateMonthlyIncome(transactions);
        final remaining = monthlyIncome - forecast.predictedAmount;
        final canAfford = remaining >= amount;
        final msg = canAfford
            ? "Based on your spending patterns, you should have ${remaining.toStringAsFixed(2)} left this month. A ${amount.toStringAsFixed(2)} purchase seems manageable."
            : "Based on your spending patterns, you might be tight. You have about ${remaining.toStringAsFixed(2)} projected remaining and this purchase is ${amount.toStringAsFixed(2)}.";
        return AIQueryResponse(
          type: ResponseType.affordability,
          message: msg,
          data: {
            'canAfford': canAfford,
            'amount': amount,
            'remainingBudget': remaining
          },
        );
      },
    ),
    QueryPattern(
      keywords: [
        'summary',
        'overview',
        'how am i doing',
        'financial health'
      ],
      handler: (query, transactions, insights) {
        return AIQueryResponse(
          type: ResponseType.summary,
          message: generateSpendingSummary(transactions),
        );
      },
    ),
  ];
}

// ─── Supporting classes ───────────────────────────────────────────────────────

class QueryPattern {
  final List<String> keywords;
  final AIQueryResponse Function(
      String, List<Transaction>, AIInsightsService) handler;

  QueryPattern({required this.keywords, required this.handler});

  bool matches(String query) =>
      keywords.any((kw) => query.contains(kw));

  AIQueryResponse execute(String query, List<Transaction> transactions,
          AIInsightsService insights) =>
      handler(query, transactions, insights);
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

enum AlertSeverity { info, warning, critical }

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
