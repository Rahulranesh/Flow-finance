import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/wallet_model.dart';

/// Filter criteria for transactions
class TransactionFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;
  final List<TransactionType>? types;
  final List<String>? categories;
  final List<String>? walletIds;
  final String? searchQuery;

  const TransactionFilter({
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.types,
    this.categories,
    this.walletIds,
    this.searchQuery,
  });

  TransactionFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    List<TransactionType>? types,
    List<String>? categories,
    List<String>? walletIds,
    String? searchQuery,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearMinAmount = false,
    bool clearMaxAmount = false,
    bool clearTypes = false,
    bool clearCategories = false,
    bool clearWalletIds = false,
    bool clearSearchQuery = false,
  }) {
    return TransactionFilter(
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      minAmount: clearMinAmount ? null : (minAmount ?? this.minAmount),
      maxAmount: clearMaxAmount ? null : (maxAmount ?? this.maxAmount),
      types: clearTypes ? null : (types ?? this.types),
      categories: clearCategories ? null : (categories ?? this.categories),
      walletIds: clearWalletIds ? null : (walletIds ?? this.walletIds),
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
    );
  }

  bool get isActive {
    return startDate != null ||
        endDate != null ||
        minAmount != null ||
        maxAmount != null ||
        (types != null && types!.isNotEmpty) ||
        (categories != null && categories!.isNotEmpty) ||
        (walletIds != null && walletIds!.isNotEmpty) ||
        (searchQuery != null && searchQuery!.isNotEmpty);
  }

  int get activeFilterCount {
    int count = 0;
    if (startDate != null || endDate != null) count++;
    if (minAmount != null || maxAmount != null) count++;
    if (types != null && types!.isNotEmpty) count++;
    if (categories != null && categories!.isNotEmpty) count++;
    if (walletIds != null && walletIds!.isNotEmpty) count++;
    if (searchQuery != null && searchQuery!.isNotEmpty) count++;
    return count;
  }

  /// Apply filter to a list of transactions
  List<Transaction> apply(List<Transaction> transactions) {
    return transactions.where((transaction) {
      // Date filter
      if (startDate != null && transaction.date.isBefore(startDate!)) {
        return false;
      }
      if (endDate != null && transaction.date.isAfter(endDate!)) {
        return false;
      }

      // Amount filter
      if (minAmount != null && transaction.amount < minAmount!) {
        return false;
      }
      if (maxAmount != null && transaction.amount > maxAmount!) {
        return false;
      }

      // Type filter
      if (types != null && types!.isNotEmpty) {
        if (!types!.contains(transaction.type)) {
          return false;
        }
      }

      // Category filter
      if (categories != null && categories!.isNotEmpty) {
        if (!categories!.contains(transaction.category)) {
          return false;
        }
      }

      // Wallet filter
      if (walletIds != null && walletIds!.isNotEmpty) {
        if (!walletIds!.contains(transaction.walletId)) {
          return false;
        }
      }

      // Search query filter
      if (searchQuery != null && searchQuery!.isNotEmpty) {
        final query = searchQuery!.toLowerCase();
        final matchesTitle = transaction.title.toLowerCase().contains(query);
        final matchesCategory = transaction.category.toLowerCase().contains(query);
        final matchesNote = transaction.note?.toLowerCase().contains(query) ?? false;
        if (!matchesTitle && !matchesCategory && !matchesNote) {
          return false;
        }
      }

      return true;
    }).toList();
  }
}

/// Filter panel widget for advanced filtering
class FilterPanel extends StatefulWidget {
  final TransactionFilter initialFilter;
  final List<Wallet> wallets;
  final List<String> availableCategories;
  final ValueChanged<TransactionFilter> onFilterChanged;
  final VoidCallback onClearFilters;

  const FilterPanel({
    super.key,
    required this.initialFilter,
    required this.wallets,
    required this.availableCategories,
    required this.onFilterChanged,
    required this.onClearFilters,
  });

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  late TransactionFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters'.tr(),
                  style: AppTypography.titleLarge(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                if (_filter.isActive)
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _clearAllFilters,
                    child: Text(
                      'Clear All'.tr(),
                      style: AppTypography.labelMedium(
                        color: AppColors.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Filter options
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Range
                  _buildSectionTitle('Date Range'.tr()),
                  const SizedBox(height: 12),
                  _buildDateRangeFilter(),
                  const SizedBox(height: 24),

                  // Amount Range
                  _buildSectionTitle('Amount Range'.tr()),
                  const SizedBox(height: 12),
                  _buildAmountRangeFilter(),
                  const SizedBox(height: 24),

                  // Transaction Type
                  _buildSectionTitle('Transaction Type'.tr()),
                  const SizedBox(height: 12),
                  _buildTypeFilter(),
                  const SizedBox(height: 24),

                  // Categories
                  _buildSectionTitle('Categories'.tr()),
                  const SizedBox(height: 12),
                  _buildCategoryFilter(),
                  const SizedBox(height: 24),

                  // Wallets
                  if (widget.wallets.isNotEmpty) ...[
                    _buildSectionTitle('Wallets'.tr()),
                    const SizedBox(height: 12),
                    _buildWalletFilter(),
                    const SizedBox(height: 24),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Apply button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: AppButton.primary(
                label: 'Apply Filters'.tr(),
                onPressed: () {
                  widget.onFilterChanged(_filter);
                  Navigator.pop(context);
                },
                expanded: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: AppTypography.titleSmall(
        color: isDark
            ? AppColors.textPrimaryDark
            : AppColors.textPrimaryLight,
      ),
    );
  }

  Widget _buildDateRangeFilter() {
    return Row(
      children: [
        Expanded(
          child: _buildDateButton(
            label: _filter.startDate != null
                ? '${_filter.startDate!.month}/${_filter.startDate!.day}/${_filter.startDate!.year}'
                : 'Start Date'.tr(),
            onTap: () => _selectStartDate(),
            isSelected: _filter.startDate != null,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'to'.tr(),
          style: AppTypography.bodyMedium(
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDateButton(
            label: _filter.endDate != null
                ? '${_filter.endDate!.month}/${_filter.endDate!.day}/${_filter.endDate!.year}'
                : 'End Date'.tr(),
            onTap: () => _selectEndDate(),
            isSelected: _filter.endDate != null,
          ),
        ),
      ],
    );
  }

  Widget _buildDateButton({
    required String label,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : isDark
                  ? AppColors.surfaceVariantDark
                  : AppColors.surfaceVariantLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : isDark
                    ? AppColors.borderDark
                    : AppColors.borderLight,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textSecondary(context),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.bodySmall(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textPrimary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountRangeFilter() {
    return Row(
      children: [
        Expanded(
          child: _buildAmountInput(
            hint: 'Min'.tr(),
            value: _filter.minAmount,
            onChanged: (value) {
              setState(() {
                _filter = _filter.copyWith(minAmount: value);
              });
            },
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'to'.tr(),
          style: AppTypography.bodyMedium(
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildAmountInput(
            hint: 'Max'.tr(),
            value: _filter.maxAmount,
            onChanged: (value) {
              setState(() {
                _filter = _filter.copyWith(maxAmount: value);
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAmountInput({
    required String hint,
    required double? value,
    required ValueChanged<double?> onChanged,
  }) {
    final controller = TextEditingController(
      text: value != null ? value.toStringAsFixed(0) : '',
    );

    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: hint,
        prefixText: '\$',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onChanged: (text) {
        final amount = double.tryParse(text);
        onChanged(amount);
      },
    );
  }

  Widget _buildTypeFilter() {
    final types = [
      _TypeOption('Income'.tr(), TransactionType.income, Icons.arrow_upward, AppColors.success),
      _TypeOption('Expense'.tr(), TransactionType.expense, Icons.arrow_downward, AppColors.error),
    ];

    return Wrap(
      spacing: 12,
      children: types.map((type) {
        final isSelected = _filter.types?.contains(type.type) ?? false;
        return GestureDetector(
          onTap: () {
            setState(() {
              final currentTypes = _filter.types ?? [];
              if (isSelected) {
                _filter = _filter.copyWith(
                  types: currentTypes.where((t) => t != type.type).toList(),
                );
              } else {
                _filter = _filter.copyWith(types: [...currentTypes, type.type]);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? type.color.withOpacity(0.1) : AppColors.surfaceVariant(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? type.color : AppColors.border(context).withOpacity(0.5),
                width: isSelected ? 1.5 : 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  type.icon,
                  color: isSelected ? type.color : AppColors.textSecondary(context),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(type.label, style: AppTypography.labelMedium(color: isSelected ? type.color : null)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.availableCategories.map((category) {
        final isSelected = _filter.categories?.contains(category) ?? false;
        return GestureDetector(
          onTap: () {
            setState(() {
              final currentCategories = _filter.categories ?? [];
              if (isSelected) {
                _filter = _filter.copyWith(
                  categories: currentCategories.where((c) => c != category).toList(),
                );
              } else {
                _filter = _filter.copyWith(
                  categories: [...currentCategories, category],
                );
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceVariant(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border(context).withOpacity(0.5),
                width: isSelected ? 1.5 : 0.5,
              ),
            ),
            child: Text(category, style: AppTypography.labelMedium(color: isSelected ? AppColors.primary : null)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWalletFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.wallets.map((wallet) {
        final isSelected = _filter.walletIds?.contains(wallet.id) ?? false;
        return GestureDetector(
          onTap: () {
            setState(() {
              final currentWalletIds = _filter.walletIds ?? [];
              if (isSelected) {
                _filter = _filter.copyWith(
                  walletIds: currentWalletIds.where((id) => id != wallet.id).toList(),
                );
              } else {
                _filter = _filter.copyWith(
                  walletIds: [...currentWalletIds, wallet.id],
                );
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? wallet.color.withOpacity(0.1) : AppColors.surfaceVariant(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? wallet.color : AppColors.border(context).withOpacity(0.5),
                width: isSelected ? 1.5 : 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: wallet.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(wallet.name, style: AppTypography.labelMedium(color: isSelected ? wallet.color : null)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _selectStartDate() async {
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
        child: CupertinoDatePicker(
          initialDateTime: _filter.startDate ?? DateTime.now(),
          minimumDate: DateTime(2020),
          maximumDate: _filter.endDate ?? DateTime.now(),
          mode: CupertinoDatePickerMode.date,
          onDateTimeChanged: (date) {
            Navigator.pop(context, date);
          },
        ),
      ),
    );
    if (date != null) {
      setState(() {
        _filter = _filter.copyWith(startDate: date);
      });
    }
  }

  Future<void> _selectEndDate() async {
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
        child: CupertinoDatePicker(
          initialDateTime: _filter.endDate ?? DateTime.now(),
          minimumDate: _filter.startDate ?? DateTime(2020),
          maximumDate: DateTime.now(),
          mode: CupertinoDatePickerMode.date,
          onDateTimeChanged: (date) {
            Navigator.pop(context, date);
          },
        ),
      ),
    );
    if (date != null) {
      setState(() {
        _filter = _filter.copyWith(endDate: date);
      });
    }
  }

  void _clearAllFilters() {
    setState(() {
      _filter = const TransactionFilter();
    });
    widget.onClearFilters();
  }
}

class _TypeOption {
  final String label;
  final TransactionType type;
  final IconData icon;
  final Color color;

  _TypeOption(this.label, this.type, this.icon, this.color);
}

/// Show filter panel as bottom sheet
Future<TransactionFilter?> showFilterPanel(
  BuildContext context, {
  required TransactionFilter initialFilter,
  required List<Wallet> wallets,
  required List<String> availableCategories,
}) async {
  return showCupertinoModalPopup<TransactionFilter>(
    context: context,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return FilterPanel(
            initialFilter: initialFilter,
            wallets: wallets,
            availableCategories: availableCategories,
            onFilterChanged: (filter) {
              Navigator.pop(context, filter);
            },
            onClearFilters: () {
              Navigator.pop(context, const TransactionFilter());
            },
          );
        },
      );
    },
  );
}
