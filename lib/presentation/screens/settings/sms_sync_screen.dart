import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/services/currency_formatter.dart';
import '../../../core/services/sms_transaction_service.dart';
import '../../../data/models/transaction_model.dart';
import '../../blocs/transaction_bloc.dart';
import 'package:flow_finance/core/utils/extensions.dart';
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
  bool _didShowImportPrompt = false;

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
    if (!mounted) return;
    setState(() {
      _hasPermission = hasPermission;
    });
    if (hasPermission) {
      _showImportSetupIfNeeded();
    }
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
      _showImportSetupIfNeeded(force: true);
    } else {
      if (mounted) {
        context.showSnackBar(
          SnackBar(
            content:
                Text('SMS permissions are required to sync transactions'.tr()),
          ),
        );
      }
    }
  }

  void _showImportSetupIfNeeded({bool force = false}) {
    if (!_hasPermission || !mounted) return;
    if (_didShowImportPrompt && !force) return;
    _didShowImportPrompt = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showImportSetupSheet();
    });
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
    }
  }

  Future<void> _showImportSetupSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textSecondary = AppColors.textSecondary(context);

        return StatefulBuilder(
          builder: (context, setSheetState) {
            void setQuickRange(int days) {
              final now = DateTime.now();
              final nextRange = DateTimeRange(
                start: days >= 3650
                    ? DateTime(2020)
                    : now.subtract(Duration(days: days)),
                end: now,
              );
              setState(() {
                _dateRange = nextRange;
              });
              setSheetState(() {});
            }

            return SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: textSecondary.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Choose SMS import period'.tr(),
                      style: AppTypography.titleLarge().copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pick the exact bank SMS history window to scan before importing transactions.'
                          .tr(),
                      style: AppTypography.bodyMedium(color: textSecondary),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _QuickRangeChip(
                          label: 'Last 7 days'.tr(),
                          onTap: () => setQuickRange(7),
                        ),
                        _QuickRangeChip(
                          label: 'Last 30 days'.tr(),
                          onTap: () => setQuickRange(30),
                        ),
                        _QuickRangeChip(
                          label: 'Last 90 days'.tr(),
                          onTap: () => setQuickRange(90),
                        ),
                        _QuickRangeChip(
                          label: 'Full history'.tr(),
                          onTap: () => setQuickRange(3650),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        await _selectDateRange();
                        setSheetState(() {});
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Ink(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.16),
                              AppColors.secondary.withOpacity(0.12),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.calendar_month_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Import range'.tr(),
                                    style: AppTypography.labelMedium(
                                      color: textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _dateRange == null
                                        ? 'Select date range'.tr()
                                        : '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}',
                                    style: AppTypography.bodyLarge().copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppButton.primary(
                      label: 'Scan SMS transactions'.tr(),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await _syncTransactions();
                      },
                      icon: Icons.sync_rounded,
                      expanded: true,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _syncTransactions() async {
    if (_dateRange == null) {
      context.showSnackBar(
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
        context.showSnackBar(
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
        context.showSnackBar(
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
                icon: const Icon(Icons.tune_rounded),
                onPressed: _showImportSetupSheet,
                tooltip: 'Import setup'.tr(),
              ),
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
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.08),
                        AppColors.secondary.withOpacity(0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Choose from and to dates before scanning so imports stay accurate and fast.'
                              .tr(),
                          style: AppTypography.bodySmall(
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ),
                    ],
                  ),
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
                  label: 'Scan SMS transactions'.tr(),
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
                AppColors.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
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
                  label: 'Change range'.tr(),
                  onPressed: _showImportSetupSheet,
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
                context.showSnackBar(
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
    final noteBits = (transaction.note ?? '')
        .split('•')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
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
                      style:
                          AppTypography.bodyLarge(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${transaction.category} • ${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
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
          if (transaction.paymentMethod != null || noteBits.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (transaction.paymentMethod != null)
                  _InfoPill(label: transaction.paymentMethod!),
                for (final bit in noteBits.take(3)) _InfoPill(label: bit),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickRangeChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickRangeChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      backgroundColor: AppColors.primary.withOpacity(0.08),
      side: BorderSide(color: AppColors.primary.withOpacity(0.16)),
      label: Text(
        label,
        style: AppTypography.labelMedium(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;

  const _InfoPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall(
          color: AppColors.textSecondary(context),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
