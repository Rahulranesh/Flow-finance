import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../data/models/wallet_model.dart';
import '../../blocs/wallet_bloc.dart';

class WalletsScreen extends StatefulWidget {
  const WalletsScreen({super.key});

  @override
  State<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends State<WalletsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletBloc>().loadWallets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      title: 'Wallets',
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _showAddWalletDialog(context),
        ),
      ],
      body: Consumer<WalletBloc>(
        builder: (context, bloc, child) {
          if (bloc.isLoading && bloc.wallets.isEmpty) {
            return AppLoading.fullScreen(message: 'Loading wallets...');
          }

          return CustomScrollView(
            slivers: [
              // Total Balance Card
              SliverToBoxAdapter(
                child: _buildTotalBalanceCard(context, bloc, isDark),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Wallets List Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Your Wallets',
                    style: AppTypography.titleMedium(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Wallets List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final wallet = bloc.activeWallets[index];
                      return _buildWalletCard(context, wallet, bloc, isDark);
                    },
                    childCount: bloc.activeWallets.length,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Transfer Button
              if (bloc.activeWallets.length >= 2)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: AppButton.secondary(
                      label: 'Transfer Between Wallets',
                      onPressed: () => _showTransferDialog(context, bloc),
                      icon: Icons.swap_horiz,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTotalBalanceCard(BuildContext context, WalletBloc bloc, bool isDark) {
    return AppCard(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Balance',
              style: AppTypography.bodyMedium(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '\$${bloc.totalBalance.toStringAsFixed(2)}',
              style: AppTypography.displaySmall(
                color: Colors.white,
              ),
            ),
            if (bloc.balancesByCurrency.length > 1) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                children: bloc.balancesByCurrency.entries.map((entry) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${entry.key}: ${entry.value.toStringAsFixed(2)}',
                      style: AppTypography.bodySmall(
                        color: Colors.white,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context, Wallet wallet, WalletBloc bloc, bool isDark) {
    return Dismissible(
      key: Key(wallet.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => bloc.deleteWallet(wallet.id),
      child: AppCard(
        margin: const EdgeInsets.only(bottom: 12),
        onTap: () => _showEditWalletDialog(context, wallet, bloc),
        child: Row(
          children: [
            // Wallet Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: wallet.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                wallet.icon,
                color: wallet.color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),

            // Wallet Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        wallet.name,
                        style: AppTypography.titleSmall(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      if (wallet.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Default',
                            style: AppTypography.labelSmall(
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    wallet.type.displayName,
                    style: AppTypography.bodySmall(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),

            // Balance
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${wallet.currency} ${wallet.balance.toStringAsFixed(2)}',
                  style: AppTypography.titleSmall(
                    color: wallet.balance >= 0 ? AppColors.success : AppColors.error,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                if (!wallet.isDefault)
                  TextButton(
                    onPressed: () => bloc.setDefaultWallet(wallet.id),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Set as Default',
                      style: AppTypography.labelSmall(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddWalletDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const WalletDialog(),
    );
  }

  void _showEditWalletDialog(BuildContext context, Wallet wallet, WalletBloc bloc) {
    showDialog(
      context: context,
      builder: (context) => WalletDialog(wallet: wallet),
    );
  }

  void _showTransferDialog(BuildContext context, WalletBloc bloc) {
    showDialog(
      context: context,
      builder: (context) => WalletTransferDialog(bloc: bloc),
    );
  }
}

/// Dialog for adding/editing wallet
class WalletDialog extends StatefulWidget {
  final Wallet? wallet;

  const WalletDialog({super.key, this.wallet});

  @override
  State<WalletDialog> createState() => _WalletDialogState();
}

class _WalletDialogState extends State<WalletDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  late final TextEditingController _noteController;
  late WalletType _selectedType;
  late String _selectedCurrency;
  late int _selectedColor;

  final List<String> _currencies = ['USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.wallet?.name ?? '');
    _balanceController = TextEditingController(
      text: widget.wallet?.balance.toString() ?? '0.00',
    );
    _noteController = TextEditingController(text: widget.wallet?.note ?? '');
    _selectedType = widget.wallet?.type ?? WalletType.cash;
    _selectedCurrency = widget.wallet?.currency ?? 'USD';
    _selectedColor = widget.wallet?.colorValue ?? WalletColors.colors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.wallet != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Wallet' : 'Add Wallet'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Wallet Name',
                hintText: 'e.g., Main Bank Account',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<WalletType>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Wallet Type'),
              items: WalletType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(type.icon, size: 20),
                      const SizedBox(width: 8),
                      Text(type.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCurrency,
              decoration: const InputDecoration(labelText: 'Currency'),
              items: _currencies.map((currency) {
                return DropdownMenuItem(
                  value: currency,
                  child: Text(currency),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCurrency = value);
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _balanceController,
              decoration: const InputDecoration(
                labelText: 'Initial Balance',
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
              enabled: !isEditing, // Can't edit balance directly
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (Optional)',
                hintText: 'Add a note about this wallet',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Text(
              'Select Color',
              style: AppTypography.bodyMedium(),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: WalletColors.colors.map((color) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(color),
                      shape: BoxShape.circle,
                      border: _selectedColor == color
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Color(color).withValues(alpha: 0.3),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: _selectedColor == color
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saveWallet,
          child: Text(isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }

  void _saveWallet() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a wallet name')),
      );
      return;
    }

    final balance = double.tryParse(_balanceController.text) ?? 0.0;
    final bloc = context.read<WalletBloc>();

    final wallet = Wallet(
      id: widget.wallet?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      type: _selectedType,
      currency: _selectedCurrency,
      balance: widget.wallet?.balance ?? balance,
      colorValue: _selectedColor,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      isDefault: widget.wallet?.isDefault ?? false,
      isArchived: widget.wallet?.isArchived ?? false,
      createdAt: widget.wallet?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (widget.wallet != null) {
      bloc.updateWallet(wallet);
    } else {
      bloc.addWallet(wallet);
    }

    Navigator.pop(context);
  }
}

/// Dialog for transferring between wallets
class WalletTransferDialog extends StatefulWidget {
  final WalletBloc bloc;

  const WalletTransferDialog({super.key, required this.bloc});

  @override
  State<WalletTransferDialog> createState() => _WalletTransferDialogState();
}

class _WalletTransferDialogState extends State<WalletTransferDialog> {
  String? _fromWalletId;
  String? _toWalletId;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallets = widget.bloc.activeWallets;

    return AlertDialog(
      title: const Text('Transfer Between Wallets'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _fromWalletId,
              decoration: const InputDecoration(labelText: 'From Wallet'),
              items: wallets.map((wallet) {
                return DropdownMenuItem(
                  value: wallet.id,
                  child: Text('${wallet.name} (${wallet.currency} ${wallet.balance.toStringAsFixed(2)})'),
                );
              }).toList(),
              onChanged: (value) => setState(() => _fromWalletId = value),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _toWalletId,
              decoration: const InputDecoration(labelText: 'To Wallet'),
              items: wallets
                  .where((w) => w.id != _fromWalletId)
                  .map((wallet) {
                return DropdownMenuItem(
                  value: wallet.id,
                  child: Text('${wallet.name} (${wallet.currency})'),
                );
              }).toList(),
              onChanged: (value) => setState(() => _toWalletId = value),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (Optional)',
                hintText: 'e.g., Monthly savings transfer',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _fromWalletId != null && _toWalletId != null ? _transfer : null,
          child: const Text('Transfer'),
        ),
      ],
    );
  }

  void _transfer() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    widget.bloc.transferBetweenWallets(
      fromWalletId: _fromWalletId!,
      toWalletId: _toWalletId!,
      amount: amount,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    Navigator.pop(context);
  }
}
