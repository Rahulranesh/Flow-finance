import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Transactions list screen with filtering and search
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Income', 'Expense', 'Transfer'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Transactions',
      actions: [
        AppIconButton(
          icon: Icons.filter_list,
          onPressed: () {},
          variant: AppIconButtonVariant.filled,
        ),
        const SizedBox(width: 16),
      ],
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(20),
            child: AppSearchInput(
              controller: _searchController,
              hint: 'Search transactions...',
              onChanged: (value) {
                // Handle search
              },
            ),
          ),

          // Filter Chips
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = filter == _selectedFilter;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                  child: AnimatedContainer(
                    duration: AppAnimations.fast,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceVariant(context),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      filter,
                      style: AppTypography.labelMedium(
                        color: isSelected ? Colors.white : null,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Transactions List
          Expanded(
            child: _TransactionsList(),
          ),
        ],
      ),
    );
  }
}

/// Grouped transactions list with date headers
class _TransactionsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Sample grouped data
    final groups = [
      ('Today', 3),
      ('Yesterday', 4),
      ('This Week', 5),
      ('Last Week', 6),
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: groups.length,
      itemBuilder: (context, groupIndex) {
        final (date, count) = groups[groupIndex];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                date,
                style: AppTypography.labelLarge(
                  color: AppColors.textSecondary(context),
                ),
              ),
            ),

            // Transactions for this date
            ...List.generate(count, (index) {
              final itemIndex = groupIndex * 10 + index;
              return _TransactionItem(
                index: itemIndex,
                isExpense: itemIndex % 3 != 0,
              );
            }),
          ],
        );
      },
    );
  }
}

/// Individual transaction item with swipe actions
class _TransactionItem extends StatelessWidget {
  final int index;
  final bool isExpense;

  const _TransactionItem({
    required this.index,
    required this.isExpense,
  });

  @override
  Widget build(BuildContext context) {
    final categories = [
      ('Shopping', Icons.shopping_bag, const Color(0xFFEC4899)),
      ('Food', Icons.restaurant, const Color(0xFFF59E0B)),
      ('Transport', Icons.directions_car, const Color(0xFF3B82F6)),
      ('Entertainment', Icons.movie, const Color(0xFF8B5CF6)),
      ('Health', Icons.favorite, const Color(0xFFEF4444)),
      ('Salary', Icons.work, const Color(0xFF10B981)),
      ('Investment', Icons.trending_up, const Color(0xFF14B8A6)),
      ('Utilities', Icons.bolt, const Color(0xFFF97316)),
    ];
    final category = categories[index % categories.length];

    return Dismissible(
      key: ValueKey('transaction_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      child: AppCard(
        variant: AppCardVariant.flat,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        onTap: () {},
        child: Row(
          children: [
            // Category Icon
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

            // Transaction Details
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
                    'Visa ending in 4242',
                    style: AppTypography.bodySmall(
                      color: AppColors.textTertiary(context),
                    ),
                  ),
                ],
              ),
            ),

            // Amount and Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isExpense ? '-' : '+'}\$${(index + 1) * 25}.00',
                  style: AppTypography.amountSmall(
                    isNegative: isExpense,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Completed',
                    style: AppTypography.caption(
                      color: AppColors.success,
                    ),
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

/// Transaction detail screen
class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Transaction Details',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Amount Section
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.expense.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.shopping_bag,
                      color: AppColors.expense,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '-\$125.00',
                    style: AppTypography.amountLarge(isNegative: true),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Shopping',
                    style: AppTypography.titleMedium(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Details Section
            AppCard(
              variant: AppCardVariant.flat,
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Status',
                    value: 'Completed',
                    valueColor: AppColors.success,
                  ),
                  const Divider(height: 24),
                  _DetailRow(
                    label: 'Date',
                    value: 'Jan 15, 2025',
                  ),
                  const Divider(height: 24),
                  _DetailRow(
                    label: 'Time',
                    value: '2:30 PM',
                  ),
                  const Divider(height: 24),
                  _DetailRow(
                    label: 'Payment Method',
                    value: 'Visa ending in 4242',
                  ),
                  const Divider(height: 24),
                  _DetailRow(
                    label: 'Transaction ID',
                    value: '#TRX-2025-001',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Notes Section
            AppCard(
              variant: AppCardVariant.flat,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notes',
                    style: AppTypography.labelLarge(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Weekly grocery shopping at Whole Foods. Included some organic items.',
                    style: AppTypography.bodyMedium(
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Actions
            Row(
              children: [
                Expanded(
                  child: AppButton.secondary(
                    label: 'Edit',
                    onPressed: () {},
                    icon: Icons.edit,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton.danger(
                    label: 'Delete',
                    onPressed: () {},
                    icon: Icons.delete,
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium(
            color: AppColors.textSecondary(context),
          ),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
