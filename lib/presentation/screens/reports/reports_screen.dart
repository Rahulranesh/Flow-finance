import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../../core/services/currency_formatter.dart';
import '../../../core/services/data_export_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/transaction_model.dart';
import '../../blocs/transaction_bloc.dart';
import '../../widgets/charts/charts.dart';

/// Reports and insights screen
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final DataExportService _dataExportService = const DataExportService();
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionBloc>().loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      title: 'Reports'.tr(),
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: _selectDateRange,
        ),
        IconButton(
          icon: const Icon(Icons.download),
          onPressed: _exportReport,
        ),
      ],
      body: Consumer<TransactionBloc>(
        builder: (context, bloc, child) {
          if (bloc.isLoading) {
            return AppLoading.fullScreen();
          }

          final filteredTransactions =
              _getFilteredTransactions(bloc.transactions);
          final insights = _generateInsights(filteredTransactions);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Range Display
                _buildDateRangeDisplay(isDark),
                const SizedBox(height: 20),

                // Summary Cards
                _buildSummaryCards(insights),
                const SizedBox(height: 24),

                // Charts
                _buildChartsSection(filteredTransactions, isDark),
                const SizedBox(height: 24),

                // Insights
                _buildInsightsSection(insights, isDark),
                const SizedBox(height: 24),

                // Top Categories
                _buildTopCategoriesSection(filteredTransactions, isDark),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateRangeDisplay(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.date_range,
            size: 20,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${_formatDate(_dateRange.start)} - ${_formatDate(_dateRange.end)}',
              style: AppTypography.bodyMedium(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ),
          TextButton(
            onPressed: _selectDateRange,
            child: Text('Change'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(_ReportInsights insights) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Income'.tr(),
            insights.totalIncome,
            AppColors.success,
            Icons.arrow_upward,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Total Expense'.tr(),
            insights.totalExpense,
            AppColors.error,
            Icons.arrow_downward,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String label, double amount, Color color, IconData icon) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AppTypography.labelSmall(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              amount.toCurrency(),
              style: AppTypography.titleLarge(
                color: color,
              ).copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection(List<Transaction> transactions, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Spending Overview'.tr(),
          style: AppTypography.titleMedium(
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 250,
              child: CategoryPieChart(
                transactions: transactions,
                showLabels: true,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 250,
              child: CashFlowChart(
                transactions: transactions,
                startDate: _dateRange.start,
                endDate: _dateRange.end,
                showDaily: _dateRange.duration.inDays <= 31,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsSection(_ReportInsights insights, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Insights'.tr(),
          style: AppTypography.titleMedium(
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInsightRow(
                  'Savings Rate'.tr(),
                  '${insights.savingsRate.toStringAsFixed(1)}%',
                  insights.savingsRate >= 20
                      ? AppColors.success
                      : AppColors.warning,
                  Icons.savings,
                ),
                const Divider(height: 24),
                _buildInsightRow(
                  'Avg Daily Spend'.tr(),
                  insights.avgDailySpend.toCurrency(),
                  AppColors.primary,
                  Icons.today,
                ),
                if (insights.topCategory != null) ...[
                  const Divider(height: 24),
                  _buildInsightRow(
                    'Top Category'.tr(),
                    '${insights.topCategory} (${insights.topCategoryAmount.toCurrency(decimalDigits: 0)})',
                    AppColors.secondary,
                    Icons.category,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightRow(
      String label, String value, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelSmall(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.bodyMedium(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopCategoriesSection(
      List<Transaction> transactions, bool isDark) {
    final categoryTotals = <String, double>{};

    for (final transaction in transactions) {
      if (transaction.type == TransactionType.expense) {
        categoryTotals[transaction.category] =
            (categoryTotals[transaction.category] ?? 0) + transaction.amount;
      }
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topCategories = sortedCategories.take(5).toList();

    if (topCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalExpense =
        categoryTotals.values.fold(0.0, (sum, amount) => sum + amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Spending Categories'.tr(),
          style: AppTypography.titleMedium(
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            children: topCategories.map((entry) {
              final percentage = (entry.value / totalExpense) * 100;
              return _buildCategoryRow(
                entry.key,
                entry.value,
                percentage,
                _getCategoryColor(entry.key),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryRow(
      String category, double amount, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  const SizedBox(width: 12),
                  Text(
                    category,
                    style: AppTypography.bodyMedium(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Text(
                '${amount.toCurrency(decimalDigits: 0)} (${percentage.toStringAsFixed(1)}%)',
                style: AppTypography.bodySmall(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: AppColors.border(context),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  _ReportInsights _generateInsights(List<Transaction> transactions) {
    double totalIncome = 0;
    double totalExpense = 0;
    final categoryTotals = <String, double>{};

    for (final transaction in transactions) {
      if (transaction.type == TransactionType.income) {
        totalIncome += transaction.amount;
      } else {
        totalExpense += transaction.amount;
        categoryTotals[transaction.category] =
            (categoryTotals[transaction.category] ?? 0) + transaction.amount;
      }
    }

    final netSavings = totalIncome - totalExpense;
    final savingsRate =
        totalIncome > 0 ? (netSavings / totalIncome) * 100 : 0.0;

    final days = _dateRange.duration.inDays + 1;
    final avgDailySpend = days > 0 ? totalExpense / days : 0.0;

    String? topCategory;
    double topCategoryAmount = 0;
    categoryTotals.forEach((category, amount) {
      if (amount > topCategoryAmount) {
        topCategory = category;
        topCategoryAmount = amount;
      }
    });

    return _ReportInsights(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netSavings: netSavings,
      savingsRate: savingsRate,
      avgDailySpend: avgDailySpend,
      topCategory: topCategory,
      topCategoryAmount: topCategoryAmount,
    );
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

  List<Transaction> _getFilteredTransactions(List<Transaction> transactions) {
    return transactions.where((t) {
      return t.date
              .isAfter(_dateRange.start.subtract(const Duration(days: 1))) &&
          t.date.isBefore(_dateRange.end.add(const Duration(days: 1)));
    }).toList();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  void _exportReport() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Export Report'.tr(),
              style: AppTypography.titleMedium(),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.table_chart, color: AppColors.success),
              title: Text('Export as CSV'.tr()),
              subtitle: Text('Spreadsheet format for Excel/Google Sheets'.tr()),
              onTap: () {
                Navigator.pop(context);
                _exportToCsv();
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: AppColors.error),
              title: Text('Export as PDF'.tr()),
              subtitle: Text('Document format for sharing/printing'.tr()),
              onTap: () {
                Navigator.pop(context);
                _exportToPdf();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _exportToCsv() {
    final bloc = context.read<TransactionBloc>();
    final transactions = _getFilteredTransactions(bloc.transactions);
    _dataExportService.shareExport(
      transactions: transactions,
      dateRange: _dateRange,
      format: ExportFormat.csv,
      currencySymbol: CurrencyFormatter.currentCurrency.symbol,
    );
  }

  void _exportToPdf() {
    final bloc = context.read<TransactionBloc>();
    final transactions = _getFilteredTransactions(bloc.transactions);
    _dataExportService.shareExport(
      transactions: transactions,
      dateRange: _dateRange,
      format: ExportFormat.pdf,
      currencySymbol: CurrencyFormatter.currentCurrency.symbol,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

class _ReportInsights {
  const _ReportInsights({
    required this.totalIncome,
    required this.totalExpense,
    required this.netSavings,
    required this.savingsRate,
    required this.avgDailySpend,
    required this.topCategory,
    required this.topCategoryAmount,
  });

  final double totalIncome;
  final double totalExpense;
  final double netSavings;
  final double savingsRate;
  final double avgDailySpend;
  final String? topCategory;
  final double topCategoryAmount;
}
