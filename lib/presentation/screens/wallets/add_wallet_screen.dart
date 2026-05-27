import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../../core/services/currency_formatter.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/wallet_model.dart';
import '../../../core/utils/extensions.dart';
import '../../blocs/wallet_bloc.dart';

/// Add/Edit wallet screen
class AddWalletScreen extends StatefulWidget {
  final Wallet? wallet;

  const AddWalletScreen({super.key, this.wallet});

  @override
  State<AddWalletScreen> createState() => _AddWalletScreenState();
}

class _AddWalletScreenState extends State<AddWalletScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();

  WalletType _selectedType = WalletType.cash;
  Color _selectedColor = AppColors.primary;
  IconData _selectedIcon = Icons.account_balance_wallet;

  final List<Color> _colors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.success,
    AppColors.warning,
    AppColors.error,
    const Color(0xFF9C27B0),
    const Color(0xFF00BCD4),
    const Color(0xFFFF9800),
    const Color(0xFF4CAF50),
    const Color(0xFFE91E63),
  ];

  final List<IconData> _icons = [
    Icons.account_balance_wallet,
    Icons.account_balance,
    CupertinoIcons.creditcard,
    Icons.savings,
    CupertinoIcons.money_dollar,
    Icons.monetization_on,
    Icons.payment,
    Icons.wallet,
    Icons.currency_exchange,
    Icons.account_balance_wallet_outlined,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.wallet != null) {
      _nameController.text = widget.wallet!.name;
      _balanceController.text = widget.wallet!.balance.toString();
      _selectedType = widget.wallet!.type;
      _selectedColor = widget.wallet!.color;
      _selectedIcon = widget.wallet!.icon;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.wallet != null;

    return AppScaffold(
      title: isEdit ? 'Edit Wallet'.tr() : 'Add Wallet'.tr(),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Preview Card
            _buildPreviewCard(),
            const SizedBox(height: 24),

            // Name Field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Wallet Name'.tr(),
                hintText: 'e.g., Main Account, Savings'.tr(),
                prefixIcon: Icon(CupertinoIcons.tag),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter wallet name'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Balance Field
            TextFormField(
              controller: _balanceController,
              decoration: InputDecoration(
                labelText: 'Initial Balance'.tr(),
                hintText: '0.00'.tr(),
                prefixIcon: Icon(CupertinoIcons.money_dollar),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter initial balance'.tr();
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Wallet Type
            Text(
              'Wallet Type'.tr(),
              style: AppTypography.titleSmall(),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: WalletType.values.map((type) {
                final isSelected = type == _selectedType;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedType = type;
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getTypeIcon(type),
                          size: 18,
                          color: isSelected ? AppColors.primary : AppColors.textSecondary(context),
                        ),
                        const SizedBox(width: 6),
                        Text(_getTypeName(type), style: AppTypography.labelMedium(color: isSelected ? AppColors.primary : null)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Color Selection
            Text(
              'Color'.tr(),
              style: AppTypography.titleSmall(),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _colors.map((color) {
                final isSelected = color == _selectedColor;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(CupertinoIcons.check_mark, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Icon Selection
            Text(
              'Icon'.tr(),
              style: AppTypography.titleSmall(),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _icons.map((icon) {
                final isSelected = icon == _selectedIcon;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIcon = icon;
                    });
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _selectedColor.withOpacity(0.2)
                          : AppColors.surfaceVariant(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? _selectedColor : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected
                          ? _selectedColor
                          : AppColors.textSecondary(context),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Save Button
            AppButton.primary(
              label: isEdit ? 'Update Wallet'.tr() : 'Create Wallet'.tr(),
              onPressed: _saveWallet,
              expanded: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _selectedColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _selectedIcon,
                color: _selectedColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _nameController.text.isEmpty
                        ? 'Wallet Name'.tr()
                        : _nameController.text,
                    style: AppTypography.titleMedium(),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getTypeName(_selectedType),
                    style: AppTypography.bodySmall(
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${CurrencyFormatter.currentCurrency.symbol}${_balanceController.text.isEmpty ? '0.00' : _balanceController.text}',
              style: AppTypography.titleLarge(
                color: _selectedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeName(WalletType type) {
    switch (type) {
      case WalletType.cash:
        return 'Cash'.tr();
      case WalletType.bank:
        return 'Bank Account'.tr();
      case WalletType.creditCard:
        return 'Credit/Debit Card'.tr();
      case WalletType.savings:
        return 'Savings'.tr();
      case WalletType.investment:
        return 'Investment'.tr();
      case WalletType.digital:
        return 'Digital Wallet'.tr();
      case WalletType.other:
        return 'Other'.tr();
    }
  }

  IconData _getTypeIcon(WalletType type) {
    switch (type) {
      case WalletType.cash:
        return CupertinoIcons.money_dollar;
      case WalletType.bank:
        return Icons.account_balance;
      case WalletType.creditCard:
        return CupertinoIcons.creditcard;
      case WalletType.savings:
        return Icons.savings;
      case WalletType.investment:
        return Icons.trending_up;
      case WalletType.digital:
        return CupertinoIcons.phone;
      case WalletType.other:
        return Icons.wallet;
    }
  }

  Future<void> _saveWallet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text;
    final balance = double.parse(_balanceController.text);

    final wallet = Wallet(
      id: widget.wallet?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      balance: balance,
      type: _selectedType,
      currency: CurrencyFormatter.currentCurrencyCode,
      colorValue: _selectedColor.value,
      isDefault: widget.wallet?.isDefault ?? false,
      isArchived: false,
      createdAt: widget.wallet?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      final bloc = context.read<WalletBloc>();
      if (widget.wallet != null) {
        await bloc.updateWallet(wallet);
      } else {
        await bloc.addWallet(wallet);
      }

      if (mounted) {
        Navigator.pop(context);
        CupertinoToast.show(
          context,
          message: widget.wallet != null
              ? 'Wallet updated'.tr()
              : 'Wallet created'.tr(),
        );
      }
    } catch (e) {
      if (mounted) {
        CupertinoToast.show(
          context,
          message: '${'Error'.tr()}: $e',
          type: CupertinoToastType.error,
        );
      }
    }
  }
}
