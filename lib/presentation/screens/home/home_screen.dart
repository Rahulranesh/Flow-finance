import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/widgets/quick_settings_button.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/models.dart';
import '../../blocs/blocs.dart';
import '../../widgets/transaction_details_sheet.dart';
import '../settings/sms_sync_screen.dart';
import '../settings/google_pay_sync_screen.dart';
import '../add_transaction/add_transaction_screen.dart';
import '../transactions/transactions_screen.dart';
import '../reports/reports_screen.dart';

/// Modern home screen with balance overview, quick actions, and recent transactions
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Flow Finance'.tr(),
      actions: [
        const QuickSettingsButton(),
        const SizedBox(width: 8),
        AppIconButton(
          icon: Icons.notifications_outlined,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportsScreen()),
            );
          },
          variant: AppIconButtonVariant.filled,
        ),
        const SizedBox(width: 16),
      ],
      body: CustomScrollView(
        slivers: [
          // Balance Hero Section
          SliverToBoxAdapter(
            child: _BalanceHeroCard(),
          ),

          // Quick Actions
          SliverToBoxAdapter(
            child: _QuickActionsRow(),
          ),

          // Stats Overview
          SliverToBoxAdapter(
            child: _StatsOverview(),
          ),

          // Recent Transactions Header
          SliverPersistentHeader(
            pinned: true,
            delegate: _SectionHeaderDelegate(
              title: 'Recent Transactions'.tr(),
              actionLabel: 'See All'.tr(),
              onAction: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TransactionsScreen()),
                );
              },
            ),
          ),

          // Recent Transactions List
          Consumer<TransactionBloc>(
            builder: (context, bloc, child) {
              if (bloc.isLoading) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (bloc.error != null) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(bloc.error!),
                        const SizedBox(height: 16),
                        AppButton.secondary(
                          label: 'Retry'.tr(),
                          onPressed: () => bloc.loadTransactions(),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final transactions = bloc.transactions.take(10).toList();

              if (transactions.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: AppEmptyState(
                      icon: Icons.receipt_long,
                      title: 'No transactions yet'.tr(),
                      subtitle:
                          'Add your first transaction to get started'.tr(),
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _TransactionListItem(
                    transaction: transactions[index],
                  ),
                  childCount: transactions.length,
                ),
              );
            },
          ),

          // Bottom padding
          const SliverPadding(
            padding: EdgeInsets.only(bottom: 100),
          ),
        ],
      ),
      floatingActionButton: AppFAB(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );
        },
        label: 'Add'.tr(),
      ),
    );
  }
}

/// Balance hero card with total balance and mini chart
class _BalanceHeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final transactionBloc = context.watch<TransactionBloc>();
    final balance = transactionBloc.balance;
    final income = transactionBloc.totalIncome;
    final expense = transactionBloc.totalExpense;
    final savingsRate = income > 0 ? ((balance / income) * 100) : 0.0;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: () => _showBalanceDetailsSheet(
          context,
          balance: balance,
          income: income,
          expense: expense,
          transactions: transactionBloc.transactions.take(5).toList(),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primaryDark,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 24,
                spreadRadius: -4,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Balance'.tr(),
                    style: AppTypography.bodyMedium(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          savingsRate >= 0
                              ? Icons.trending_up
                              : Icons.trending_down,
                          size: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${savingsRate.toStringAsFixed(1)}%',
                          style: AppTypography.labelSmall(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                balance.toCurrency(),
                style: AppTypography.displayLarge(color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                'Tap for beautiful detailed money logs'.tr(),
                style: AppTypography.bodySmall(
                  color: Colors.white.withOpacity(0.78),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: 'Income'.tr(),
                      amount: income.toCurrency(),
                      icon: Icons.arrow_downward,
                      iconColor: AppColors.income,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  Expanded(
                    child: _MiniStat(
                      label: 'Expense'.tr(),
                      amount: expense.toCurrency(),
                      icon: Icons.arrow_upward,
                      iconColor: AppColors.expense,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String amount;
  final IconData icon;
  final Color iconColor;

  const _MiniStat({
    required this.label,
    required this.amount,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                size: 14,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.bodySmall(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          amount,
          style: AppTypography.titleMedium(color: Colors.white),
        ),
      ],
    );
  }
}

/// Quick actions row
class _QuickActionsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionItem(
        icon: Icons.add_circle,
        label: 'Manual',
        color: AppColors.primary,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
          );
        },
      ),
      _ActionItem(
        icon: Icons.sms,
        label: 'SMS Sync',
        color: AppColors.secondary,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SmsSyncScreen(),
            ),
          );
        },
      ),
      _ActionItem(
        icon: Icons.payment,
        label: 'Google Pay',
        color: AppColors.success,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GooglePaySyncScreen(),
            ),
          );
        },
      ),
      _ActionItem(
        icon: Icons.auto_awesome,
        label: 'Auto Sync',
        color: AppColors.warning,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Auto sync will run in background'),
            ),
          );
        },
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: actions.map((action) => _buildActionButton(action)).toList(),
      ),
    );
  }

  Widget _buildActionButton(_ActionItem action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: action.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              action.icon,
              color: action.color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            action.label,
            style: AppTypography.labelMedium(),
          ),
        ],
      ),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _ActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

/// Stats overview section
class _StatsOverview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<BudgetBloc, TransactionBloc>(
      builder: (context, budgetBloc, transactionBloc, child) {
        final totalBudget = budgetBloc.totalBudgetLimit;
        final spent = budgetBloc.budgetProgress.values.fold<double>(
          0,
          (sum, item) => sum + item.spent,
        );
        final remaining = (totalBudget - spent).clamp(0, double.infinity);
        final balance = transactionBloc.balance;
        final savingsRate = transactionBloc.totalIncome > 0
            ? ((balance / transactionBloc.totalIncome) * 100)
                .clamp(-999.0, 999.0)
            : 0.0;

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overview',
                style: AppTypography.titleLarge(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppStatCard(
                      title: 'Monthly Budget',
                      value: totalBudget.toCurrency(),
                      subtitle: 'Left: ${remaining.toCurrency()}',
                      icon: Icons.account_balance_wallet,
                      trend: totalBudget > 0
                          ? '${((spent / totalBudget) * 100).toStringAsFixed(0)}% used'
                          : 'No budgets',
                      isPositive: remaining >= 0,
                      color: AppColors.primary,
                      onTap: () => _showMetricDetailsSheet(
                        context,
                        title: 'Budget Health',
                        accent: AppColors.primary,
                        headline: totalBudget.toCurrency(),
                        items: [
                          ('Allocated', totalBudget.toCurrency()),
                          ('Spent', spent.toCurrency()),
                          ('Remaining', remaining.toCurrency()),
                          (
                            'Status',
                            totalBudget == 0
                                ? 'No budgets created yet'
                                : remaining >= 0
                                    ? 'Within plan'
                                    : 'Overspent',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppStatCard(
                      title: 'Net Savings',
                      value: balance.toCurrency(),
                      subtitle:
                          'Income: ${transactionBloc.totalIncome.toCurrency()}',
                      icon: Icons.savings,
                      trend: '${savingsRate.toStringAsFixed(0)}%',
                      isPositive: balance >= 0,
                      color: AppColors.secondary,
                      onTap: () => _showMetricDetailsSheet(
                        context,
                        title: 'Net Savings',
                        accent: AppColors.secondary,
                        headline: balance.toCurrency(),
                        items: [
                          ('Income', transactionBloc.totalIncome.toCurrency()),
                          (
                            'Expense',
                            transactionBloc.totalExpense.toCurrency()
                          ),
                          (
                            'Savings Rate',
                            '${savingsRate.toStringAsFixed(1)}%'
                          ),
                          (
                            'Insight',
                            balance >= 0
                                ? 'You are retaining more than you spend.'
                                : 'Expenses are ahead of income right now.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Section header delegate for sticky headers
class _SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  _SectionHeaderDelegate({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTypography.titleLarge(),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 56;

  @override
  double get minExtent => 56;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}

/// Transaction list item
class _TransactionListItem extends StatelessWidget {
  final Transaction transaction;

  const _TransactionListItem({
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == TransactionType.expense;

    // Get category icon and color
    final categoryData = _getCategoryData(transaction.category);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: AppCard(
        variant: AppCardVariant.flat,
        padding: const EdgeInsets.all(16),
        onTap: () => showTransactionDetailsSheet(context, transaction),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: categoryData.$2.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                categoryData.$1,
                color: categoryData.$2,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: AppTypography.bodyLarge(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transaction.date.toRelative(),
                    style: AppTypography.bodySmall(
                      color: AppColors.textTertiary(context),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${isExpense ? '-' : '+'}${transaction.amount.toCurrency()}',
              style: AppTypography.amountSmall(
                isNegative: isExpense,
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color) _getCategoryData(String category) {
    final categoryMap = <String, (IconData, Color)>{
      'Food': (Icons.restaurant, const Color(0xFFF59E0B)),
      'Food & Dining': (Icons.restaurant, const Color(0xFFF59E0B)),
      'Transport': (Icons.directions_car, const Color(0xFF3B82F6)),
      'Transportation': (Icons.directions_car, const Color(0xFF3B82F6)),
      'Shopping': (Icons.shopping_bag, const Color(0xFFEC4899)),
      'Entertainment': (Icons.movie, const Color(0xFF8B5CF6)),
      'Bills': (Icons.receipt, const Color(0xFFEF4444)),
      'Bills & Utilities': (Icons.receipt, const Color(0xFFEF4444)),
      'Health': (Icons.favorite, const Color(0xFF10B981)),
      'Health & Fitness': (Icons.favorite, const Color(0xFF10B981)),
      'Education': (Icons.school, const Color(0xFF14B8A6)),
      'Salary': (Icons.work, const Color(0xFF22C55E)),
      'Income': (Icons.arrow_downward, const Color(0xFF22C55E)),
      'Refund': (Icons.replay, const Color(0xFF22C55E)),
      'Interest': (Icons.savings, const Color(0xFF22C55E)),
      'Freelance': (Icons.laptop, const Color(0xFF6366F1)),
      'Investment': (Icons.trending_up, const Color(0xFF06B6D4)),
      'Transfer': (Icons.swap_horiz, const Color(0xFF6366F1)),
      'Cash Withdrawal': (Icons.money, const Color(0xFFEF4444)),
    };

    return categoryMap[category] ?? (Icons.category, AppColors.primary);
  }
}

void _showBalanceDetailsSheet(
  BuildContext context, {
  required double balance,
  required double income,
  required double expense,
  required List<Transaction> transactions,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Money Log',
                      style: AppTypography.labelLarge(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      balance.toCurrency(),
                      style: AppTypography.displayMedium(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _sheetPill('Income ${income.toCurrency()}'),
                        _sheetPill('Expense ${expense.toCurrency()}'),
                        _sheetPill(
                          income > 0
                              ? 'Savings ${(balance / income * 100).toStringAsFixed(1)}%'
                              : 'Savings 0%',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Recent detailed logs', style: AppTypography.titleMedium()),
              const SizedBox(height: 12),
              ...transactions.map(
                (transaction) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    tileColor: AppColors.surfaceVariant(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text(transaction.title),
                    subtitle: Text(
                      '${transaction.category} • ${transaction.date.toDateTime()}',
                    ),
                    trailing: Text(
                      '${transaction.type == TransactionType.expense ? '-' : '+'}${transaction.amount.toCurrency()}',
                      style: AppTypography.bodyLarge(
                        fontWeight: FontWeight.w700,
                        color: transaction.type == TransactionType.expense
                            ? AppColors.expense
                            : AppColors.income,
                      ),
                    ),
                    onTap: () =>
                        showTransactionDetailsSheet(context, transaction),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void _showMetricDetailsSheet(
  BuildContext context, {
  required String title,
  required Color accent,
  required String headline,
  required List<(String, String)> items,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.headlineSmall()),
            const SizedBox(height: 8),
            Text(
              headline,
              style: AppTypography.displaySmall(color: accent),
            ),
            const SizedBox(height: 18),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 92,
                      child: Text(
                        item.$1,
                        style: AppTypography.bodySmall(
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.$2,
                        style: AppTypography.bodyMedium(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _sheetPill(String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.18),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: AppTypography.labelMedium(color: Colors.white),
    ),
  );
}
