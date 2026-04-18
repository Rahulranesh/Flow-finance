import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Add transaction screen with clean number pad and category selection
class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final TextEditingController _noteController = TextEditingController();
  String _amount = '0';
  bool _isExpense = true;
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();

  final List<_Category> _categories = [
    _Category('Food', Icons.restaurant, const Color(0xFFF59E0B)),
    _Category('Shopping', Icons.shopping_bag, const Color(0xFFEC4899)),
    _Category('Transport', Icons.directions_car, const Color(0xFF3B82F6)),
    _Category('Entertainment', Icons.movie, const Color(0xFF8B5CF6)),
    _Category('Health', Icons.favorite, const Color(0xFFEF4444)),
    _Category('Bills', Icons.receipt, const Color(0xFF64748B)),
    _Category('Education', Icons.school, const Color(0xFF14B8A6)),
    _Category('Other', Icons.more_horiz, const Color(0xFF94A3B8)),
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _onNumberPressed(String number) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_amount == '0') {
        _amount = number;
      } else {
        _amount += number;
      }
    });
  }

  void _onBackspace() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_amount.length > 1) {
        _amount = _amount.substring(0, _amount.length - 1);
      } else {
        _amount = '0';
      }
    });
  }

  void _onDecimal() {
    HapticFeedback.lightImpact();
    setState(() {
      if (!_amount.contains('.')) {
        _amount += '.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Add Transaction',
      body: Column(
        children: [
          // Amount Display
          _AmountDisplay(
            amount: _amount,
            isExpense: _isExpense,
            onToggleType: () {
              setState(() {
                _isExpense = !_isExpense;
              });
            },
          ),

          // Category Selection
          _CategorySelector(
            categories: _categories,
            selectedCategory: _selectedCategory,
            onCategorySelected: (category) {
              setState(() {
                _selectedCategory = category;
              });
            },
          ),

          // Date and Note
          _DateAndNoteSection(
            selectedDate: _selectedDate,
            onDateChanged: (date) {
              setState(() {
                _selectedDate = date;
              });
            },
            noteController: _noteController,
          ),

          const Spacer(),

          // Number Pad
          _NumberPad(
            onNumberPressed: _onNumberPressed,
            onBackspace: _onBackspace,
            onDecimal: _onDecimal,
          ),

          // Save Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: AppButton.primary(
              label: 'Save Transaction',
              onPressed: () {},
              expanded: true,
              size: AppButtonSize.large,
            ),
          ),
        ],
      ),
    );
  }
}

/// Amount display section
class _AmountDisplay extends StatelessWidget {
  final String amount;
  final bool isExpense;
  final VoidCallback onToggleType;

  const _AmountDisplay({
    required this.amount,
    required this.isExpense,
    required this.onToggleType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Type Toggle
          Row(
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

          const SizedBox(height: 24),

          // Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '\$',
                style: AppTypography.displayMedium(
                  color: AppColors.textSecondary(context),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                amount,
                style: AppTypography.displayLarge(
                  color: isExpense ? AppColors.expense : AppColors.income,
                ),
              ),
            ],
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppColors.border(context),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelLarge(
            color: isSelected ? color : AppColors.textSecondary(context),
          ),
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
            'Category',
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
                    borderRadius: BorderRadius.circular(16),
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
                        category.name,
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
              final date = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2026),
              );
              if (date != null) {
                onDateChanged(date);
              }
            },
            child: AppCard(
              variant: AppCardVariant.flat,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.calendar_today,
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
                          'Date',
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
                    Icons.chevron_right,
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
            hint: 'Add a note...',
            prefixIcon: Icons.edit_note,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

/// Number pad
class _NumberPad extends StatelessWidget {
  final ValueChanged<String> onNumberPressed;
  final VoidCallback onBackspace;
  final VoidCallback onDecimal;

  const _NumberPad({
    required this.onNumberPressed,
    required this.onBackspace,
    required this.onDecimal,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              _NumberButton('1', onNumberPressed),
              _NumberButton('2', onNumberPressed),
              _NumberButton('3', onNumberPressed),
            ],
          ),
          Row(
            children: [
              _NumberButton('4', onNumberPressed),
              _NumberButton('5', onNumberPressed),
              _NumberButton('6', onNumberPressed),
            ],
          ),
          Row(
            children: [
              _NumberButton('7', onNumberPressed),
              _NumberButton('8', onNumberPressed),
              _NumberButton('9', onNumberPressed),
            ],
          ),
          Row(
            children: [
              _NumberButton('.', onDecimal, isSpecial: true),
              _NumberButton('0', onNumberPressed),
              _ActionButton(
                icon: Icons.backspace_outlined,
                onTap: onBackspace,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NumberButton extends StatelessWidget {
  final String label;
  final VoidCallback? onSpecialTap;
  final ValueChanged<String>? onNumberTap;
  final bool isSpecial;

  const _NumberButton(
    this.label,
    dynamic onTap, {
    this.isSpecial = false,
  })  : onSpecialTap = onTap is VoidCallback ? onTap : null,
        onNumberTap = onTap is ValueChanged<String> ? onTap : null;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (onNumberTap != null) {
            onNumberTap!(label);
          } else if (onSpecialTap != null) {
            onSpecialTap!();
          }
        },
        child: Container(
          height: 64,
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isSpecial
                ? AppColors.surfaceVariant(context)
                : AppColors.surface(context),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTypography.headlineSmall(),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onTap,
        child: Container(
          height: 64,
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant(context),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Icon(
              icon,
              color: AppColors.textSecondary(context),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class _Category {
  final String name;
  final IconData icon;
  final Color color;

  _Category(this.name, this.icon, this.color);
}
