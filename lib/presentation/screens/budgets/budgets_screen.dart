import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/transaction_model.dart';
import '../../blocs/blocs.dart';
import '../reports/reports_screen.dart';

/// Budgets overview screen
class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScrollScaffold(
      title: 'Budgets'.tr(),
      actions: [
        AppIconButton(
          icon: Icons.add,
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
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Monthly Overview Card
                _MonthlyOverviewCard(),

                const SizedBox(height: 24),

                // Budget Progress
                Text(
                  'Budget Progress'.tr(),
                  style: AppTypography.titleLarge(),
                ),
                const SizedBox(height: 16),

                // Budget List
                _BudgetList(),

                const SizedBox(height: 24),

                // Spending Insights
                Text(
                  'Spending Insights'.tr(),
                  style: AppTypography.titleLarge(),
                ),
                const SizedBox(height: 16),

                _SpendingInsights(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Monthly overview card
class _MonthlyOverviewCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetBloc>(
      builder: (context, bloc, child) {
        final totalBudget = bloc.totalBudgetLimit;
        final progress = bloc.budgetProgress;
        final totalSpent = progress.values.fold<double>(
          0,
          (sum, p) => sum + p.spent,
        );
        final remaining = totalBudget - totalSpent;
        final double percentage =
            totalBudget > 0 ? totalSpent / totalBudget : 0.0;

        return AppCard(
          variant: AppCardVariant.highlighted,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Budget'.tr(),
                          style: AppTypography.bodyMedium(
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          totalBudget.toCurrency(),
                          style: AppTypography.headlineMedium(),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: percentage > 0.9
                          ? AppColors.error.withOpacity(0.1)
                          : percentage > 0.75
                              ? AppColors.warning.withOpacity(0.1)
                              : AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          percentage > 0.9
                              ? Icons.warning
                              : percentage > 0.75
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                          size: 16,
                          color: percentage > 0.9
                              ? AppColors.error
                              : percentage > 0.75
                                  ? AppColors.warning
                                  : AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          percentage > 0.9
                              ? 'Over Budget'.tr()
                              : percentage > 0.75
                                  ? 'Near Limit'.tr()
                                  : 'On Track'.tr(),
                          style: AppTypography.labelSmall(
                            color: percentage > 0.9
                                ? AppColors.error
                                : percentage > 0.75
                                    ? AppColors.warning
                                    : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AppLinearProgress(
                value: percentage.clamp(0.0, 1.0),
                label:
                    'Spent: ${totalSpent.toCurrency()} / ${totalBudget.toCurrency()}',
                showPercentage: true,
                height: 12,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _StatItem(
                    label: 'Spent'.tr(),
                    value: totalSpent.toCurrency(),
                    color: AppColors.expense,
                  ),
                  const SizedBox(width: 24),
                  _StatItem(
                    label: 'Remaining'.tr(),
                    value: remaining.toCurrency(),
                    color: AppColors.income,
                  ),
                  const SizedBox(width: 24),
                  _StatItem(
                    label: 'Days Left'.tr(),
                    value:
                        '${DateTime.now().endOfMonth.difference(DateTime.now()).inDays}',
                    color: AppColors.primary,
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

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.caption(
                color: AppColors.textTertiary(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.titleMedium(),
        ),
      ],
    );
  }
}

/// Budget list with progress bars
class _BudgetList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetBloc>(
      builder: (context, bloc, child) {
        if (bloc.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (bloc.error != null) {
          return Center(
            child: Column(
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(bloc.error!),
                const SizedBox(height: 16),
                AppButton.secondary(
                  label: 'Retry'.tr(),
                  onPressed: () => bloc.loadBudgets(),
                ),
              ],
            ),
          );
        }

        final progress = bloc.budgetProgress;

        if (progress.isEmpty) {
          return AppEmptyState(
            icon: Icons.pie_chart,
            title: 'No budgets yet'.tr(),
            subtitle: 'Create your first budget to start tracking'.tr(),
          );
        }

        return Column(
          children: progress.entries.map((entry) {
            final p = entry.value;
            final isOverBudget = p.isOverBudget;
            final isNearLimit = p.isNearLimit;

            return AppCard(
              variant: AppCardVariant.flat,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              onTap: () => _showBudgetDetails(context, p),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: p.category.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getCategoryIcon(p.category.iconName),
                          color: p.category.color,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.category.name,
                              style: AppTypography.bodyLarge(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${p.spent.toCurrency()} ${'of'.tr()} ${p.budget.limit.toCurrency()}',
                              style: AppTypography.bodySmall(
                                color: AppColors.textTertiary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${(p.percentage * 100).toInt()}%',
                            style: AppTypography.labelLarge(
                              color: isOverBudget
                                  ? AppColors.error
                                  : isNearLimit
                                      ? AppColors.warning
                                      : p.category.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${p.remaining.toCurrency()} ${'left'.tr()}',
                            style: AppTypography.caption(
                              color: isOverBudget
                                  ? AppColors.error
                                  : AppColors.textTertiary(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: p.percentage.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: AppColors.surfaceVariant(context),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isOverBudget
                            ? AppColors.error
                            : isNearLimit
                                ? AppColors.warning
                                : p.category.color,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  IconData _getCategoryIcon(String iconName) {
    final iconMap = <String, IconData>{
      'restaurant': Icons.restaurant,
      'directions_car': Icons.directions_car,
      'shopping_bag': Icons.shopping_bag,
      'movie': Icons.movie,
      'receipt': Icons.receipt,
      'favorite': Icons.favorite,
      'school': Icons.school,
      'work': Icons.work,
      'laptop': Icons.laptop,
      'trending_up': Icons.trending_up,
    };
    return iconMap[iconName] ?? Icons.category;
  }

  void _showBudgetDetails(BuildContext context, BudgetProgress progress) {
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
              Text(
                progress.category.name,
                style: AppTypography.headlineSmall(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                '${progress.spent.toCurrency()} ${'spent'.tr()}',
                style: AppTypography.displaySmall(
                  color: progress.category.color,
                ),
              ),
              const SizedBox(height: 16),
              Text('${'Limit'.tr()}: ${progress.budget.limit.toCurrency()}'),
              const SizedBox(height: 8),
              Text('${'Remaining'.tr()}: ${progress.remaining.toCurrency()}'),
              const SizedBox(height: 8),
              Text(
                '${'Usage'.tr()}: ${(progress.percentage * 100).toStringAsFixed(1)}%',
              ),
              const SizedBox(height: 8),
              Text(
                '${'Period'.tr()}: ${progress.budget.period.name.capitalize.tr()}',
              ),
              const SizedBox(height: 8),
              Text(
                  '${'Start'.tr()}: ${progress.budget.startDate.toLongDate()}'),
              if (progress.budget.endDate != null) ...[
                const SizedBox(height: 8),
                Text('${'End'.tr()}: ${progress.budget.endDate!.toLongDate()}'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Spending insights section
class _SpendingInsights extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<BudgetBloc, TransactionBloc>(
      builder: (context, budgetBloc, transactionBloc, child) {
        final expenses = <String, double>{};
        for (final transaction in transactionBloc.transactions) {
          if (transaction.type != TransactionType.expense) continue;
          expenses[transaction.category] =
              (expenses[transaction.category] ?? 0) + transaction.amount;
        }

        final ranked = expenses.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final totalExpense =
            ranked.fold<double>(0, (sum, item) => sum + item.value);
        final alertBudget = budgetBloc.budgetProgress.values
            .where((item) => item.percentage >= 0.75)
            .toList()
          ..sort((a, b) => b.percentage.compareTo(a.percentage));

        return Column(
          children: [
            AppCard(
              variant: AppCardVariant.flat,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Spending Categories'.tr(),
                    style: AppTypography.titleMedium(),
                  ),
                  const SizedBox(height: 16),
                  if (ranked.isEmpty)
                    Text(
                      'Add expense transactions to see category insights.'.tr(),
                      style: AppTypography.bodySmall(
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ...ranked.take(3).toList().asMap().entries.map((entry) {
                    final percentage = totalExpense > 0
                        ? ((entry.value.value / totalExpense) * 100).round()
                        : 0;
                    return Padding(
                      padding: EdgeInsets.only(bottom: entry.key == 2 ? 0 : 12),
                      child: _InsightItem(
                        rank: entry.key + 1,
                        category: entry.value.key,
                        amount: entry.value.value.toCurrency(),
                        percentage: percentage,
                        color: _categoryColor(entry.value.key),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              variant: AppCardVariant.flat,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (alertBudget.isNotEmpty
                              ? AppColors.warning
                              : AppColors.success)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      alertBudget.isNotEmpty
                          ? Icons.warning_amber
                          : Icons.check_circle,
                      color: alertBudget.isNotEmpty
                          ? AppColors.warning
                          : AppColors.success,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alertBudget.isNotEmpty
                              ? 'Budget Alert'
                              : 'Budgets Healthy',
                          style: AppTypography.bodyLarge(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          alertBudget.isNotEmpty
                              ? '${alertBudget.first.category.name} is at ${(alertBudget.first.percentage * 100).toStringAsFixed(0)}% of its limit.'
                              : 'No budget categories are close to their limits right now.',
                          style: AppTypography.bodySmall(
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Color _categoryColor(String category) {
    final hash = category.codeUnits.fold<int>(0, (sum, value) => sum + value);
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.success,
      AppColors.warning,
      AppColors.error,
    ];
    return colors[hash % colors.length];
  }
}

class _InsightItem extends StatelessWidget {
  final int rank;
  final String category;
  final String amount;
  final int percentage;
  final Color color;

  const _InsightItem({
    required this.rank,
    required this.category,
    required this.amount,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: rank == 1
                ? const Color(0xFFFFD700).withOpacity(0.2)
                : rank == 2
                    ? const Color(0xFFC0C0C0).withOpacity(0.2)
                    : const Color(0xFFCD7F32).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: AppTypography.labelSmall(
                color: rank == 1
                    ? const Color(0xFFB8860B)
                    : rank == 2
                        ? const Color(0xFF808080)
                        : const Color(0xFF8B4513),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            category,
            style: AppTypography.bodyMedium(),
          ),
        ),
        Text(
          amount,
          style: AppTypography.bodyMedium(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$percentage%',
          style: AppTypography.caption(
            color: AppColors.textTertiary(context),
          ),
        ),
      ],
    );
  }
}
