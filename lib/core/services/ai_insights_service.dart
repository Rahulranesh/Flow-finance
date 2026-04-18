import 'dart:math';
import '../../data/models/transaction_model.dart';

/// AI-powered insights and predictions for financial data
class AIInsightsService {
  /// Detect unusual spending patterns
  List<SpendingAnomaly> detectAnomalies(List<Transaction> transactions) {
    final anomalies = <SpendingAnomaly>[];
    final categoryStats = _calculateCategoryStats(transactions);

    for (final transaction in transactions) {
      if (transaction.type != TransactionType.expense) continue;

      final stats = categoryStats[transaction.category];
      if (stats == null) continue;

      // Check if amount is significantly higher than average (2 standard deviations)
      final zScore = (transaction.amount - stats.mean) / stats.stdDev;
      if (zScore > 2.0) {
        anomalies.add(SpendingAnomaly(
          transaction: transaction,
          severity: zScore > 3.0 ? AnomalySeverity.high : AnomalySeverity.medium,
          reason: '${transaction.category} spending is ${(transaction.amount / stats.mean).toStringAsFixed(1)}x higher than average',
        ));
      }
    }

    return anomalies..sort((a, b) => b.severity.index.compareTo(a.severity.index));
  }

  /// Predict spending for future periods
  SpendingForecast predictSpending(
    List<Transaction> transactions, {
    int daysAhead = 30,
  }) {
    final expenses = transactions.where((t) => t.type == TransactionType.expense).toList();
    
    if (expenses.isEmpty) {
      return SpendingForecast(
        predictedAmount: 0,
        confidence: 0,
        breakdown: {},
      );
    }

    // Calculate daily averages by category
    final categoryDailyAvg = <String, double>{};
    final daysOfData = _calculateDaysOfData(expenses);
    
    final categoryTotals = <String, double>{};
    for (final t in expenses) {
      categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
    }

    categoryTotals.forEach((category, total) {
      categoryDailyAvg[category] = total / max(daysOfData, 1);
    });

    // Predict for future period
    final predictedBreakdown = <String, double>{};
    double totalPrediction = 0;

    categoryDailyAvg.forEach((category, dailyAvg) {
      // Apply seasonal adjustment if enough data
      final seasonalFactor = _calculateSeasonalFactor(expenses, category);
      final prediction = dailyAvg * daysAhead * seasonalFactor;
      predictedBreakdown[category] = prediction;
      totalPrediction += prediction;
    });

    // Calculate confidence based on data quality
    final confidence = _calculateConfidence(expenses, daysOfData);

    return SpendingForecast(
      predictedAmount: totalPrediction,
      confidence: confidence,
      breakdown: predictedBreakdown,
    );
  }

  /// Generate personalized budget recommendations
  List<BudgetRecommendation> generateBudgetRecommendations(
    List<Transaction> transactions,
    Map<String, double> currentBudgets,
  ) {
    final recommendations = <BudgetRecommendation>[];
    final categoryStats = _calculateCategoryStats(transactions);
    final monthlyIncome = _calculateMonthlyIncome(transactions);

    categoryStats.forEach((category, stats) {
      final currentBudget = currentBudgets[category] ?? 0;
      final recommendedBudget = stats.mean * 1.2; // 20% buffer above average

      if (currentBudget == 0) {
        // No budget set - recommend one
        recommendations.add(BudgetRecommendation(
          category: category,
          currentBudget: 0,
          recommendedBudget: recommendedBudget,
          reason: 'Based on your spending pattern, consider setting a \$${recommendedBudget.toStringAsFixed(0)} monthly budget',
          priority: RecommendationPriority.high,
        ));
      } else if (currentBudget < stats.mean) {
        // Budget too tight
        recommendations.add(BudgetRecommendation(
          category: category,
          currentBudget: currentBudget,
          recommendedBudget: recommendedBudget,
          reason: 'You consistently exceed this budget. Consider increasing to \$${recommendedBudget.toStringAsFixed(0)}',
          priority: RecommendationPriority.medium,
        ));
      } else if (currentBudget > stats.mean * 2) {
        // Budget too loose
        final tighterBudget = stats.mean * 1.3;
        recommendations.add(BudgetRecommendation(
          category: category,
          currentBudget: currentBudget,
          recommendedBudget: tighterBudget,
          reason: 'You have significant room to save. Try reducing to \$${tighterBudget.toStringAsFixed(0)}',
          priority: RecommendationPriority.low,
        ));
      }
    });

    // Add savings recommendation
    final currentSavingsRate = _calculateSavingsRate(transactions);
    if (currentSavingsRate < 0.2) {
      recommendations.add(BudgetRecommendation(
        category: 'Savings',
        currentBudget: monthlyIncome * currentSavingsRate,
        recommendedBudget: monthlyIncome * 0.2,
        reason: 'Aim to save at least 20% of your income (\$${(monthlyIncome * 0.2).toStringAsFixed(0)})',
        priority: RecommendationPriority.high,
      ));
    }

    return recommendations..sort((a, b) => a.priority.index.compareTo(b.priority.index));
  }

  /// Predict cash flow for upcoming periods
  CashFlowPrediction predictCashFlow(
    List<Transaction> transactions, {
    int periods = 3,
    String periodType = 'month',
  }) {
    final now = DateTime.now();
    final predictions = <PeriodCashFlow>[];

    for (int i = 1; i <= periods; i++) {
      DateTime periodStart;
      DateTime periodEnd;

      switch (periodType) {
        case 'week':
          periodStart = now.add(Duration(days: 7 * (i - 1)));
          periodEnd = periodStart.add(const Duration(days: 6));
          break;
        case 'month':
        default:
          periodStart = DateTime(now.year, now.month + i, 1);
          periodEnd = DateTime(now.year, now.month + i + 1, 0);
          break;
      }

      // Predict income (recurring + estimated)
      final predictedIncome = _predictIncome(transactions, periodStart, periodEnd);
      
      // Predict expenses (recurring + forecasted)
      final predictedExpenses = _predictExpenses(transactions, periodStart, periodEnd);

      predictions.add(PeriodCashFlow(
        startDate: periodStart,
        endDate: periodEnd,
        predictedIncome: predictedIncome,
        predictedExpenses: predictedExpenses,
        netCashFlow: predictedIncome - predictedExpenses,
      ));
    }

    return CashFlowPrediction(
      periods: predictions,
      overallTrend: _calculateOverallTrend(predictions),
    );
  }

  /// Calculate financial health score
  FinancialHealthScore calculateHealthScore(
    List<Transaction> transactions,
    List<FinancialGoal> goals,
  ) {
    final scores = <HealthCategory, double>{};

    // Savings rate score (0-100)
    final savingsRate = _calculateSavingsRate(transactions);
    scores[HealthCategory.savings] = min(savingsRate * 400, 100); // 25% = 100 points

    // Spending consistency score
    final consistencyScore = _calculateSpendingConsistency(transactions);
    scores[HealthCategory.consistency] = consistencyScore;

    // Goal progress score
    final goalScore = _calculateGoalProgress(goals);
    scores[HealthCategory.goals] = goalScore;

    // Emergency fund score (3 months expenses = 100)
    final emergencyFundMonths = _calculateEmergencyFundMonths(transactions);
    scores[HealthCategory.emergencyFund] = min(emergencyFundMonths * 33.33, 100);

    // Overall score
    final overallScore = scores.values.reduce((a, b) => a + b) / scores.length;

    // Generate recommendations
    final recommendations = <String>[];
    if (scores[HealthCategory.savings]! < 50) {
      recommendations.add('Increase your savings rate to at least 20% of income');
    }
    if (scores[HealthCategory.emergencyFund]! < 50) {
      recommendations.add('Build an emergency fund covering 3-6 months of expenses');
    }
    if (scores[HealthCategory.consistency]! < 70) {
      recommendations.add('Your spending is inconsistent. Try creating a budget');
    }

    return FinancialHealthScore(
      overallScore: overallScore.round(),
      categoryScores: scores,
      recommendations: recommendations,
      lastUpdated: DateTime.now(),
    );
  }

  // Private helper methods

  Map<String, CategoryStats> _calculateCategoryStats(List<Transaction> transactions) {
    final byCategory = <String, List<double>>{};

    for (final t in transactions.where((t) => t.type == TransactionType.expense)) {
      byCategory.putIfAbsent(t.category, () => []);
      byCategory[t.category]!.add(t.amount);
    }

    final stats = <String, CategoryStats>{};
    byCategory.forEach((category, amounts) {
      final mean = amounts.reduce((a, b) => a + b) / amounts.length;
      final variance = amounts.map((a) => pow(a - mean, 2)).reduce((a, b) => a + b) / amounts.length;
      final stdDev = sqrt(variance);

      stats[category] = CategoryStats(
        mean: mean,
        stdDev: stdDev > 0 ? stdDev : 1, // Avoid division by zero
        count: amounts.length,
      );
    });

    return stats;
  }

  int _calculateDaysOfData(List<Transaction> transactions) {
    if (transactions.isEmpty) return 0;
    final dates = transactions.map((t) => t.date).toList();
    final earliest = dates.reduce((a, b) => a.isBefore(b) ? a : b);
    final latest = dates.reduce((a, b) => a.isAfter(b) ? a : b);
    return latest.difference(earliest).inDays + 1;
  }

  double _calculateSeasonalFactor(List<Transaction> transactions, String category) {
    // Simple seasonal adjustment based on day of week/month
    // In a real implementation, this would use more sophisticated ML
    return 1.0;
  }

  double _calculateConfidence(List<Transaction> transactions, int daysOfData) {
    // More data = higher confidence
    if (daysOfData < 30) return 0.3;
    if (daysOfData < 90) return 0.6;
    if (daysOfData < 365) return 0.8;
    return 0.95;
  }

  double _calculateMonthlyIncome(List<Transaction> transactions) {
    final income = transactions.where((t) => t.type == TransactionType.income);
    if (income.isEmpty) return 0;
    final totalIncome = income.fold(0.0, (sum, t) => sum + t.amount);
    final days = _calculateDaysOfData(transactions);
    return totalIncome / max(days, 1) * 30;
  }

  double _calculateSavingsRate(List<Transaction> transactions) {
    double income = 0;
    double expenses = 0;

    for (final t in transactions) {
      if (t.type == TransactionType.income) {
        income += t.amount;
      } else {
        expenses += t.amount;
      }
    }

    if (income == 0) return 0;
    return (income - expenses) / income;
  }

  double _calculateSpendingConsistency(List<Transaction> transactions) {
    final expenses = transactions.where((t) => t.type == TransactionType.expense).toList();
    if (expenses.length < 10) return 50;

    final dailyTotals = <DateTime, double>{};
    for (final t in expenses) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      dailyTotals[day] = (dailyTotals[day] ?? 0) + t.amount;
    }

    final amounts = dailyTotals.values.toList();
    final mean = amounts.reduce((a, b) => a + b) / amounts.length;
    final variance = amounts.map((a) => pow(a - mean, 2)).reduce((a, b) => a + b) / amounts.length;
    final cv = sqrt(variance) / mean; // Coefficient of variation

    // Lower CV = more consistent = higher score
    return max(0, 100 - (cv * 50));
  }

  double _calculateGoalProgress(List<FinancialGoal> goals) {
    if (goals.isEmpty) return 100;
    final progressValues = goals.map((g) => g.progressPercentage).toList();
    return progressValues.reduce((a, b) => a + b) / progressValues.length;
  }

  double _calculateEmergencyFundMonths(List<Transaction> transactions) {
    // This would require knowing the user's savings balance
    // For now, return an estimate based on savings rate
    final savingsRate = _calculateSavingsRate(transactions);
    return savingsRate * 12; // Rough estimate
  }

  double _predictIncome(List<Transaction> transactions, DateTime start, DateTime end) {
    // Find recurring income patterns
    final incomeTransactions = transactions.where((t) => t.type == TransactionType.income).toList();
    if (incomeTransactions.isEmpty) return 0;

    // Simple average for now
    final totalIncome = incomeTransactions.fold(0.0, (sum, t) => sum + t.amount);
    final days = _calculateDaysOfData(transactions);
    final dailyAvg = totalIncome / max(days, 1);
    
    return dailyAvg * end.difference(start).inDays;
  }

  double _predictExpenses(List<Transaction> transactions, DateTime start, DateTime end) {
    final forecast = predictSpending(transactions, daysAhead: end.difference(start).inDays);
    return forecast.predictedAmount;
  }

  CashFlowTrend _calculateOverallTrend(List<PeriodCashFlow> periods) {
    if (periods.length < 2) return CashFlowTrend.stable;

    final firstHalf = periods.take(periods.length ~/ 2).map((p) => p.netCashFlow).reduce((a, b) => a + b);
    final secondHalf = periods.skip(periods.length ~/ 2).map((p) => p.netCashFlow).reduce((a, b) => a + b);

    final change = (secondHalf - firstHalf) / firstHalf.abs();
    if (change > 0.1) return CashFlowTrend.improving;
    if (change < -0.1) return CashFlowTrend.declining;
    return CashFlowTrend.stable;
  }
}

// Data models for AI insights

class SpendingAnomaly {
  final Transaction transaction;
  final AnomalySeverity severity;
  final String reason;

  SpendingAnomaly({
    required this.transaction,
    required this.severity,
    required this.reason,
  });
}

enum AnomalySeverity { low, medium, high }

class SpendingForecast {
  final double predictedAmount;
  final double confidence;
  final Map<String, double> breakdown;

  SpendingForecast({
    required this.predictedAmount,
    required this.confidence,
    required this.breakdown,
  });
}

class BudgetRecommendation {
  final String category;
  final double currentBudget;
  final double recommendedBudget;
  final String reason;
  final RecommendationPriority priority;

  BudgetRecommendation({
    required this.category,
    required this.currentBudget,
    required this.recommendedBudget,
    required this.reason,
    required this.priority,
  });
}

enum RecommendationPriority { low, medium, high }

class CashFlowPrediction {
  final List<PeriodCashFlow> periods;
  final CashFlowTrend overallTrend;

  CashFlowPrediction({
    required this.periods,
    required this.overallTrend,
  });
}

class PeriodCashFlow {
  final DateTime startDate;
  final DateTime endDate;
  final double predictedIncome;
  final double predictedExpenses;
  final double netCashFlow;

  PeriodCashFlow({
    required this.startDate,
    required this.endDate,
    required this.predictedIncome,
    required this.predictedExpenses,
    required this.netCashFlow,
  });
}

enum CashFlowTrend { improving, stable, declining }

class FinancialHealthScore {
  final int overallScore;
  final Map<HealthCategory, double> categoryScores;
  final List<String> recommendations;
  final DateTime lastUpdated;

  FinancialHealthScore({
    required this.overallScore,
    required this.categoryScores,
    required this.recommendations,
    required this.lastUpdated,
  });

  String get rating {
    if (overallScore >= 90) return 'Excellent';
    if (overallScore >= 80) return 'Very Good';
    if (overallScore >= 70) return 'Good';
    if (overallScore >= 60) return 'Fair';
    return 'Needs Improvement';
  }
}

enum HealthCategory { savings, consistency, goals, emergencyFund }

class FinancialGoal {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;

  FinancialGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
  });

  double get progressPercentage => (currentAmount / targetAmount * 100).clamp(0, 100);
}

class CategoryStats {
  final double mean;
  final double stdDev;
  final int count;

  CategoryStats({
    required this.mean,
    required this.stdDev,
    required this.count,
  });
}
