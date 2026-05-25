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
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pie_chart_outline,
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
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getCategoryColor(topCategory.key).withOpacity(0.16),
                AppColors.primary.withOpacity(0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _getCategoryColor(topCategory.key).withOpacity(0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: _getCategoryColor(topCategory.key),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top spend category'.tr(),
                      style: AppTypography.labelMedium(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${topCategory.key} • ${topCategory.value.toCurrency(decimalDigits: 0)}',
                      style: AppTypography.titleSmall().copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // Enhanced Pie Chart with better spacing and shadows
        Container(
          height: radius * 2 + 60,
          padding: const EdgeInsets.all(16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Shadow effect
              Container(
                width: radius * 2,
                height: radius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
              // Pie Chart
              PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 50,
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
                      titleStyle: AppTypography.labelMedium(
                        color: Colors.white,
                      ).copyWith(fontWeight: FontWeight.bold),
                      badgeWidget: percentage > 8
                          ? _buildBadge(entry.key, color)
                          : null,
                      badgePositionPercentageOffset: 1.3,
                      borderSide: BorderSide(
                        color: isDark ? Colors.black : Colors.white,
                        width: 2,
                      ),
                    );
                  }).toList(),
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                    enabled: true,
                  ),
                ),
              ),
              // Center text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total'.tr(),
                    style: AppTypography.labelSmall(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    total.toCurrency(decimalDigits: 0),
                    style: AppTypography.titleMedium(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      
                    ).copyWith(
                      fontWeight: FontWeight.bold,
                    )
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Enhanced Category Legend with better layout
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceDark.withOpacity(0.5)
                : AppColors.surfaceLight.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Wrap(
            spacing: 20,
            runSpacing: 16,
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
        ),
      ],
    );
  }

  Widget _buildBadge(String category, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
      child: Text(
        category,
        style: AppTypography.labelSmall(
          color: Colors.white,
          fontWeight: FontWeight.bold,
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
    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  category,
                  style: AppTypography.bodySmall(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${amount.toCurrency(decimalDigits: 0)} (${percentage.toStringAsFixed(1)}%)',
                  style: AppTypography.labelSmall(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
