import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/services/currency_formatter.dart';
import '../../../core/services/sms_transaction_service.dart';
import '../../../data/models/transaction_model.dart';
import '../../blocs/transaction_bloc.dart';
import 'package:provider/provider.dart';

/// SMS Sync screen for syncing transactions from SMS
class SmsSyncScreen extends StatefulWidget {
  const SmsSyncScreen({super.key});

  @override
  State<SmsSyncScreen> createState() => _SmsSyncScreenState();
}

class _SmsSyncScreenState extends State<SmsSyncScreen> {
  final SmsTransactionService _smsService = SmsTransactionService();
  bool _isLoading = false;
  bool _hasPermission = false;
  List<Transaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final hasPermission = await _smsService.hasPermissions();
    setState(() {
      _hasPermission = hasPermission;
    });
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isLoading = true;
    });

    final granted = await _smsService.requestPermissions();

    setState(() {
      _hasPermission = granted;
      _isLoading = false;
    });

    if (granted) {
      _syncTransactions();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('SMS permissions are required to sync transactions'.tr()),
          ),
        );
      }
    }
  }

  Future<void> _syncTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final transactions = await _smsService.parseTransactions(limit: 100);
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Found {} transactions'
                  .tr(args: [transactions.length.toString()]),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'Error syncing'.tr()}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'SMS Sync'.tr(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_hasPermission
              ? _buildPermissionRequest()
              : _transactions.isEmpty
                  ? _buildEmptyState()
                  : _buildTransactionsList(),
    );
  }

  Widget _buildPermissionRequest() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sms,
              size: 80,
              color: AppColors.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'SMS Permission Required'.tr(),
              style: AppTypography.titleLarge(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'We need access to your SMS messages to automatically detect and import transactions from bank notifications.'
                  .tr(),
              style: AppTypography.bodyMedium(
                color: AppColors.textSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            AppButton.primary(
              label: 'Grant Permission'.tr(),
              onPressed: _requestPermissions,
              icon: Icons.check_circle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppEmptyState(
              icon: Icons.inbox,
              title: 'No transactions found'.tr(),
              subtitle: 'Sync your SMS to find bank transactions'.tr(),
            ),
            const SizedBox(height: 24),
            AppButton.primary(
              label: 'Sync Now'.tr(),
              onPressed: _syncTransactions,
              icon: Icons.sync,
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
              Text(
                '${_transactions.length} ${'transactions found'.tr()}',
                style: AppTypography.titleSmall(),
              ),
              AppButton.secondary(
                label: 'Sync Again'.tr(),
                onPressed: _syncTransactions,
                icon: Icons.refresh,
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      imported == 0
                          ? 'No new SMS transactions to import'.tr()
                          : 'Imported {} SMS transactions'
                              .tr(args: [imported.toString()]),
                    ),
                  ),
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
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isExpense ? Icons.arrow_downward : Icons.arrow_upward,
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
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.category,
                  style: AppTypography.bodySmall(
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isExpense ? '-' : '+'}${CurrencyFormatter.format(transaction.amount, currencyCode: transaction.currency)}',
            style: AppTypography.titleSmall(
              color: isExpense ? AppColors.error : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}
