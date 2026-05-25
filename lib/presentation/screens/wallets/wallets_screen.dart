import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../../core/services/currency_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../data/models/wallet_model.dart';
import '../../blocs/wallet_bloc.dart';
import 'package:flow_finance/core/utils/extensions.dart';
import 'add_wallet_screen.dart';

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
      title: 'Wallets'.tr(),
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _showAddWalletDialog(context),
        ),
      ],
      body: Consumer<WalletBloc>(
        builder: (context, bloc, child) {
          if (bloc.isLoading && bloc.wallets.isEmpty) {
            return AppLoading.fullScreen(message: 'Loading wallets...'.tr());
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
                    'Your Wallets'.tr(),
                    style: AppTypography.titleMedium(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
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
                      label: 'Transfer Between Wallets'.tr(),
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

  Widget _buildTotalBalanceCard(
      BuildContext context, WalletBloc bloc, bool isDark) {
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
              'Total Balance'.tr(),
              style: AppTypography.bodyMedium(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.format(bloc.totalBalance),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  Widget _buildWalletCard(
      BuildContext context, Wallet wallet, WalletBloc bloc, bool isDark) {
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
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      if (wallet.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Default'.tr(),
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
                    _localizedWalletType(wallet.type).tr(),
                    style: AppTypography.bodySmall(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
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
                    color: wallet.balance >= 0
                        ? AppColors.success
                        : AppColors.error,
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
                      'Set as Default'.tr(),
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddWalletScreen(),
      ),
    ).then((_) {
      // Reload wallets after adding
      context.read<WalletBloc>().loadWallets();
    });
  }

  void _showEditWalletDialog(
      BuildContext context, Wallet wallet, WalletBloc bloc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddWalletScreen(wallet: wallet),
      ),
    ).then((_) {
      // Reload wallets after editing
      context.read<WalletBloc>().loadWallets();
    });
  }

  void _showTransferDialog(BuildContext context, WalletBloc bloc) {
    showDialog(
      context: context,
      builder: (context) => WalletTransferDialog(bloc: bloc),
    );
  }

  String _localizedWalletType(WalletType type) {
    switch (type) {
      case WalletType.cash:
        return 'Cash';
      case WalletType.bank:
        return 'Bank Account';
      case WalletType.creditCard:
        return 'Credit/Debit Card';
      case WalletType.savings:
        return 'Savings';
      case WalletType.investment:
        return 'Investment';
      case WalletType.digital:
        return 'Digital Wallet';
      case WalletType.other:
        return 'Other';
    }
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
      title: Text('Transfer Between Wallets'.tr()),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _fromWalletId,
              decoration: InputDecoration(labelText: 'From Wallet'.tr()),
              items: wallets.map((wallet) {
                return DropdownMenuItem(
                  value: wallet.id,
                  child: Text(
                      '${wallet.name} (${wallet.currency} ${wallet.balance.toStringAsFixed(2)})'),
                );
              }).toList(),
              onChanged: (value) => setState(() => _fromWalletId = value),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _toWalletId,
              decoration: InputDecoration(labelText: 'To Wallet'.tr()),
              items: wallets.where((w) => w.id != _fromWalletId).map((wallet) {
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
              decoration: InputDecoration(
                labelText: 'Amount'.tr(),
                prefixText: CurrencyFormatter.currentCurrency.symbol,
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Note (Optional)'.tr(),
                hintText: 'e.g., Monthly savings transfer'.tr(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'.tr()),
        ),
        FilledButton(
          onPressed:
              _fromWalletId != null && _toWalletId != null ? _transfer : null,
          child: Text('Transfer'.tr()),
        ),
      ],
    );
  }

  void _transfer() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      context.showSnackBar(
        SnackBar(content: Text('Please enter a valid amount'.tr())),
      );
      return;
    }

    widget.bloc.transferBetweenWallets(
      fromWalletId: _fromWalletId!,
      toWalletId: _toWalletId!,
      amount: amount,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    Navigator.pop(context);
  }
}
