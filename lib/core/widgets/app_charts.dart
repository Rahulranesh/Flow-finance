import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/theme.dart';

/// Modern chart components for data visualization
class AppCharts {
  AppCharts._();

  /// Line chart for spending trends
  static Widget lineChart({
    required List<FlSpot> spots,
    required List<String> labels,
    Color? lineColor,
    Color? fillColor,
    bool showGrid = true,
    bool curved = true,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final primaryColor = lineColor ?? AppColors.primary;
        final secondaryColor = fillColor ?? primaryColor.withOpacity(0.1);

        return LineChart(
          LineChartData(
            gridData: FlGridData(
              show: showGrid,
              drawVerticalLine: false,
              horizontalInterval: 1,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  strokeWidth: 1,
                  dashArray: [5, 5],
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < labels.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          labels[index],
                          style: AppTypography.caption(
                            color: AppColors.textTertiary(context),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: 2,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '\$${value.toInt()}',
                      style: AppTypography.caption(
                        color: AppColors.textTertiary(context),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: spots.length - 1.0,
            minY: 0,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: curved,
                gradient: LinearGradient(
                  colors: [primaryColor, primaryColor.withOpacity(0.8)],
                ),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: primaryColor,
                      strokeWidth: 2,
                      strokeColor: AppColors.surface(context),
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      secondaryColor,
                      secondaryColor.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (touchedSpot) => AppColors.surface(context),
                tooltipRoundedRadius: 12,
                tooltipBorder: BorderSide(
                  color: AppColors.border(context),
                ),
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    return LineTooltipItem(
                      '\$${spot.y.toStringAsFixed(0)}',
                      AppTypography.labelMedium(
                        color: AppColors.textPrimary(context),
                      ),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        );
      },
    );
  }

  /// Pie chart for expense breakdown
  static Widget pieChart({
    required List<PieChartSectionData> sections,
    bool showTitles = true,
    double radius = 100,
  }) {
    return Builder(
      builder: (context) {
        return PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 40,
            sections: sections,
            pieTouchData: PieTouchData(
              touchCallback: (FlTouchEvent event, pieTouchResponse) {},
            ),
          ),
        );
      },
    );
  }

  /// Bar chart for category comparison
  static Widget barChart({
    required List<BarChartGroupData> barGroups,
    required List<String> labels,
    double maxY = 100,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) => AppColors.surface(context),
                tooltipRoundedRadius: 8,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '\$${rod.toY.toStringAsFixed(0)}',
                    AppTypography.labelMedium(
                      color: AppColors.textPrimary(context),
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < labels.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          labels[index],
                          style: AppTypography.caption(
                            color: AppColors.textTertiary(context),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  reservedSize: 30,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '\$${value.toInt()}',
                      style: AppTypography.caption(
                        color: AppColors.textTertiary(context),
                      ),
                    );
                  },
                ),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  strokeWidth: 1,
                  dashArray: [5, 5],
                );
              },
            ),
            borderData: FlBorderData(show: false),
            barGroups: barGroups,
          ),
        );
      },
    );
  }
}

/// Spending trend chart widget
class SpendingTrendChart extends StatelessWidget {
  const SpendingTrendChart({super.key});

  @override
  Widget build(BuildContext context) {
    final spots = [
      const FlSpot(0, 2000),
      const FlSpot(1, 2800),
      const FlSpot(2, 2200),
      const FlSpot(3, 3200),
      const FlSpot(4, 2800),
      const FlSpot(5, 3500),
      const FlSpot(6, 3000),
    ];

    final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return AppCard(
      variant: AppCardVariant.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending Trend',
            style: AppTypography.titleMedium(),
          ),
          const SizedBox(height: 4),
          Text(
            'Last 7 days',
            style: AppTypography.bodySmall(
              color: AppColors.textTertiary(context),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: AppCharts.lineChart(
              spots: spots,
              labels: labels,
              lineColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Expense breakdown pie chart
class ExpenseBreakdownChart extends StatelessWidget {
  const ExpenseBreakdownChart({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = [
      PieChartSectionData(
        color: const Color(0xFFF59E0B),
        value: 35,
        title: '35%',
        radius: 60,
        titleStyle: AppTypography.labelSmall(color: Colors.white),
      ),
      PieChartSectionData(
        color: const Color(0xFF3B82F6),
        value: 25,
        title: '25%',
        radius: 60,
        titleStyle: AppTypography.labelSmall(color: Colors.white),
      ),
      PieChartSectionData(
        color: const Color(0xFFEC4899),
        value: 20,
        title: '20%',
        radius: 60,
        titleStyle: AppTypography.labelSmall(color: Colors.white),
      ),
      PieChartSectionData(
        color: const Color(0xFF8B5CF6),
        value: 15,
        title: '15%',
        radius: 60,
        titleStyle: AppTypography.labelSmall(color: Colors.white),
      ),
      PieChartSectionData(
        color: const Color(0xFF10B981),
        value: 5,
        title: '5%',
        radius: 60,
        titleStyle: AppTypography.labelSmall(color: Colors.white),
      ),
    ];

    return AppCard(
      variant: AppCardVariant.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Expense Breakdown',
            style: AppTypography.titleMedium(),
          ),
          const SizedBox(height: 4),
          Text(
            'By category',
            style: AppTypography.bodySmall(
              color: AppColors.textTertiary(context),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: AppCharts.pieChart(sections: sections),
                ),
                Expanded(
                  flex: 2,
                  child: _buildLegend(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    final items = [
      ('Food', const Color(0xFFF59E0B)),
      ('Transport', const Color(0xFF3B82F6)),
      ('Shopping', const Color(0xFFEC4899)),
      ('Entertainment', const Color(0xFF8B5CF6)),
      ('Others', const Color(0xFF10B981)),
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: item.$2,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item.$1,
                style: AppTypography.caption(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Category comparison bar chart
class CategoryComparisonChart extends StatelessWidget {
  const CategoryComparisonChart({super.key});

  @override
  Widget build(BuildContext context) {
    final barGroups = [
      BarChartGroupData(
        x: 0,
        barRods: [
          BarChartRodData(
            toY: 800,
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
            ),
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
      BarChartGroupData(
        x: 1,
        barRods: [
          BarChartRodData(
            toY: 600,
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
            ),
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
      BarChartGroupData(
        x: 2,
        barRods: [
          BarChartRodData(
            toY: 450,
            gradient: const LinearGradient(
              colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
            ),
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
      BarChartGroupData(
        x: 3,
        barRods: [
          BarChartRodData(
            toY: 300,
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
            ),
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    ];

    final labels = ['Food', 'Trans', 'Shop', 'Ent'];

    return AppCard(
      variant: AppCardVariant.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category Comparison',
            style: AppTypography.titleMedium(),
          ),
          const SizedBox(height: 4),
          Text(
            'This month vs last month',
            style: AppTypography.bodySmall(
              color: AppColors.textTertiary(context),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: AppCharts.barChart(
              barGroups: barGroups,
              labels: labels,
              maxY: 1000,
            ),
          ),
        ],
      ),
    );
  }
}
