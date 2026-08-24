import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../core/services/currency_formatter.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/extensions.dart';
import '../../data/models/transaction_model.dart';
import '../blocs/transaction_bloc.dart';

Future<void> showTransactionDetailsSheet(
  BuildContext context,
  Transaction transaction,
) {
  final isExpense = transaction.type == TransactionType.expense;

  return showCupertinoModalPopup<void>(
    context: context,
    builder: (context) => Material(
      color: Colors.transparent,
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.border(context),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isExpense
                              ? [AppColors.expense.withOpacity(0.9), AppColors.error]
                              : [AppColors.income.withOpacity(0.9), AppColors.success],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.title,
                            style: AppTypography.headlineSmall(color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${isExpense ? '-' : '+'}${CurrencyFormatter.format(transaction.amount, currencyCode: transaction.currency)}',
                            style: AppTypography.displaySmall(color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _chip(
                                '${transaction.type.name.capitalize.tr()} ${'entry'.tr()}',
                                Colors.white.withOpacity(0.2),
                              ),
                              _chip(
                                transaction.category,
                                Colors.white.withOpacity(0.2),
                              ),
                              _chip(
                                transaction.currency,
                                Colors.white.withOpacity(0.2),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _DetailRow(label: 'Category'.tr(), value: transaction.category),
                    _DetailRow(
                      label: 'Type'.tr(),
                      value: transaction.type.name.capitalize.tr(),
                    ),
                    _DetailRow(
                      label: 'Date'.tr(),
                      value: transaction.date.toDateTime(),
                    ),
                    if (transaction.paymentMethod != null)
                      _DetailRow(
                        label: 'Payment'.tr(),
                        value: transaction.paymentMethod!,
                      ),
                    _DetailRow(label: 'Currency'.tr(), value: transaction.currency),
                    if (transaction.note != null && transaction.note!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant(context),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notes'.tr(),
                              style: AppTypography.labelMedium(
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              transaction.note!,
                              style: AppTypography.bodyMedium(),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: CupertinoButton(
                        color: AppColors.primary,
                        padding: EdgeInsets.zero,
                        borderRadius: BorderRadius.circular(14),
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditTransactionDialog(context, transaction);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(CupertinoIcons.pencil, size: 18, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'Edit Title & Category'.tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void _showEditTransactionDialog(BuildContext context, Transaction transaction) {
  final titleController = TextEditingController(text: transaction.title);
  final categoryController = TextEditingController(text: transaction.category);

  showCupertinoDialog<void>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text('Edit Transaction'.tr()),
      content: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          children: [
            CupertinoTextField(
              controller: titleController,
              placeholder: 'Title (e.g. Swiggy, Amazon)'.tr(),
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: categoryController,
              placeholder: 'Category (e.g. Food, Shopping)'.tr(),
            ),
          ],
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'.tr()),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () {
            final updatedTitle = titleController.text.trim();
            final updatedCategory = categoryController.text.trim();

            if (updatedTitle.isNotEmpty && updatedCategory.isNotEmpty) {
              final updated = transaction.copyWith(
                title: updatedTitle,
                category: updatedCategory,
              );
              context.read<TransactionBloc>().updateTransaction(updated);
            }
            Navigator.pop(context);
          },
          child: Text('Save'.tr()),
        ),
      ],
    ),
  );
}

Widget _chip(String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: AppTypography.labelSmall(color: Colors.white),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: AppTypography.bodySmall(
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
