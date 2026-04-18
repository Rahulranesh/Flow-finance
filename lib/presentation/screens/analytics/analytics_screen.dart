import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../data/models/transaction_model.dart';
import '../../blocs/transaction_bloc.dart';
import '../../widgets/charts/trend_chart.dart';
import '../../widgets/charts/category_pie_chart.dart';
import '../../widgets/charts/cash_flow_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionBloc>().loadTransactions();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      title: 'Analytics',
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: _selectDateRange,
        ),
      ],
      body: Column(
        children: [
          // Date Range Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            child: Row(
              children: [
                Icon(
                  Icons.date_range,
                  size: 16,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_formatDate(_dateRange.start)} - ${_formatDate(_dateRange.end)}',
                  style: AppTypography.bodySmall(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            labelStyle: AppTypography.labelMedium(
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: AppTypography.labelMedium(),
            tabs: const [
              Tab(text: 'Trends'),
              Tab(text: 'Categories'),
              Tab(text: 'Cash Flow'),
            ],
          ),

          // Tab Content
          Expanded(
            child: Consumer<TransactionBloc>(
              builder: (context, bloc, child) {
                if (bloc.isLoading) {
                  return AppLoading.fullScreen();
                }

                final filteredTransactions = _getFilteredTransactions(bloc.transactions);

                if (filteredTransactions.isEmpty) {
                  return _buildEmptyState(isDark);
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    // Trends Tab
                    _buildTrendsTab(filteredTransactions, isDark),

                    // Categories Tab
                    _buildCategoriesTab(filteredTransactions, isDark),

                    // Cash Flow Tab
                    _buildCashFlowTab(filteredTransactions, isDark),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsTab(List<Transaction> transactions, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Income & Expense Trends', isDark),
          const SizedBox(height: 16),
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TrendChart(
                transactions: transactions,
                startDate: _dateRange.start,
                endDate: _dateRange.end,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildKeyMetrics(transactions, isDark),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab(List<Transaction> transactions, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Expense Breakdown', isDark),
          const SizedBox(height: 16),
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CategoryPieChart(
                transactions: transactions,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildTopCategories(transactions, isDark),
        ],
      ),
    );
  }

  Widget _buildCashFlowTab(List<Transaction> transactions, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Cash Flow Analysis', isDark),
          const SizedBox(height: 16),
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CashFlowChart(
                transactions: transactions,
                startDate: _dateRange.start,
                endDate: _dateRange.end,
                showDaily: _dateRange.duration.inDays <= 31,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: AppTypography.titleMedium(
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      ),
    );
  }

  Widget _buildKeyMetrics(List<Transaction> transactions, bool isDark) {
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
    final savingsRate = totalIncome > 0 ? (balance / totalIncome) * 100 : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Key Metrics', isDark),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Income',
                '\$${totalIncome.toStringAsFixed(2)}',
                AppColors.success,
                Icons.arrow_upward,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Total Expense',
                '\$${totalExpense.toStringAsFixed(2)}',
                AppColors.error,
                Icons.arrow_downward,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Net Balance',
                '\$${balance.toStringAsFixed(2)}',
                balance >= 0 ? AppColors.primary : AppColors.error,
                Icons.account_balance_wallet,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Savings Rate',
                '${savingsRate.toStringAsFixed(1)}%',
                savingsRate >= 20 ? AppColors.success : AppColors.warning,
                Icons.savings,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, Color color, IconData icon) {
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
              value,
              style: AppTypography.titleLarge(
                color: color,
              ).copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCategories(List<Transaction> transactions, bool isDark) {
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

    final totalExpense = categoryTotals.values.fold(0.0, (sum, amount) => sum + amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Top Spending Categories', isDark),
        const SizedBox(height: 16),
        ...topCategories.map((entry) {
          final percentage = (entry.value / totalExpense) * 100;
          return _buildCategoryBar(entry.key, entry.value, percentage, isDark);
        }),
      ],
    );
  }

  Widget _buildCategoryBar(String category, double amount, double percentage, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: AppTypography.bodySmall(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              Text(
                '\$${amount.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
                style: AppTypography.bodySmall(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: isDark
                  ? AppColors.borderDark
                  : AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getCategoryColor(category),
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: AppTypography.titleMedium(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some transactions to see analytics',
            style: AppTypography.bodyMedium(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
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
      return t.date.isAfter(_dateRange.start.subtract(const Duration(days: 1))) &&
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

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
