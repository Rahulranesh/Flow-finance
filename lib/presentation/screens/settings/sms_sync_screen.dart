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
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    // Default to last 30 days
    _dateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );
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

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _dateRange) {
      setState(() {
        _dateRange = picked;
      });
      // Auto-sync after date range selection
      _syncTransactions();
    }
  }

  Future<void> _syncTransactions() async {
    if (_dateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a date range first'.tr()),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final allTransactions = await _smsService.parseTransactions(
        startDate: _dateRange!.start,
        endDate: _dateRange!.end,
      );
      
      setState(() {
        _transactions = allTransactions;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Found {} transactions from {} to {}'
                  .tr(args: [
                    allTransactions.length.toString(),
                    _formatDate(_dateRange!.start),
                    _formatDate(_dateRange!.end),
                  ]),
            ),
            duration: const Duration(seconds: 3),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'SMS Sync'.tr(),
      actions: _hasPermission
          ? [
              IconButton(
                icon: const Icon(Icons.date_range),
                onPressed: _selectDateRange,
                tooltip: 'Select Date Range'.tr(),
              ),
            ]
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_hasPermission
              ? _buildPermissionRequest()
              : _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // Date Range Selector Card
        Container(
          margin: const EdgeInsets.all(16),
          child: AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Transaction History Period'.tr(),
                      style: AppTypography.titleSmall().copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _selectDateRange,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'From'.tr(),
                              style: AppTypography.labelSmall(
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _dateRange != null
                                  ? _formatDate(_dateRange!.start)
                                  : 'Select'.tr(),
                              style: AppTypography.bodyLarge().copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.arrow_forward,
                          color: AppColors.primary,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'To'.tr(),
                              style: AppTypography.labelSmall(
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _dateRange != null
                                  ? _formatDate(_dateRange!.end)
                                  : 'Select'.tr(),
                              style: AppTypography.bodyLarge().copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AppButton.primary(
                  label: 'Sync Transactions'.tr(),
                  onPressed: _syncTransactions,
                  icon: Icons.sync,
                  expanded: true,
                ),
              ],
            ),
          ),
        ),
        
        // Transactions List or Empty State
        Expanded(
          child: _transactions.isEmpty
              ? _buildEmptyState()
              : _buildTransactionsList(),
        ),
      ],
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
              subtitle: _dateRange != null
                  ? 'No SMS transactions found in the selected date range. Try a different period.'
                      .tr()
                  : 'Select a date range and sync to find bank transactions.'
                      .tr(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    final totalAmount = _transactions.fold<double>(
      0,
      (sum, t) => sum + (t.type == TransactionType.expense ? t.amount : 0),
    );
    
    return Column(
      children: [
        // Summary Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transactions Found'.tr(),
                          style: AppTypography.labelMedium(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_transactions.length}',
                          style: AppTypography.headlineMedium(
                            color: Colors.white,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total Amount'.tr(),
                          style: AppTypography.labelMedium(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(totalAmount),
                          style: AppTypography.headlineSmall(
                            color: Colors.white,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppButton.secondary(
                  label: 'Refresh'.tr(),
                  onPressed: _syncTransactions,
                  icon: Icons.refresh,
                  expanded: true,
                ),
              ],
            ),
          ),
        ),

        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
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
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: AppButton.primary(
              label: 'Import {} Transactions'.tr(args: [_transactions.length.toString()]),
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
                          : 'Successfully imported {} transactions!'
                              .tr(args: [imported.toString()]),
                    ),
                    backgroundColor: imported > 0 ? AppColors.success : null,
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
