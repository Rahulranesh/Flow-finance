import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/currency_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../data/models/recurring_transaction_model.dart';
import '../../../data/models/transaction_model.dart';
import 'package:flow_finance/core/utils/extensions.dart';
import '../../../data/repositories/recurring_transaction_repository.dart';

/// Recurring transactions management screen
class RecurringTransactionsScreen extends StatefulWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  State<RecurringTransactionsScreen> createState() =>
      _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState
    extends State<RecurringTransactionsScreen> {
  bool _isLoading = true;
  List<RecurringTransaction> _transactions = [];
  RecurringTransactionSummary? _summary;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final repo = context.read<RecurringTransactionRepository>();
      final transactions = await repo.getActive();
      final summary = await repo.getSummary();

      setState(() {
        _transactions = transactions;
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        context.showSnackBar(
          SnackBar(content: Text('Failed to load recurring transactions'.tr())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      title: 'Recurring'.tr(),
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: _createRecurring,
        ),
      ],
      body: _isLoading
          ? AppLoading.fullScreen()
          : Column(
              children: [
                // Summary Card
                if (_summary != null) _buildSummaryCard(isDark),

                // Transaction List
                Expanded(
                  child: _transactions.isEmpty
                      ? _buildEmptyState(isDark)
                      : _buildTransactionList(isDark),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryCard(bool isDark) {
    return AppCard(
      margin: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Monthly Income'.tr(),
                    _summary!.totalMonthlyIncome,
                    AppColors.success,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.border(context),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Monthly Expense'.tr(),
                    _summary!.totalMonthlyExpense,
                    AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: AppColors.border(context)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatChip(
                  'Active'.tr(),
                  _summary!.activeCount.toString(),
                  AppColors.primary,
                ),
                if (_summary!.dueTodayCount > 0)
                  _buildStatChip(
                    'Due Today'.tr(),
                    _summary!.dueTodayCount.toString(),
                    AppColors.warning,
                  ),
                if (_summary!.overdueCount > 0)
                  _buildStatChip(
                    'Overdue'.tr(),
                    _summary!.overdueCount.toString(),
                    AppColors.error,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.labelSmall(
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.format(amount, decimalDigits: 0),
          style: AppTypography.titleMedium(
            color: color,
          ).copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
            '${label.tr()}: ',
            style: AppTypography.labelSmall(
              color: AppColors.textSecondaryLight,
            ),
          ),
          Text(
            value,
            style: AppTypography.labelMedium(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.repeat,
            size: 80,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          const SizedBox(height: 24),
          Text(
            'No Recurring Transactions'.tr(),
            style: AppTypography.titleLarge(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set up recurring income or expenses\nto track them automatically'
                .tr(),
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 32),
          AppButton.primary(
            label: 'Add Recurring Transaction'.tr(),
            onPressed: _createRecurring,
            icon: Icons.add,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          final transaction = _transactions[index];
          return _RecurringTransactionCard(
            transaction: transaction,
            onToggle: () => _toggleTransaction(transaction),
            onDelete: () => _deleteTransaction(transaction),
            onEdit: () => _editTransaction(transaction),
          );
        },
      ),
    );
  }

  void _createRecurring() {
    _showRecurringDialog();
  }

  void _editTransaction(RecurringTransaction transaction) {
    _showRecurringDialog(transaction: transaction);
  }

  void _showRecurringDialog({RecurringTransaction? transaction}) {
    final isEditing = transaction != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RecurringTransactionForm(
        transaction: transaction,
        onSave: (data) async {
          try {
            final repo = context.read<RecurringTransactionRepository>();

            if (isEditing) {
              final updated = transaction.copyWith(
                title: data['title'] as String,
                amount: data['amount'] as double,
                type: data['type'] as TransactionType,
                category: data['category'] as String,
                frequency: data['frequency'] as RecurringFrequency,
                startDate: data['startDate'] as DateTime,
                endCondition: data['endCondition'] as EndConditionType,
                occurrenceCount: data['occurrenceCount'] as int?,
                endDate: data['endDate'] as DateTime?,
              );
              await repo.update(updated);
            } else {
              await repo.create(
                id: const Uuid().v4(),
                title: data['title'] as String,
                amount: data['amount'] as double,
                type: data['type'] as TransactionType,
                category: data['category'] as String,
                frequency: data['frequency'] as RecurringFrequency,
                startDate: data['startDate'] as DateTime,
                endCondition: data['endCondition'] as EndConditionType,
                occurrenceCount: data['occurrenceCount'] as int?,
                endDate: data['endDate'] as DateTime?,
              );
            }

            Navigator.pop(context);
            _loadData();
          } catch (e) {
            context.showSnackBar(
              SnackBar(
                content: Text(
                  isEditing
                      ? 'Failed to update transaction'.tr()
                      : 'Failed to create transaction'.tr(),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _toggleTransaction(RecurringTransaction transaction) async {
    try {
      final repo = context.read<RecurringTransactionRepository>();
      await repo.toggleActive(transaction.id);
      _loadData();
    } catch (e) {
      if (mounted) {
        context.showSnackBar(
          SnackBar(content: Text('Failed to update transaction'.tr())),
        );
      }
    }
  }

  Future<void> _deleteTransaction(RecurringTransaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Recurring Transaction'.tr()),
        content:
            Text('Are you sure you want to delete "${transaction.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'.tr(),
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = context.read<RecurringTransactionRepository>();
        await repo.delete(transaction.id);
        _loadData();
      } catch (e) {
        if (mounted) {
          context.showSnackBar(
            SnackBar(content: Text('Failed to delete transaction'.tr())),
          );
        }
      }
    }
  }
}

class _RecurringTransactionCard extends StatelessWidget {
  final RecurringTransaction transaction;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _RecurringTransactionCard({
    required this.transaction,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? AppColors.success : AppColors.error;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.title,
                          style: AppTypography.bodyMedium(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          transaction.category,
                          style: AppTypography.labelSmall(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isIncome ? '+' : '-'}${CurrencyFormatter.format(transaction.amount)}',
                        style: AppTypography.bodyMedium(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '/${transaction.frequency.shortName}',
                        style: AppTypography.labelSmall(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: AppColors.border(context)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusChip(),
                  Row(
                    children: [
                      if (transaction.isDueToday)
                        _buildActionChip('Due Today'.tr(), AppColors.warning),
                      if (transaction.isOverdue)
                        _buildActionChip('Overdue'.tr(), AppColors.error),
                      const SizedBox(width: 8),
                      Switch(
                        value: transaction.isActive,
                        onChanged: (_) => onToggle(),
                        activeColor: AppColors.primary,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.error),
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    if (transaction.hasEnded) {
      return _buildChip('Ended'.tr(), AppColors.textSecondaryLight);
    }
    if (!transaction.isActive) {
      return _buildChip('Paused'.tr(), AppColors.warning);
    }
    return _buildChip('Active'.tr(), AppColors.success);
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall(color: color),
      ),
    );
  }

  Widget _buildActionChip(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RecurringTransactionForm extends StatefulWidget {
  final RecurringTransaction? transaction;
  final Function(Map<String, dynamic>) onSave;

  const _RecurringTransactionForm({
    this.transaction,
    required this.onSave,
  });

  @override
  State<_RecurringTransactionForm> createState() =>
      _RecurringTransactionFormState();
}

class _RecurringTransactionFormState extends State<_RecurringTransactionForm> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  bool _isExpense = true;
  RecurringFrequency _frequency = RecurringFrequency.monthly;
  EndConditionType _endCondition = EndConditionType.never;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  int? _occurrenceCount;

  final List<String> _categories = [
    'Food',
    'Shopping',
    'Transport',
    'Entertainment',
    'Health',
    'Bills',
    'Education',
    'Salary',
    'Freelance',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _titleController.text = widget.transaction!.title;
      _amountController.text = widget.transaction!.amount.toString();
      _categoryController.text = widget.transaction!.category;
      _isExpense = widget.transaction!.type == TransactionType.expense;
      _frequency = widget.transaction!.frequency;
      _endCondition = widget.transaction!.endCondition;
      _startDate = widget.transaction!.startDate;
      _endDate = widget.transaction!.endDate;
      _occurrenceCount = widget.transaction!.occurrenceCount;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  widget.transaction != null
                      ? 'Edit Recurring Transaction'.tr()
                      : 'Add Recurring Transaction'.tr(),
                  style: AppTypography.titleLarge(),
                ),
                const SizedBox(height: 24),

                // Type Toggle
                Row(
                  children: [
                    Expanded(
                      child: _buildTypeButton(
                          'Expense'.tr(), true, AppColors.error),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTypeButton(
                          'Income'.tr(), false, AppColors.success),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Title
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title'.tr(),
                    hintText: 'e.g., Rent, Salary'.tr(),
                  ),
                ),
                const SizedBox(height: 16),

                // Amount
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount'.tr(),
                    prefixText: CurrencyFormatter.currentCurrency.symbol,
                  ),
                ),
                const SizedBox(height: 16),

                // Category
                DropdownButtonFormField<String>(
                  value: _categories.contains(_categoryController.text)
                      ? _categoryController.text
                      : null,
                  decoration: InputDecoration(labelText: 'Category'.tr()),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _categoryController.text = value ?? ''),
                ),
                const SizedBox(height: 20),

                // Frequency
                Text('Frequency'.tr(), style: AppTypography.titleSmall()),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: RecurringFrequency.values.map((f) {
                    final isSelected = _frequency == f;
                    return ChoiceChip(
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _frequency = f);
                      },
                      label: Text(f.displayName),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Start Date
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Start Date'.tr()),
                  subtitle: Text(
                      '${_startDate.month}/${_startDate.day}/${_startDate.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) setState(() => _startDate = date);
                  },
                ),
                const SizedBox(height: 16),

                // End Condition
                Text('End Condition'.tr(), style: AppTypography.titleSmall()),
                const SizedBox(height: 8),
                Column(
                  children: [
                    RadioListTile<EndConditionType>(
                      title: Text('Never'.tr()),
                      value: EndConditionType.never,
                      groupValue: _endCondition,
                      onChanged: (v) => setState(() => _endCondition = v!),
                    ),
                    RadioListTile<EndConditionType>(
                      title: Text('After specific number of occurrences'.tr()),
                      value: EndConditionType.afterCount,
                      groupValue: _endCondition,
                      onChanged: (v) => setState(() => _endCondition = v!),
                    ),
                    if (_endCondition == EndConditionType.afterCount)
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 48, right: 16, bottom: 8),
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Number of occurrences'.tr(),
                            hintText: 'e.g., 12'.tr(),
                          ),
                          onChanged: (v) => _occurrenceCount = int.tryParse(v),
                        ),
                      ),
                    RadioListTile<EndConditionType>(
                      title: Text('On specific date'.tr()),
                      value: EndConditionType.onDate,
                      groupValue: _endCondition,
                      onChanged: (v) => setState(() => _endCondition = v!),
                    ),
                    if (_endCondition == EndConditionType.onDate)
                      ListTile(
                        contentPadding:
                            const EdgeInsets.only(left: 48, right: 16),
                        title: Text('End Date'.tr()),
                        subtitle: Text(_endDate != null
                            ? '${_endDate!.month}/${_endDate!.day}/${_endDate!.year}'
                            : 'Select date'.tr()),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _endDate ??
                                DateTime.now().add(const Duration(days: 365)),
                            firstDate: _startDate,
                            lastDate: DateTime(2030),
                          );
                          if (date != null) setState(() => _endDate = date);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 32),

                // Save Button
                AppButton.primary(
                  label: widget.transaction != null
                      ? 'Update'.tr()
                      : 'Create'.tr(),
                  onPressed: _save,
                  expanded: true,
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeButton(String label, bool isExpense, Color color) {
    final isSelected = _isExpense == isExpense;
    return GestureDetector(
      onTap: () => setState(() => _isExpense = isExpense),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.border(context),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isExpense ? Icons.arrow_downward : Icons.arrow_upward,
              color: isSelected ? color : AppColors.textSecondary(context),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.labelMedium(
                color: isSelected ? color : AppColors.textPrimary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      context.showSnackBar(
        SnackBar(content: Text('Please enter a valid amount'.tr())),
      );
      return;
    }

    if (_titleController.text.isEmpty) {
      context.showSnackBar(
        SnackBar(content: Text('Please enter a title'.tr())),
      );
      return;
    }

    if (_categoryController.text.isEmpty) {
      context.showSnackBar(
        SnackBar(content: Text('Please select a category'.tr())),
      );
      return;
    }

    widget.onSave({
      'title': _titleController.text,
      'amount': amount,
      'type': _isExpense ? TransactionType.expense : TransactionType.income,
      'category': _categoryController.text,
      'frequency': _frequency,
      'startDate': _startDate,
      'endCondition': _endCondition,
      'occurrenceCount': _occurrenceCount,
      'endDate': _endDate,
    });
  }
}
