import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/transaction_model.dart';

/// Pie chart showing expense breakdown by category
class CategoryPieChart extends StatelessWidget {
  final List<Transaction> transactions;
  final bool showLabels;
  final double radius;

  const CategoryPieChart({
    super.key,
    required this.transactions,
    this.showLabels = true,
    this.radius = 100,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryData = _getCategoryData();

    if (categoryData.isEmpty) {
      return Center(
        child: Text(
          'No data available'.tr(),
          style: AppTypography.bodyMedium(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      );
    }

    final total = categoryData.values.fold(0.0, (sum, amount) => sum + amount);

    return Column(
      children: [
        SizedBox(
          height: radius * 2 + 40,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: categoryData.entries.map((entry) {
                final percentage = (entry.value / total) * 100;
                final color = _getCategoryColor(entry.key);

                return PieChartSectionData(
                  color: color,
                  value: entry.value,
                  title: showLabels && percentage > 5
                      ? '${percentage.toStringAsFixed(0)}%'
                      : '',
                  radius: radius,
                  titleStyle: AppTypography.labelSmall(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  badgeWidget:
                      percentage > 10 ? _buildBadge(entry.key, color) : null,
                  badgePositionPercentageOffset: 1.2,
                );
              }).toList(),
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                enabled: true,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Category Legend
        Wrap(
          spacing: 16,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: categoryData.entries.map((entry) {
            final percentage = (entry.value / total) * 100;
            return _buildLegendItem(
              entry.key,
              _getCategoryColor(entry.key),
              entry.value,
              percentage,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBadge(String category, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        category,
        style: AppTypography.labelSmall(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLegendItem(
    String category,
    Color color,
    double amount,
    double percentage,
  ) {
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
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              category,
              style: AppTypography.bodySmall(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${amount.toCurrency(decimalDigits: 0)} (${percentage.toStringAsFixed(1)}%)',
              style: AppTypography.labelSmall(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Map<String, double> _getCategoryData() {
    final data = <String, double>{};

    for (final transaction in transactions) {
      if (transaction.type == TransactionType.expense) {
        data[transaction.category] =
            (data[transaction.category] ?? 0) + transaction.amount;
      }
    }

    // Sort by amount descending
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries);
  }

  Color _getCategoryColor(String category) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.success,
      AppColors.warning,
      AppColors.error,
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFFFF9800), // Orange
      const Color(0xFF795548), // Brown
      const Color(0xFF607D8B), // Blue Grey
    ];

    // Generate consistent color based on category name
    int hash = 0;
    for (var i = 0; i < category.length; i++) {
      hash = category.codeUnitAt(i) + ((hash << 5) - hash);
    }

    return colors[hash.abs() % colors.length];
  }
}

/// Donut chart variant
class CategoryDonutChart extends StatelessWidget {
  final List<Transaction> transactions;
  final String centerText;

  const CategoryDonutChart({
    super.key,
    required this.transactions,
    this.centerText = '',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryData = _getCategoryData();

    if (categoryData.isEmpty) {
      return Center(
        child: Text(
          'No data available'.tr(),
          style: AppTypography.bodyMedium(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 60,
            sections: categoryData.entries.map((entry) {
              return PieChartSectionData(
                color: _getCategoryColor(entry.key),
                value: entry.value,
                title: '',
                radius: 80,
              );
            }).toList(),
          ),
        ),
        if (centerText.isNotEmpty)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerText,
                style: AppTypography.titleLarge(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              Text(
                'Total'.tr(),
                style: AppTypography.bodySmall(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Map<String, double> _getCategoryData() {
    final data = <String, double>{};

    for (final transaction in transactions) {
      if (transaction.type == TransactionType.expense) {
        data[transaction.category] =
            (data[transaction.category] ?? 0) + transaction.amount;
      }
    }

    return data;
  }

  Color _getCategoryColor(String category) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.success,
      AppColors.warning,
      AppColors.error,
      const Color(0xFF9C27B0),
      const Color(0xFF00BCD4),
      const Color(0xFFFF9800),
    ];

    int hash = 0;
    for (var i = 0; i < category.length; i++) {
      hash = category.codeUnitAt(i) + ((hash << 5) - hash);
    }

    return colors[hash.abs() % colors.length];
  }
}
