import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Budgets overview screen
class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScrollScaffold(
      title: 'Budgets',
      actions: [
        AppIconButton(
          icon: Icons.add,
          onPressed: () {},
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
                  'Budget Progress',
                  style: AppTypography.titleLarge(),
                ),
                const SizedBox(height: 16),

                // Budget List
                _BudgetList(),

                const SizedBox(height: 24),

                // Spending Insights
                Text(
                  'Spending Insights',
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
                      'Total Budget',
                      style: AppTypography.bodyMedium(
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$5,000.00',
                      style: AppTypography.headlineMedium(),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_down,
                      size: 16,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'On Track',
                      style: AppTypography.labelSmall(
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AppLinearProgress(
            value: 0.65,
            label: 'Spent: \$3,250 / \$5,000',
            showPercentage: true,
            height: 12,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatItem(
                label: 'Spent',
                value: '\$3,250',
                color: AppColors.expense,
              ),
              const SizedBox(width: 24),
              _StatItem(
                label: 'Remaining',
                value: '\$1,750',
                color: AppColors.income,
              ),
              const SizedBox(width: 24),
              _StatItem(
                label: 'Days Left',
                value: '12',
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
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
    final budgets = [
      _BudgetData(
        'Food & Dining',
        Icons.restaurant,
        const Color(0xFFF59E0B),
        800,
        650,
      ),
      _BudgetData(
        'Transportation',
        Icons.directions_car,
        const Color(0xFF3B82F6),
        500,
        420,
      ),
      _BudgetData(
        'Shopping',
        Icons.shopping_bag,
        const Color(0xFFEC4899),
        600,
        580,
      ),
      _BudgetData(
        'Entertainment',
        Icons.movie,
        const Color(0xFF8B5CF6),
        300,
        150,
      ),
      _BudgetData(
        'Utilities',
        Icons.bolt,
        const Color(0xFFF97316),
        400,
        380,
      ),
    ];

    return Column(
      children: budgets.map((budget) {
        final progress = budget.spent / budget.total;
        final isOverBudget = progress > 1;

        return AppCard(
          variant: AppCardVariant.flat,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: budget.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      budget.icon,
                      color: budget.color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budget.name,
                          style: AppTypography.bodyLarge(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${budget.spent.toStringAsFixed(0)} of \$${budget.total.toStringAsFixed(0)}',
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
                        '${(progress * 100).toInt()}%',
                        style: AppTypography.labelLarge(
                          color: isOverBudget ? AppColors.error : budget.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${(budget.total - budget.spent).toStringAsFixed(0)} left',
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
                  value: progress.clamp(0, 1),
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceVariant(context),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOverBudget ? AppColors.error : budget.color,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _BudgetData {
  final String name;
  final IconData icon;
  final Color color;
  final double total;
  final double spent;

  _BudgetData(this.name, this.icon, this.color, this.total, this.spent);
}

/// Spending insights section
class _SpendingInsights extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppCard(
          variant: AppCardVariant.flat,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Top Spending Categories',
                style: AppTypography.titleMedium(),
              ),
              const SizedBox(height: 16),
              _InsightItem(
                rank: 1,
                category: 'Food & Dining',
                amount: '\$650',
                percentage: 20,
                color: const Color(0xFFF59E0B),
              ),
              const SizedBox(height: 12),
              _InsightItem(
                rank: 2,
                category: 'Shopping',
                amount: '\$580',
                percentage: 18,
                color: const Color(0xFFEC4899),
              ),
              const SizedBox(height: 12),
              _InsightItem(
                rank: 3,
                category: 'Transportation',
                amount: '\$420',
                percentage: 13,
                color: const Color(0xFF3B82F6),
              ),
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
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.warning_amber,
                  color: AppColors.warning,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Budget Alert',
                      style: AppTypography.bodyLarge(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Shopping budget is at 96%. Consider reducing expenses.',
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
