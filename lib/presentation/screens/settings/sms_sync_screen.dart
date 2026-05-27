import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
        CupertinoToast.show(
        context,
        message: 'SMS permissions are required to sync transactions'.tr(),
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
              surface: AppColors.surfaceLight,
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
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) {
        final textSecondary = AppColors.textSecondary(context);

        return Material(
          color: Colors.transparent,
          child: StatefulBuilder(
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
                  color: AppColors.surface(context),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
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
                          borderRadius: BorderRadius.circular(10),
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
                      borderRadius: BorderRadius.circular(10),
                      child: Ink(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.16),
                              AppColors.secondary.withOpacity(0.12),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
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
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                CupertinoIcons.calendar,
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
                              CupertinoIcons.chevron_forward,
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
                      icon: CupertinoIcons.refresh,
                      expanded: true,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        );
      },
    );
  }

  Future<void> _syncTransactions() async {
    if (_dateRange == null) {
      CupertinoToast.show(
        context,
        message: 'Please select a date range first'.tr(),
        type: CupertinoToastType.warning,
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
        CupertinoToast.show(
          context,
          message: 'Found {} transactions from {} to {}'
              .tr(args: [
                allTransactions.length.toString(),
                _formatDate(_dateRange!.start),
                _formatDate(_dateRange!.end),
              ]),
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
                icon: const Icon(CupertinoIcons.slider_horizontal_3),
                onPressed: _showImportSetupSheet,
                tooltip: 'Import setup'.tr(),
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.calendar),
                onPressed: _selectDateRange,
                tooltip: 'Select Date Range'.tr(),
              ),
            ]
          : null,
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
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
                      CupertinoIcons.calendar,
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
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _selectDateRange,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
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
                          CupertinoIcons.chevron_forward,
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
                  icon: CupertinoIcons.refresh,
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
              CupertinoIcons.chat_bubble_2_fill,
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
              icon: CupertinoIcons.check_mark_circled_solid,
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
              icon: CupertinoIcons.tray_full_fill,
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
                  icon: CupertinoIcons.refresh,
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
                CupertinoToast.show(
                  context,
                  message: imported == 0
                      ? 'No new SMS transactions to import'.tr()
                      : 'Successfully imported {} transactions!'
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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isExpense ? CupertinoIcons.arrow_down : CupertinoIcons.arrow_up,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withOpacity(0.5)),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
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
                  borderRadius: BorderRadius.circular(10),
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
