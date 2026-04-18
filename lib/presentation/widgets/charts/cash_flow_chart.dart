import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/transaction_model.dart';

/// Bar chart comparing income vs expenses
class CashFlowChart extends StatelessWidget {
  final List<Transaction> transactions;
  final DateTime startDate;
  final DateTime endDate;
  final bool showDaily;

  const CashFlowChart({
    super.key,
    required this.transactions,
    required this.startDate,
    required this.endDate,
    this.showDaily = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barGroups = _getBarGroups();

    if (barGroups.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: AppTypography.bodyMedium(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      );
    }

    return Column(
      children: [
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('Income', AppColors.success),
            const SizedBox(width: 24),
            _buildLegendItem('Expense', AppColors.error),
          ],
        ),
        const SizedBox(height: 16),

        // Chart
        SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: _getMaxY(),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => isDark
                      ? AppColors.surfaceDark
                      : AppColors.surfaceLight,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final isIncome = rodIndex == 0;
                    return BarTooltipItem(
                      '${isIncome ? 'Income' : 'Expense'}\n',
                      AppTypography.labelSmall(
                        color: isIncome ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: '\$${rod.toY.toStringAsFixed(2)}',
                          style: AppTypography.bodySmall(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '\$${value.toStringAsFixed(0)}',
                        style: AppTypography.labelSmall(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= barGroups.length) {
                        return const SizedBox.shrink();
                      }

                      final date = _getDateForIndex(index);
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          showDaily
                              ? '${date.month}/${date.day}'
                              : _getMonthAbbreviation(date.month),
                          style: AppTypography.labelSmall(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: _getHorizontalInterval(),
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(show: false),
              barGroups: barGroups,
            ),
          ),
        ),

        // Summary
        const SizedBox(height: 24),
        _buildSummary(context),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTypography.bodySmall(),
        ),
      ],
    );
  }

  Widget _buildSummary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    double totalIncome = 0;
    double totalExpense = 0;

    for (final transaction in transactions) {
      if (transaction.type == TransactionType.income) {
        totalIncome += transaction.amount;
      } else if (transaction.type == TransactionType.expense) {
        totalExpense += transaction.amount;
      }
    }

    final balance = totalIncome - totalExpense;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              'Income',
              totalIncome,
              AppColors.success,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          Expanded(
            child: _buildSummaryItem(
              'Expense',
              totalExpense,
              AppColors.error,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          Expanded(
            child: _buildSummaryItem(
              'Balance',
              balance,
              balance >= 0 ? AppColors.primary : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.labelSmall(
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '\$${amount.toStringAsFixed(0)}',
          style: AppTypography.titleSmall(
            color: color,
          ).copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  List<BarChartGroupData> _getBarGroups() {
    if (showDaily) {
      return _getDailyBarGroups();
    } else {
      return _getMonthlyBarGroups();
    }
  }

  List<BarChartGroupData> _getDailyBarGroups() {
    final data = <DateTime, Map<String, double>>{};

    // Initialize all days in range
    var current = startDate;
    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      data[DateTime(current.year, current.month, current.day)] = {
        'income': 0,
        'expense': 0,
      };
      current = current.add(const Duration(days: 1));
    }

    // Aggregate transactions
    for (final transaction in transactions) {
      final date = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );

      if (data.containsKey(date)) {
        if (transaction.type == TransactionType.income) {
          data[date]!['income'] =
              (data[date]!['income'] ?? 0) + transaction.amount;
        } else if (transaction.type == TransactionType.expense) {
          data[date]!['expense'] =
              (data[date]!['expense'] ?? 0) + transaction.amount;
        }
      }
    }

    // Create bar groups
    final sortedDates = data.keys.toList()..sort();
    return sortedDates.asMap().entries.map((entry) {
      final index = entry.key;
      final date = entry.value;
      final values = data[date]!;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: values['income'] ?? 0,
            color: AppColors.success,
            width: 8,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
            ),
          ),
          BarChartRodData(
            toY: values['expense'] ?? 0,
            color: AppColors.error,
            width: 8,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();
  }

  List<BarChartGroupData> _getMonthlyBarGroups() {
    final data = <String, Map<String, double>>{};

    // Aggregate by month
    for (final transaction in transactions) {
      final monthKey = '${transaction.date.year}-${transaction.date.month}';

      data.putIfAbsent(monthKey, () => {'income': 0, 'expense': 0});

      if (transaction.type == TransactionType.income) {
        data[monthKey]!['income'] =
            (data[monthKey]!['income'] ?? 0) + transaction.amount;
      } else if (transaction.type == TransactionType.expense) {
        data[monthKey]!['expense'] =
            (data[monthKey]!['expense'] ?? 0) + transaction.amount;
      }
    }

    // Create bar groups
    final sortedMonths = data.keys.toList()..sort();
    return sortedMonths.asMap().entries.map((entry) {
      final index = entry.key;
      final monthKey = entry.value;
      final values = data[monthKey]!;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: values['income'] ?? 0,
            color: AppColors.success,
            width: 16,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
            ),
          ),
          BarChartRodData(
            toY: values['expense'] ?? 0,
            color: AppColors.error,
            width: 16,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();
  }

  DateTime _getDateForIndex(int index) {
    if (showDaily) {
      return startDate.add(Duration(days: index));
    } else {
      // For monthly, return first day of that month
      return DateTime(startDate.year, startDate.month + index, 1);
    }
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  double _getMaxY() {
    double max = 0;
    for (final transaction in transactions) {
      if (transaction.amount > max) {
        max = transaction.amount;
      }
    }
    return max * 1.2;
  }

  double _getHorizontalInterval() {
    return _getMaxY() / 5;
  }
}
