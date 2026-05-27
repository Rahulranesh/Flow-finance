import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/models.dart';
import '../../blocs/blocs.dart';
import '../../widgets/transaction_details_sheet.dart';


/// Transactions list screen with filtering and search
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  TransactionFilter _selectedFilter = TransactionFilter.all;

  final List<(String, TransactionFilter)> _filters = const [
    ('All', TransactionFilter.all),
    ('Income', TransactionFilter.income),
    ('Expense', TransactionFilter.expense),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Transactions'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis),
        centerTitle: false,
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.slider_horizontal_3),
            onPressed: () => showCupertinoModalPopup<void>(
              context: context,
              builder: (context) => CupertinoActionSheet(
                title: Text('Filter Transactions'.tr()),
                message: Text('Select a filter option'.tr()),
                actions: [
                  CupertinoActionSheetAction(
                    child: Text('All Transactions'.tr()),
                    onPressed: () {
                      context.read<TransactionBloc>().setFilter(TransactionFilter.all);
                      Navigator.pop(context);
                    },
                  ),
                  CupertinoActionSheetAction(
                    child: Text('Income Only'.tr()),
                    onPressed: () {
                      context.read<TransactionBloc>().setFilter(TransactionFilter.income);
                      Navigator.pop(context);
                    },
                  ),
                  CupertinoActionSheetAction(
                    child: Text('Expenses Only'.tr()),
                    onPressed: () {
                      context.read<TransactionBloc>().setFilter(TransactionFilter.expense);
                      Navigator.pop(context);
                    },
                  ),
                ],
                cancelButton: CupertinoActionSheetAction(
                  isDefaultAction: true,
                  child: Text('Cancel'.tr()),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(20),
            child: AppSearchInput(
              controller: _searchController,
              hint: 'Search transactions...'.tr(),
              onChanged: (value) {
                context.read<TransactionBloc>().search(value);
              },
              onClear: () {
                _searchController.clear();
                context.read<TransactionBloc>().clearSearch();
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
                final (label, filter) = _filters[index];
                final isSelected = filter == _selectedFilter;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFilter = filter;
                    });
                    context.read<TransactionBloc>().setFilter(filter);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceVariant(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      label.tr(),
                      style: AppTypography.labelMedium(
                        color: isSelected ? Colors.white : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Transactions List
          Expanded(
            child: Consumer<TransactionBloc>(
              builder: (context, bloc, child) {
                if (bloc.isLoading) {
                  return const Center(child: CupertinoActivityIndicator());
                }

                if (bloc.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
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
                  );
                }

                final transactions = bloc.transactions;

                if (transactions.isEmpty) {
                  return Center(
                    child: AppEmptyState(
                      icon: CupertinoIcons.doc_plaintext,
                      title: 'No transactions found'.tr(),
                      subtitle:
                          'Try adjusting your filters or add a new transaction'
                              .tr(),
                    ),
                  );
                }

                return _TransactionsList(transactions: transactions);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Grouped transactions list with date headers
class _TransactionsList extends StatelessWidget {
  final List<Transaction> transactions;

  const _TransactionsList({required this.transactions});

  @override
  Widget build(BuildContext context) {
    // Group transactions by date
    final grouped = <String, List<Transaction>>{};
    for (final transaction in transactions) {
      final date = transaction.date;
      String key;
      if (date.isToday) {
        key = 'Today'.tr();
      } else if (date.isYesterday) {
        key = 'Yesterday'.tr();
      } else if (date.difference(DateTime.now()).inDays > -7) {
        key = 'This Week'.tr();
      } else if (date.difference(DateTime.now()).inDays > -14) {
        key = 'Last Week'.tr();
      } else {
        key = date.toShortDate();
      }
      grouped.putIfAbsent(key, () => []).add(transaction);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: grouped.length,
      itemBuilder: (context, groupIndex) {
        final date = grouped.keys.elementAt(groupIndex);
        final items = grouped[date]!;

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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Transactions for this date
            ...items.map((transaction) => _TransactionItem(
                  transaction: transaction,
                )),
          ],
        );
      },
    );
  }
}

/// Individual transaction item with swipe actions
class _TransactionItem extends StatelessWidget {
  final Transaction transaction;

  const _TransactionItem({
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == TransactionType.expense;
    final categoryData = _getCategoryData(transaction.category);

    return Dismissible(
      key: ValueKey('transaction_${transaction.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        context.read<TransactionBloc>().deleteTransaction(transaction.id);
        CupertinoToast.show(
          context,
          message: 'Transaction deleted'.tr(),
          onUndo: () {},
        );
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          CupertinoIcons.delete,
          color: Colors.white,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: () => showTransactionDetailsSheet(context, transaction),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.border(context).withOpacity(0.5),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                // Category Icon
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

                // Transaction Details
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
                        transaction.category,
                        style: AppTypography.bodySmall(
                          color: AppColors.textTertiary(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Amount and Status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isExpense ? '-' : '+'}${transaction.amount.toCurrency()}',
                      style: AppTypography.amountSmall(
                        isNegative: isExpense,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Completed',
                        style: AppTypography.caption(
                          color: AppColors.success,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (IconData, Color) _getCategoryData(String category) {
    final categoryMap = <String, (IconData, Color)>{
      'Food': (CupertinoIcons.bag, const Color(0xFFF59E0B)),
      'Food & Dining': (CupertinoIcons.bag, const Color(0xFFF59E0B)),
      'Transport': (CupertinoIcons.car, const Color(0xFF3B82F6)),
      'Transportation': (CupertinoIcons.car, const Color(0xFF3B82F6)),
      'Shopping': (CupertinoIcons.shopping_cart, const Color(0xFFEC4899)),
      'Entertainment': (CupertinoIcons.film, const Color(0xFF8B5CF6)),
      'Bills': (CupertinoIcons.doc_plaintext, const Color(0xFFEF4444)),
      'Bills & Utilities':
          (CupertinoIcons.doc_plaintext, const Color(0xFFEF4444)),
      'Health': (CupertinoIcons.heart, const Color(0xFF10B981)),
      'Health & Fitness': (CupertinoIcons.heart, const Color(0xFF10B981)),
      'Education': (CupertinoIcons.book, const Color(0xFF14B8A6)),
      'Salary': (CupertinoIcons.briefcase, const Color(0xFF22C55E)),
      'Income': (CupertinoIcons.arrow_down, const Color(0xFF22C55E)),
      'Refund': (CupertinoIcons.refresh_thick, const Color(0xFF22C55E)),
      'Interest': (CupertinoIcons.money_dollar, const Color(0xFF22C55E)),
      'Freelance': (CupertinoIcons.briefcase, const Color(0xFF6366F1)),
      'Investment': (CupertinoIcons.chart_bar, const Color(0xFF06B6D4)),
      'Transfer': (Icons.swap_horiz, const Color(0xFF6366F1)),
      'Cash Withdrawal':
          (CupertinoIcons.money_dollar, const Color(0xFFEF4444)),
    };

    return categoryMap[category] ?? (CupertinoIcons.tray_full, AppColors.primary);
  }
}
