import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/services/currency_formatter.dart';
import '../../../core/services/google_pay_service.dart';
import '../../../data/models/transaction_model.dart';
import '../../blocs/transaction_bloc.dart';
import 'package:flow_finance/core/utils/extensions.dart';
import 'package:provider/provider.dart';

/// Google Pay Sync screen
class GooglePaySyncScreen extends StatefulWidget {
  const GooglePaySyncScreen({super.key});

  @override
  State<GooglePaySyncScreen> createState() => _GooglePaySyncScreenState();
}

class _GooglePaySyncScreenState extends State<GooglePaySyncScreen> {
  final GooglePayService _googlePayService = GooglePayService();
  bool _isLoading = false;
  List<Transaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _syncTransactions();
  }

  Future<void> _syncTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final transactions =
          await _googlePayService.parseGooglePayTransactions(limit: 100);
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });

      if (mounted && transactions.isNotEmpty) {
        CupertinoToast.show(
          context,
          message: 'Found {} Google Pay transactions'
              .tr(args: [transactions.length.toString()]),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        CupertinoToast.show(
          context,
          message: '${'Error syncing'.tr()}: $e',
          type: CupertinoToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Google Pay Sync'.tr(),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : _transactions.isEmpty
              ? _buildEmptyState()
              : _buildTransactionsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.creditcard_fill,
              size: 80,
              color: AppColors.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Google Pay Transactions'.tr(),
              style: AppTypography.titleLarge(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'No Google Pay SMS messages found. Make sure you have Google Pay transaction notifications enabled.'
                  .tr(),
              style: AppTypography.bodyMedium(
                color: AppColors.textSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            AppButton.primary(
              label: 'Sync Again'.tr(),
              onPressed: _syncTransactions,
                icon: CupertinoIcons.refresh,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          color: AppColors.surfaceVariant(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Google Pay Transactions'.tr(),
                    style: AppTypography.titleSmall(),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_transactions.length} ${'transactions found'.tr()}',
                    style: AppTypography.bodySmall(
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
              AppIconButton(
              icon: CupertinoIcons.refresh,
                onPressed: _syncTransactions,
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _transactions.length,
            itemBuilder: (context, index) {
              final transaction = _transactions[index];
              return _TransactionItem(transaction: transaction);
            },
          ),
        ),

        // Footer
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: SafeArea(
            child: AppButton.primary(
              label: 'Import All Transactions'.tr(),
              onPressed: () async {
                final imported =
                    await context.read<TransactionBloc>().addTransactions(
                          _transactions,
                        );
                if (!mounted) return;
                CupertinoToast.show(
                  context,
                  message: imported == 0
                      ? 'No new Google Pay transactions to import'.tr()
                      : 'Imported {} Google Pay transactions'
                          .tr(args: [imported.toString()]),
                );
                Navigator.pop(context);
              },
              expanded: true,
            ),
          ),
        ),
      ],
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final Transaction transaction;

  const _TransactionItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == TransactionType.expense;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (isExpense ? AppColors.error : AppColors.success)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              CupertinoIcons.creditcard_fill,
              color: isExpense ? AppColors.error : AppColors.success,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: AppTypography.bodyLarge(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      transaction.category,
                      style: AppTypography.bodySmall(
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                    if (transaction.note != null) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          transaction.note!,
                          style: AppTypography.caption(
                            color: AppColors.textTertiary(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isExpense ? '-' : '+'}${CurrencyFormatter.format(transaction.amount, currencyCode: transaction.currency)}',
                style: AppTypography.titleSmall(
                  color: isExpense ? AppColors.error : AppColors.success,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(transaction.date),
                style: AppTypography.caption(
                  color: AppColors.textTertiary(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today'.tr();
    } else if (difference.inDays == 1) {
      return 'Yesterday'.tr();
    } else if (difference.inDays < 7) {
      return '{} days ago'.tr(args: [difference.inDays.toString()]);
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
