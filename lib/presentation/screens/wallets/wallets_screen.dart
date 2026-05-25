import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../data/models/currency_model.dart';
import '../../blocs/wallet_bloc.dart';
import '../../../core/utils/extensions.dart';
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
                      '${_currencySymbol(entry.key)}${entry.value.toStringAsFixed(2)}',
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
      onDismissed: (_) => _confirmAndDeleteWallet(context, bloc, wallet),
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
                  '${_currencySymbol(wallet.currency)}${wallet.balance.toStringAsFixed(2)}',
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

  void _confirmAndDeleteWallet(BuildContext context, WalletBloc bloc, Wallet wallet) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Wallet'.tr()),
        content: Text('Are you sure you want to delete "${wallet.name}"?'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              bloc.deleteWallet(wallet.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text('Delete'.tr()),
          ),
        ],
      ),
    );
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
  final TextEditingController _exchangeRateController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _isCrossCurrency = false;
  double? _exchangeRate;

  @override
  void dispose() {
    _amountController.dispose();
    _exchangeRateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onWalletsChanged() {
    if (_fromWalletId == null || _toWalletId == null) return;
    final from = widget.bloc.wallets.firstWhere((w) => w.id == _fromWalletId);
    final to = widget.bloc.wallets.firstWhere((w) => w.id == _toWalletId);
    final cross = from.currency != to.currency;
    if (cross != _isCrossCurrency) {
      setState(() {
        _isCrossCurrency = cross;
        if (cross) {
          _exchangeRateController.text = '';
          _exchangeRate = null;
        }
      });
    }
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
                      '${wallet.name} (${_currencySymbol(wallet.currency)}${wallet.balance.toStringAsFixed(2)})'),
                );
              }).toList(),
              onChanged: (value) => setState(() {
                _fromWalletId = value;
                if (_toWalletId == value) _toWalletId = null;
                _onWalletsChanged();
              }),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _toWalletId,
              decoration: InputDecoration(labelText: 'To Wallet'.tr()),
              items: wallets.where((w) => w.id != _fromWalletId).map((wallet) {
                return DropdownMenuItem(
                  value: wallet.id,
                  child: Text('${wallet.name} (${_currencySymbol(wallet.currency)})'),
                );
              }).toList(),
              onChanged: (value) => setState(() {
                _toWalletId = value;
                _onWalletsChanged();
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount'.tr(),
                prefixText: CurrencyFormatter.currentCurrency.symbol,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
              onChanged: (_) => setState(() {}),
            ),
            if (_isCrossCurrency && _fromWalletId != null && _toWalletId != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.swap_horiz, size: 16, color: AppColors.warning),
                        const SizedBox(width: 6),
                        Text(
                          'Cross-Currency Transfer'.tr(),
                          style: AppTypography.labelMedium(
                            fontWeight: FontWeight.w600,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1 ${_fromWalletId != null ? (widget.bloc.wallets.firstWhere((w) => w.id == _fromWalletId).currency) : ''} = ? ${_toWalletId != null ? (widget.bloc.wallets.firstWhere((w) => w.id == _toWalletId).currency) : ''}'.tr(),
                      style: AppTypography.bodySmall(),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _exchangeRateController,
                      decoration: InputDecoration(
                        labelText: 'Exchange Rate'.tr(),
                        hintText: 'e.g., 83.50'.tr(),
                        prefixText: '1 ${_currencySymbol(widget.bloc.wallets.firstWhere((w) => w.id == _fromWalletId).currency)} = ',
                        suffixText: _currencySymbol(widget.bloc.wallets.firstWhere((w) => w.id == _toWalletId).currency),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        setState(() {
                          _exchangeRate = double.tryParse(v);
                        });
                      },
                    ),
                    if (_exchangeRate != null && _exchangeRate! > 0 && (_amountController.text.isNotEmpty)) ...[
                      const SizedBox(height: 8),
                      _buildConversionPreview(context),
                    ],
                  ],
                ),
              ),
            ],
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
          onPressed: _fromWalletId != null && _toWalletId != null && _amountController.text.isNotEmpty
              ? _transfer
              : null,
          child: Text('Transfer'.tr()),
        ),
      ],
    );
  }

  Widget _buildConversionPreview(BuildContext context) {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final to = widget.bloc.wallets.firstWhere((w) => w.id == _toWalletId);
    final converted = amount * _exchangeRate!;
    return Text(
      '→ ${CurrencyFormatter.format(converted, currencyCode: to.currency)}',
      style: AppTypography.bodySmall(color: AppColors.success),
    );
  }

  Future<void> _transfer() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      context.showSnackBar(
        SnackBar(content: Text('Please enter a valid amount'.tr())),
      );
      return;
    }

    if (_fromWalletId == _toWalletId) {
      context.showSnackBar(
        SnackBar(content: Text('Source and destination wallets must be different'.tr())),
      );
      return;
    }

    final fromWallet = widget.bloc.wallets.firstWhere((w) => w.id == _fromWalletId);
    final toWallet = widget.bloc.wallets.firstWhere((w) => w.id == _toWalletId);

    if (fromWallet.balance < amount) {
      context.showSnackBar(
        SnackBar(content: Text('Insufficient balance in source wallet'.tr())),
      );
      return;
    }

    double? exchangeRate;
    if (fromWallet.currency != toWallet.currency) {
      final rate = double.tryParse(_exchangeRateController.text);
      if (rate == null || rate <= 0) {
        context.showSnackBar(
          SnackBar(content: Text('Please enter a valid exchange rate'.tr())),
        );
        return;
      }
      exchangeRate = rate;
    }

    await widget.bloc.transferBetweenWallets(
      fromWalletId: _fromWalletId!,
      toWalletId: _toWalletId!,
      amount: amount,
      exchangeRate: exchangeRate,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    if (!context.mounted) return;
    Navigator.pop(context);
  }
}

String _currencySymbol(String code) =>
    SupportedCurrencies.getByCode(code)?.symbol ?? code;
