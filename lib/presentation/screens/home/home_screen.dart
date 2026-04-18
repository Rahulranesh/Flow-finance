import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Modern home screen with balance overview, quick actions, and recent transactions
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Flow Finance',
      actions: [
        AppIconButton(
          icon: Icons.notifications_outlined,
          onPressed: () {},
          variant: AppIconButtonVariant.filled,
        ),
        const SizedBox(width: 8),
        AppIconButton(
          icon: Icons.settings_outlined,
          onPressed: () {},
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
              title: 'Recent Transactions',
              actionLabel: 'See All',
              onAction: () {},
            ),
          ),

          // Recent Transactions List
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _TransactionListItem(
                isExpense: index % 3 != 0,
                index: index,
              ),
              childCount: 10,
            ),
          ),

          // Bottom padding
          const SliverPadding(
            padding: EdgeInsets.only(bottom: 100),
          ),
        ],
      ),
      floatingActionButton: AppFAB(
        onPressed: () {},
        label: 'Add',
      ),
    );
  }
}

/// Balance hero card with total balance and mini chart
class _BalanceHeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(20),
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
                  'Total Balance',
                  style: AppTypography.bodyMedium(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_upward,
                        size: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '12.5%',
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
              '\$24,562.80',
              style: AppTypography.displayLarge(color: Colors.white),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'Income',
                    amount: '\$8,420.00',
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
                    label: 'Expense',
                    amount: '\$3,250.00',
                    icon: Icons.arrow_upward,
                    iconColor: AppColors.expense,
                  ),
                ),
              ],
            ),
          ],
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
        label: 'Add',
        color: AppColors.primary,
        onTap: () {},
      ),
      _ActionItem(
        icon: Icons.swap_horiz,
        label: 'Transfer',
        color: AppColors.secondary,
        onTap: () {},
      ),
      _ActionItem(
        icon: Icons.pie_chart,
        label: 'Budget',
        color: AppColors.warning,
        onTap: () {},
      ),
      _ActionItem(
        icon: Icons.flag,
        label: 'Goals',
        color: AppColors.info,
        onTap: () {},
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
                  value: '\$2,400',
                  subtitle: 'Left: \$850',
                  icon: Icons.account_balance_wallet,
                  trend: '+12%',
                  isPositive: true,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppStatCard(
                  title: 'Savings Goal',
                  value: '\$12,000',
                  subtitle: 'Target: \$20,000',
                  icon: Icons.savings,
                  trend: '60%',
                  isPositive: true,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
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
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
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
  final bool isExpense;
  final int index;

  const _TransactionListItem({
    required this.isExpense,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = [
      ('Shopping', Icons.shopping_bag, const Color(0xFFEC4899)),
      ('Food', Icons.restaurant, const Color(0xFFF59E0B)),
      ('Transport', Icons.directions_car, const Color(0xFF3B82F6)),
      ('Entertainment', Icons.movie, const Color(0xFF8B5CF6)),
      ('Health', Icons.favorite, const Color(0xFFEF4444)),
      ('Salary', Icons.work, const Color(0xFF10B981)),
    ];
    final category = categories[index % categories.length];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: AppCard(
        variant: AppCardVariant.flat,
        padding: const EdgeInsets.all(16),
        onTap: () {},
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: category.$3.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                category.$2,
                color: category.$3,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.$1,
                    style: AppTypography.bodyLarge(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Today, 2:30 PM',
                    style: AppTypography.bodySmall(
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${isExpense ? '-' : '+'}\$${(index + 1) * 25}.00',
              style: AppTypography.amountSmall(
                isNegative: isExpense,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
