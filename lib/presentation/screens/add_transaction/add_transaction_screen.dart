import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/theme.dart';
import '../../../core/services/currency_formatter.dart';
import '../../../core/widgets/mascot_snackbar.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/validators/validators.dart';
import '../../../data/models/models.dart';
import '../../blocs/blocs.dart';

/// Add transaction screen with clean number pad and category selection
class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _isExpense = true;
  String _selectedCategory = 'Food';
  String? _selectedWalletId;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  final FocusNode _amountFocus = FocusNode();

  final List<_Category> _categories = [
    _Category('Food', Icons.restaurant, const Color(0xFFD4AF37)),
    _Category('Shopping', CupertinoIcons.bag, const Color(0xFF6B7280)),
    _Category('Transport', CupertinoIcons.car, const Color(0xFF9CA3AF)),
    _Category('Entertainment', CupertinoIcons.film, const Color(0xFFC7A252)),
    _Category('Health', CupertinoIcons.heart, const Color(0xFFEF4444)),
    _Category('Bills', CupertinoIcons.doc_text, const Color(0xFF64748B)),
    _Category('Education', CupertinoIcons.book, const Color(0xFF6B7280)),
    _Category('Salary', CupertinoIcons.briefcase, const Color(0xFFB8860B)),
    _Category('Freelance', Icons.laptop, const Color(0xFFB8860B)),
  ];

  @override
  void dispose() {
    _noteController.dispose();
    _amountController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    final amountText = _amountController.text.trim();
    // Validate amount
    final amountError =
        FormValidators.positiveNumber(amountText, fieldName: 'Amount');
    if (amountError != null) {
      context.showMascotSnackBar(amountError, type: MascotSnackBarType.error);
      return;
    }

    final amount = double.parse(amountText);
    if (amount <= 0) {
      context.showMascotSnackBar('Please enter a valid amount'.tr(),
          type: MascotSnackBarType.error);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get wallet info if selected
      final walletBloc = context.read<WalletBloc>();
      final selectedWallet = _selectedWalletId != null
          ? walletBloc.wallets.firstWhere(
              (w) => w.id == _selectedWalletId,
              orElse: () => walletBloc.defaultWallet!,
            )
          : walletBloc.defaultWallet;

      final transaction = Transaction(
        id: const Uuid().v4(),
        title: _isExpense ? _selectedCategory.tr() : 'Income'.tr(),
        amount: amount,
        type: _isExpense ? TransactionType.expense : TransactionType.income,
        category: _selectedCategory,
        date: _selectedDate,
        note: _noteController.text.isEmpty ? null : _noteController.text,
        walletId: selectedWallet?.id,
        currency:
            selectedWallet?.currency ?? CurrencyFormatter.currentCurrencyCode,
      );

      await context.read<TransactionBloc>().addTransaction(transaction);
      // Refresh wallet balances
      if (mounted) {
        context.read<WalletBloc>().refreshBalances();
      }

      if (mounted) {
        context.showMascotSnackBar('Transaction saved successfully'.tr(),
            type: MascotSnackBarType.success);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        context.showMascotSnackBar('Failed to save transaction'.tr(),
            type: MascotSnackBarType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Transaction'.tr()),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: FlowMascotBubble(
                message: _isExpense
                    ? 'What did you spend on?'.tr()
                    : 'Nice. Let\'s log your income.'.tr(),
                subtitle: 'One step at a time. No forms, no pressure.'.tr(),
              ),
            ),
            _AmountField(
              controller: _amountController,
              focusNode: _amountFocus,
              autofocus: true,
              isExpense: _isExpense,
              onToggleType: () {
                setState(() {
                  _isExpense = !_isExpense;
                });
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _amountFocus.requestFocus();
                });
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _CategorySelector(
                      categories: _categories,
                      selectedCategory: _selectedCategory,
                      onCategorySelected: (category) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: FlowMascotBubble(
                        message: 'Smart pick: {category}'
                            .tr(namedArgs: {'category': _selectedCategory}),
                        subtitle:
                            'Tap a category above or keep moving if this is correct.'
                                .tr(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _WalletSelector(
                      selectedWalletId: _selectedWalletId,
                      onWalletSelected: (walletId) {
                        setState(() {
                          _selectedWalletId = walletId;
                        });
                      },
                    ),
                    _DateAndNoteSection(
                      selectedDate: _selectedDate,
                      onDateChanged: (date) {
                        setState(() {
                          _selectedDate = date;
                        });
                      },
                      noteController: _noteController,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: AppButton.primary(
                label: _isLoading ? 'Saving...'.tr() : 'Save Transaction'.tr(),
                onPressed: _isLoading ? null : _saveTransaction,
                expanded: true,
                size: AppButtonSize.large,
                icon: _isLoading ? null : CupertinoIcons.checkmark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Amount input field with Cupertino text field
class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isExpense;
  final VoidCallback onToggleType;
  final bool autofocus;

  const _AmountField({
    required this.controller,
    required this.focusNode,
    required this.isExpense,
    required this.onToggleType,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isExpense ? AppColors.expense : AppColors.income;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border(context).withOpacity(0.5),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          // Type Toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TypeButton(
                  label: 'Expense',
                  isSelected: isExpense,
                  color: AppColors.expense,
                  onTap: onToggleType,
                ),
                const SizedBox(width: 12),
                _TypeButton(
                  label: 'Income',
                  isSelected: !isExpense,
                  color: AppColors.income,
                  onTap: onToggleType,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Amount Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CupertinoTextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: autofocus,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
              placeholder: '0.00',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: accentColor.withOpacity(0.15),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              prefix: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  CurrencyFormatter.currentCurrency.symbol,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: accentColor.withOpacity(0.6),
                  ),
                ),
              ),
              clearButtonMode: OverlayVisibilityMode.editing,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.12)
              : AppColors.surfaceVariant(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                isSelected ? color : AppColors.border(context).withOpacity(0.5),
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected
                  ? (color == AppColors.expense
                      ? CupertinoIcons.arrow_down_right
                      : CupertinoIcons.arrow_up_right)
                  : CupertinoIcons.minus,
              size: 16,
              color: isSelected ? color : AppColors.textTertiary(context),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.labelLarge(
                color: isSelected ? color : AppColors.textSecondary(context),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Category selector
class _CategorySelector extends StatelessWidget {
  final List<_Category> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const _CategorySelector({
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Text(
            'Category'.tr(),
            style: AppTypography.labelLarge(),
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = category.name == selectedCategory;

              return GestureDetector(
                onTap: () => onCategorySelected(category.name),
                child: AnimatedContainer(
                  duration: AppAnimations.fast,
                  width: 80,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? category.color.withOpacity(0.1)
                        : AppColors.surfaceVariant(context),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? category.color : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        category.icon,
                        color: category.color,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category.name.tr(),
                        style: AppTypography.caption(),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Date and note section
class _DateAndNoteSection extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final TextEditingController noteController;

  const _DateAndNoteSection({
    required this.selectedDate,
    required this.onDateChanged,
    required this.noteController,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Date Picker
          GestureDetector(
            onTap: () async {
              final date = await showCupertinoModalPopup<DateTime>(
                context: context,
                builder: (context) => Container(
                  height: 300,
                  padding: const EdgeInsets.only(top: 40),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: CupertinoDatePicker(
                          initialDateTime: selectedDate,
                          minimumDate: DateTime(2020),
                          maximumDate: DateTime(2026),
                          mode: CupertinoDatePickerMode.date,
                          onDateTimeChanged: (date) {
                            Navigator.pop(context, date);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
              if (date != null) {
                onDateChanged(date);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      CupertinoIcons.calendar,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date'.tr(),
                          style: AppTypography.caption(
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(selectedDate),
                          style: AppTypography.bodyLarge(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_right,
                    color: AppColors.textTertiary(context),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Note Input
          AppInput(
            controller: noteController,
            hint: 'Add a note...'.tr(),
            prefixIcon: CupertinoIcons.pencil,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _WalletSelector extends StatelessWidget {
  final String? selectedWalletId;
  final ValueChanged<String?> onWalletSelected;

  const _WalletSelector({
    required this.selectedWalletId,
    required this.onWalletSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletBloc>(
      builder: (context, walletBloc, child) {
        final wallets = walletBloc.activeWallets;

        if (wallets.isEmpty) {
          return const SizedBox.shrink();
        }

        final selectedWallet = selectedWalletId != null
            ? wallets.firstWhere(
                (w) => w.id == selectedWalletId,
                orElse: () => wallets.first,
              )
            : wallets.firstWhere(
                (w) => w.isDefault,
                orElse: () => wallets.first,
              );

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.border(context),
            ),
          ),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.creditcard,
                color: AppColors.textSecondary(context),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wallet',
                      style: AppTypography.labelSmall(
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selectedWallet.name,
                      style: AppTypography.bodyMedium(
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final selected = await showCupertinoModalPopup<String>(
                    context: context,
                    builder: (ctx) => CupertinoActionSheet(
                      title: Text('Select Wallet'.tr()),
                      actions: wallets
                          .map((w) => CupertinoActionSheetAction(
                                child: Row(
                                  children: [
                                    Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                            color: w.color,
                                            shape: BoxShape.circle)),
                                    const SizedBox(width: 8),
                                    Text(w.name),
                                    if (w.isDefault) ...[
                                      const SizedBox(width: 4),
                                      Text('(Default)'.tr(),
                                          style: AppTypography.labelSmall(
                                              color: AppColors.textSecondary(
                                                  ctx))),
                                    ],
                                  ],
                                ),
                                onPressed: () => Navigator.pop(ctx, w.id),
                              ))
                          .toList(),
                      cancelButton: CupertinoActionSheetAction(
                        isDefaultAction: true,
                        child: Text('Cancel'.tr()),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                  );
                  if (selected != null) onWalletSelected(selected);
                },
                child: Row(
                  children: [
                    Icon(CupertinoIcons.chevron_down,
                        color: AppColors.textSecondary(context), size: 18),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Category {
  final String name;
  final IconData icon;
  final Color color;

  _Category(this.name, this.icon, this.color);
}
