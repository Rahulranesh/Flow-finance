import 'package:flutter/cupertino.dart';
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
import '../settings/settings_screen.dart';
import '../../widgets/home_floating_mascot.dart';
import '../wallets/wallets_screen.dart';
import '../family/family_screen.dart';
import '../analytics/analytics_screen.dart';
import '../goals/goals_screen.dart';

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
        CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add, size: 24),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
            );
          },
        ),
        const QuickSettingsButton(),
        const SizedBox(width: 8),
        AppIconButton(
          icon: CupertinoIcons.bell,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
          variant: AppIconButtonVariant.filled,
        ),
        const SizedBox(width: 16),
      ],
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: FlowMascotBubble(
                    message: 'Welcome back. I\'ll keep your money simple today.'.tr(),
                    subtitle:
                        'Check your balance, log spending, or ask for a quick insight.'.tr(),
                    actionLabel: 'Add expense'.tr(),
                    onAction: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddTransactionScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ),

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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Recent Transactions'.tr(),
                      style: AppTypography.titleLarge(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TransactionsScreen()),
                      );
                    },
                    child: Text('See All'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ),

          // Recent Transactions List
          Consumer<TransactionBloc>(
            builder: (context, bloc, child) {
              if (bloc.isLoading) {
                return const SliverFillRemaining(
                  child: Center(child: CupertinoActivityIndicator()),
                );
              }

              if (bloc.error != null) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.exclamationmark_circle,
                          size: 48,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(bloc.error!, maxLines: 1, overflow: TextOverflow.ellipsis),
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
                      icon: CupertinoIcons.doc_text,
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
      HomeFloatingMascot(),
    ],
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
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                    SizedBox(
                      child: Text(
                        '+${NumberFormat.compact().format(income)}',
                        style: AppTypography.labelMedium(
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          savingsRate >= 0
                              ? CupertinoIcons.arrow_up_right
                              : CupertinoIcons.arrow_down_right,
                          size: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${savingsRate.toStringAsFixed(1)}%',
                          style: AppTypography.labelSmall(
                            color: Colors.white.withOpacity(0.9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Text(
                'Tap for beautiful detailed money logs'.tr(),
                style: AppTypography.bodySmall(
                  color: Colors.white.withOpacity(0.78),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: 'Income'.tr(),
                      amount: income.toCurrency(),
                      icon: CupertinoIcons.arrow_down,
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
                      icon: CupertinoIcons.arrow_up,
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
            Icon(icon, size: 12, color: iconColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: AppTypography.bodySmall(
                  color: Colors.white.withOpacity(0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: AppTypography.titleMedium(color: Colors.white),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Quick actions row
class _QuickActionsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final firstRow = [
      _ActionItem(
        icon: CupertinoIcons.add_circled,
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
        icon: CupertinoIcons.chat_bubble_2_fill,
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
        icon: CupertinoIcons.creditcard,
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
        icon: CupertinoIcons.money_dollar,
        label: 'Wallets',
        color: AppColors.warning,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WalletsScreen(),
            ),
          );
        },
      ),
    ];

    final secondRow = [
      _ActionItem(
        icon: CupertinoIcons.person_2,
        label: 'Family Mode',
        color: AppColors.info,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FamilyScreen(),
            ),
          );
        },
      ),
      _ActionItem(
        icon: CupertinoIcons.chart_bar,
        label: 'Analytics',
        color: AppColors.primary,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AnalyticsScreen(),
            ),
          );
        },
      ),
      _ActionItem(
        icon: CupertinoIcons.building_2_fill,
        label: 'Wallets & Accounts',
        color: AppColors.warning,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WalletsScreen(),
            ),
          );
        },
      ),
      _ActionItem(
        icon: CupertinoIcons.flag,
        label: 'Goals',
        color: AppColors.success,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GoalsScreen(),
            ),
          );
        },
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: firstRow.map((action) => _buildActionButton(action)).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: secondRow.map((action) => _buildActionButton(action)).toList(),
          ),
        ],
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
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              action.icon,
              color: action.color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 56,
            child: Text(
              action.label.tr(),
              style: AppTypography.labelMedium(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
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
                'Overview'.tr(),
                style: AppTypography.titleLarge(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SimpleStatCard(
                      title: 'Monthly Budget'.tr(),
                      value: totalBudget.toCurrency(),
                      subtitle: 'Left: {amount}'.tr(namedArgs: {'amount': remaining.toCurrency()}),
                      icon: CupertinoIcons.money_dollar,
                      trend: totalBudget > 0
                          ? '{}% used'.tr(args: [((spent / totalBudget) * 100).toStringAsFixed(0)])
                          : 'No budgets'.tr(),
                      isPositive: remaining >= 0,
                      color: AppColors.primary,
                      onTap: () => _showMetricDetailsSheet(
                        context,
                        title: 'Budget Health'.tr(),
                        accent: AppColors.primary,
                        headline: totalBudget.toCurrency(),
                        items: [
                          ('Allocated'.tr(), totalBudget.toCurrency()),
                          ('Spent'.tr(), spent.toCurrency()),
                          ('Remaining'.tr(), remaining.toCurrency()),
                          (
                            'Status'.tr(),
                            totalBudget == 0
                                ? 'No budgets created yet'.tr()
                                : remaining >= 0
                                    ? 'Within plan'.tr()
                                    : 'Overspent'.tr(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SimpleStatCard(
                      title: 'Net Savings'.tr(),
                      value: balance.toCurrency(),
                      subtitle:
                          'Income: {amount}'.tr(namedArgs: {'amount': transactionBloc.totalIncome.toCurrency()}),
                      icon: CupertinoIcons.money_dollar,
                      trend: '${savingsRate.toStringAsFixed(0)}%',
                      isPositive: balance >= 0,
                      color: AppColors.secondary,
                      onTap: () => _showMetricDetailsSheet(
                        context,
                        title: 'Net Savings'.tr(),
                        accent: AppColors.secondary,
                        headline: balance.toCurrency(),
                        items: [
                          ('Income'.tr(), transactionBloc.totalIncome.toCurrency()),
                          (
                            'Expense'.tr(),
                            transactionBloc.totalExpense.toCurrency()
                          ),
                          (
                            'Savings Rate'.tr(),
                            '${savingsRate.toStringAsFixed(1)}%'
                          ),
                          (
                            'Insight'.tr(),
                            balance >= 0
                                ? 'You are retaining more than you spend.'.tr()
                                : 'Expenses are ahead of income right now.'.tr(),
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

/// Simple stat card used in the overview section
class _SimpleStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final String? trend;
  final bool isPositive;
  final Color color;
  final VoidCallback? onTap;

  const _SimpleStatCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.trend,
    this.isPositive = true,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (trend != null) ...[
              const SizedBox(height: 6),
              Text(
                trend!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isPositive ? AppColors.income : AppColors.expense,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
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

    return GestureDetector(
      onTap: () => showTransactionDetailsSheet(context, transaction),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withOpacity(0.15),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: categoryData.$2.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              '${isExpense ? '-' : '+'}${transaction.amount.toCurrency()}',
              style: AppTypography.amountSmall(
                isNegative: isExpense,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
      'Transport': (CupertinoIcons.car, const Color(0xFF3B82F6)),
      'Transportation': (CupertinoIcons.car, const Color(0xFF3B82F6)),
      'Shopping': (CupertinoIcons.bag, const Color(0xFFEC4899)),
      'Entertainment': (CupertinoIcons.film, const Color(0xFF8B5CF6)),
      'Bills': (CupertinoIcons.doc_text, const Color(0xFFEF4444)),
      'Bills & Utilities': (CupertinoIcons.doc_text, const Color(0xFFEF4444)),
      'Health': (CupertinoIcons.heart, const Color(0xFF10B981)),
      'Health & Fitness': (CupertinoIcons.heart, const Color(0xFF10B981)),
      'Education': (CupertinoIcons.book, const Color(0xFF14B8A6)),
      'Salary': (CupertinoIcons.briefcase, const Color(0xFF22C55E)),
      'Income': (CupertinoIcons.arrow_down, const Color(0xFF22C55E)),
      'Refund': (CupertinoIcons.refresh, const Color(0xFF22C55E)),
      'Interest': (CupertinoIcons.money_dollar, const Color(0xFF22C55E)),
      'Freelance': (CupertinoIcons.doc_plaintext, const Color(0xFF6366F1)),
      'Investment': (CupertinoIcons.arrow_up_right, const Color(0xFF06B6D4)),
      'Transfer': (CupertinoIcons.repeat, const Color(0xFF6366F1)),
      'Cash Withdrawal': (CupertinoIcons.money_dollar, const Color(0xFFEF4444)),
    };

    return categoryMap[category] ?? (CupertinoIcons.tray_full, AppColors.primary);
  }
}

void _showBalanceDetailsSheet(
  BuildContext context, {
  required double balance,
  required double income,
  required double expense,
  required List<Transaction> transactions,
}) {
  showCupertinoModalPopup<void>(
    context: context,
    builder: (context) => Container(
      decoration: BoxDecoration(
        color: AppColors.background(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Money Log',
                      style: AppTypography.labelLarge(
                        color: Colors.white.withOpacity(0.9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      balance.toCurrency(),
                      style: AppTypography.displayMedium(color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _sheetPill('Income {amount}'.tr(namedArgs: {'amount': income.toCurrency()})),
                        _sheetPill('Expense {amount}'.tr(namedArgs: {'amount': expense.toCurrency()})),
                        _sheetPill(
                          income > 0
                              ? 'Savings {percent}%'.tr(namedArgs: {'percent': (balance / income * 100).toStringAsFixed(1)})
                              : 'Savings 0%'.tr(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Recent detailed logs'.tr(), style: AppTypography.titleMedium(), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              ...transactions.map(
                (transaction) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => showTransactionDetailsSheet(context, transaction),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant(context),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: (transaction.type == TransactionType.expense ? AppColors.expense : AppColors.income).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              transaction.type == TransactionType.expense ? CupertinoIcons.arrow_down : CupertinoIcons.arrow_up,
                              color: transaction.type == TransactionType.expense ? AppColors.expense : AppColors.income,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(transaction.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodyLarge(fontWeight: FontWeight.w600),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    '${transaction.category} • ${transaction.date.toDateTime()}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodySmall(color: AppColors.textTertiary(context)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${transaction.type == TransactionType.expense ? '-' : '+'}${transaction.amount.toCurrency()}',
                            style: AppTypography.bodyLarge(
                              fontWeight: FontWeight.w700,
                              color: transaction.type == TransactionType.expense ? AppColors.expense : AppColors.income,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
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
  showCupertinoModalPopup<void>(
    context: context,
    builder: (context) => CupertinoActionSheet(
      title: Text(title, style: AppTypography.headlineSmall(), maxLines: 1, overflow: TextOverflow.ellipsis),
      message: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headline,
            style: AppTypography.displaySmall(color: accent),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item.$2,
                      style: AppTypography.bodyMedium(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    ),
  );
}

Widget _sheetPill(String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.18),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      style: AppTypography.labelMedium(color: Colors.white),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  );
}
