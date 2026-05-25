import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/transaction_model.dart';

/// Line chart showing income/expense trends over time
class TrendChart extends StatelessWidget {
  final List<Transaction> transactions;
  final DateTime startDate;
  final DateTime endDate;
  final bool showIncome;
  final bool showExpense;
  final bool showBalance;

  const TrendChart({
    super.key,
    required this.transactions,
    required this.startDate,
    required this.endDate,
    this.showIncome = true,
    this.showExpense = true,
    this.showBalance = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final incomeData = _getIncomeData();
    final expenseData = _getExpenseData();
    final balanceData = _getBalanceData();
    final netFlow = transactions.fold<double>(0, (sum, transaction) {
      if (transaction.type == TransactionType.income) {
        return sum + transaction.amount;
      }
      if (transaction.type == TransactionType.expense) {
        return sum - transaction.amount;
      }
      return sum;
    });

    return Column(
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            _buildInsightChip(
              context,
              'Net trend'.tr(),
              netFlow.toCurrency(decimalDigits: 0),
              netFlow >= 0 ? AppColors.success : AppColors.error,
            ),
            _buildInsightChip(
              context,
              'Transactions'.tr(),
              '${transactions.length}',
              AppColors.primary,
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showIncome) _buildLegendItem('Income'.tr(), AppColors.success),
            if (showExpense) ...[
              const SizedBox(width: 16),
              _buildLegendItem('Expense'.tr(), AppColors.error),
            ],
            if (showBalance) ...[
              const SizedBox(width: 16),
              _buildLegendItem('Balance'.tr(), AppColors.primary),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // Chart
        SizedBox(
          height: 250,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: _getHorizontalInterval(),
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  axisNameWidget: Text(
                    'Amount',
                    style: AppTypography.labelSmall(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  axisNameSize: 20,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toCurrency(decimalDigits: 0),
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
                  axisNameWidget: Text(
                    'Date',
                    style: AppTypography.labelSmall(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  axisNameSize: 20,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                      final date =
                          DateTime.fromMillisecondsSinceEpoch(value.toInt());
                      final interval = _getBottomLabelInterval();
                      final index = meta.appliedInterval == 0
                          ? 0
                          : ((value - meta.min) / meta.appliedInterval).round();
                      if (index % interval != 0 &&
                          value != meta.min &&
                          value != meta.max) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${date.month}/${date.day}',
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
              borderData: FlBorderData(show: false),
              lineBarsData: [
                if (showIncome && incomeData.isNotEmpty)
                  _buildLineBarData(
                    incomeData,
                    AppColors.success,
                    isCurved: true,
                  ),
                if (showExpense && expenseData.isNotEmpty)
                  _buildLineBarData(
                    expenseData,
                    AppColors.error,
                    isCurved: true,
                  ),
                if (showBalance && balanceData.isNotEmpty)
                  _buildLineBarData(
                    balanceData,
                    AppColors.primary,
                    isCurved: false,
                    showDots: true,
                  ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (lineSpot) =>
                      isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      return LineTooltipItem(
                        spot.y.toCurrency(),
                        AppTypography.bodySmall(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.bodySmall(),
        ),
      ],
    );
  }

  Widget _buildInsightChip(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall(
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.bodyMedium(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _buildLineBarData(
    List<FlSpot> spots,
    Color color, {
    bool isCurved = true,
    bool showDots = false,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: isCurved,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(show: showDots),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.1),
      ),
    );
  }

  List<FlSpot> _getIncomeData() {
    final data = <DateTime, double>{};

    for (final transaction in transactions) {
      if (transaction.type == TransactionType.income) {
        final date = DateTime(
          transaction.date.year,
          transaction.date.month,
          transaction.date.day,
        );
        data[date] = (data[date] ?? 0) + transaction.amount;
      }
    }

    return _convertToSpots(data);
  }

  List<FlSpot> _getExpenseData() {
    final data = <DateTime, double>{};

    for (final transaction in transactions) {
      if (transaction.type == TransactionType.expense) {
        final date = DateTime(
          transaction.date.year,
          transaction.date.month,
          transaction.date.day,
        );
        data[date] = (data[date] ?? 0) + transaction.amount;
      }
    }

    return _convertToSpots(data);
  }

  List<FlSpot> _getBalanceData() {
    final data = <DateTime, double>{};
    double runningBalance = 0;

    // Sort transactions by date
    final sortedTransactions = List<Transaction>.from(transactions)
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final transaction in sortedTransactions) {
      final date = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );

      if (transaction.type == TransactionType.income) {
        runningBalance += transaction.amount;
      } else if (transaction.type == TransactionType.expense) {
        runningBalance -= transaction.amount;
      }

      data[date] = runningBalance;
    }

    return _convertToSpots(data);
  }

  List<FlSpot> _convertToSpots(Map<DateTime, double> data) {
    if (data.isEmpty) return [];

    final sortedDates = data.keys.toList()..sort();
    return sortedDates.map((date) {
      return FlSpot(
        date.millisecondsSinceEpoch.toDouble(),
        data[date] ?? 0,
      );
    }).toList();
  }

  double _getHorizontalInterval() {
    final allAmounts = transactions.map((t) => t.amount).toList();
    if (allAmounts.isEmpty) return 100;

    final maxAmount = allAmounts.reduce((a, b) => a > b ? a : b);
    return maxAmount / 5;
  }

  int _getBottomLabelInterval() {
    final span = endDate.difference(startDate).inDays;
    if (span <= 10) return 1;
    if (span <= 31) return 3;
    if (span <= 90) return 7;
    return 14;
  }
}

/// Weekly trend chart widget
class WeeklyTrendChart extends StatelessWidget {
  final List<Transaction> transactions;

  const WeeklyTrendChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return TrendChart(
      transactions: transactions.where((t) {
        return t.date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
            t.date.isBefore(endOfWeek.add(const Duration(days: 1)));
      }).toList(),
      startDate: startOfWeek,
      endDate: endOfWeek,
    );
  }
}

/// Monthly trend chart widget
class MonthlyTrendChart extends StatelessWidget {
  final List<Transaction> transactions;

  const MonthlyTrendChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    return TrendChart(
      transactions: transactions.where((t) {
        return t.date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
            t.date.isBefore(endOfMonth.add(const Duration(days: 1)));
      }).toList(),
      startDate: startOfMonth,
      endDate: endOfMonth,
    );
  }
}
