import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.chart_pie,
                size: 64,
                color: isDark
                    ? AppColors.textSecondaryDark.withOpacity(0.5)
                    : AppColors.textSecondaryLight.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No data available'.tr(),
                style: AppTypography.bodyMedium(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final total = categoryData.values.fold(0.0, (sum, amount) => sum + amount);
    final topCategory = categoryData.entries.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Spend Category Banner Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getCategoryColor(topCategory.key).withOpacity(0.15),
                AppColors.primary.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getCategoryColor(topCategory.key).withOpacity(0.25),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _getCategoryColor(topCategory.key).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: _getCategoryColor(topCategory.key),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top spend category'.tr(),
                      style: AppTypography.labelSmall(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${topCategory.key} • ${topCategory.value.toCurrency(decimalDigits: 0)}',
                      style: AppTypography.titleMedium(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ).copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Donut Chart with Center Display
        SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 65,
                  sections: categoryData.entries.map((entry) {
                    final percentage = total > 0 ? (entry.value / total) * 100 : 0.0;
                    final color = _getCategoryColor(entry.key);

                    return PieChartSectionData(
                      color: color,
                      value: entry.value,
                      title: percentage >= 10 ? '${percentage.toStringAsFixed(0)}%' : '',
                      radius: 36,
                      titleStyle: AppTypography.labelSmall(
                        color: Colors.white,
                      ).copyWith(fontWeight: FontWeight.bold),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        width: 2,
                      ),
                    );
                  }).toList(),
                  pieTouchData: PieTouchData(enabled: true),
                ),
              ),
              // Center info display
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total Expenses'.tr(),
                      style: AppTypography.labelSmall(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        total.toCurrency(decimalDigits: 0),
                        style: AppTypography.titleLarge(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Category Progress Breakdown List
        Column(
          children: categoryData.entries.map((entry) {
            final percentage = total > 0 ? (entry.value / total) * 100 : 0.0;
            final color = _getCategoryColor(entry.key);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceDark.withOpacity(0.6)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark.withOpacity(0.5)
                        : AppColors.borderLight.withOpacity(0.8),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: AppTypography.bodyMedium(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          entry.value.toCurrency(decimalDigits: 0),
                          style: AppTypography.bodyMedium(
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${percentage.toStringAsFixed(1)}%)',
                          style: AppTypography.labelSmall(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (percentage / 100).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: color.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
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
      const Color(0xFFE7B416), // Gold
      const Color(0xFF6B7280), // Grey
      const Color(0xFFC7A252), // Muted gold
      const Color(0xFF6B7280), // Slate
      const Color(0xFFD1D5DB), // Light grey
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
      const Color(0xFFE7B416),
      const Color(0xFF6B7280),
      const Color(0xFFC7A252),
    ];

    int hash = 0;
    for (var i = 0; i < category.length; i++) {
      hash = category.codeUnitAt(i) + ((hash << 5) - hash);
    }

    return colors[hash.abs() % colors.length];
  }
}
