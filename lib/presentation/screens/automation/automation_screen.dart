import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/smart_rules_engine.dart';
import '../../../core/services/auto_transfer_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../data/models/wallet_model.dart';
import '../../blocs/wallet_bloc.dart';

/// Automation settings screen
class AutomationScreen extends StatefulWidget {
  const AutomationScreen({super.key});

  @override
  State<AutomationScreen> createState() => _AutomationScreenState();
}

class _AutomationScreenState extends State<AutomationScreen> {
  final SmartRulesEngine _rulesEngine = SmartRulesEngine();
  final AutoTransferService _transferService = AutoTransferService();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      title: 'Automation',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Smart Rules Section
            _buildSectionTitle('Smart Rules', isDark),
            const SizedBox(height: 12),
            _buildSmartRulesCard(isDark),
            
            const SizedBox(height: 24),
            
            // Auto-Transfer Section
            _buildSectionTitle('Auto-Transfer', isDark),
            const SizedBox(height: 12),
            _buildAutoTransferCard(isDark),
            
            const SizedBox(height: 24),
            
            // Round-Up Section
            _buildSectionTitle('Round-Up Savings', isDark),
            const SizedBox(height: 12),
            _buildRoundUpCard(isDark),
            
            const SizedBox(height: 24),
            
            // Savings Summary
            _buildSavingsSummaryCard(isDark),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: AppTypography.titleMedium(
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      ),
    );
  }

  Widget _buildSmartRulesCard(bool isDark) {
    final rules = _rulesEngine.getRules();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Auto-Categorization Rules', style: AppTypography.bodyMedium(fontWeight: FontWeight.w600)),
            subtitle: Text(
              '${rules.length} rules active',
              style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
            ),
            trailing: AppButton.primary(
              label: 'Add Rule',
              onPressed: () => _showAddRuleDialog(),
              size: AppButtonSize.small,
            ),
          ),
          if (rules.isNotEmpty) ...[
            const Divider(),
            ...rules.take(3).map((rule) => _buildRuleTile(rule)),
            if (rules.length > 3)
              TextButton(
                onPressed: () => _showAllRules(),
                child: Text('View all ${rules.length} rules'),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildRuleTile(SmartRule rule) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        rule.isActive ? Icons.check_circle : Icons.cancel,
        color: rule.isActive ? AppColors.success : AppColors.textSecondaryLight,
      ),
      title: Text(rule.name, style: AppTypography.bodySmall()),
      subtitle: Text(
        '${rule.conditions.length} conditions → ${rule.actions.length} actions',
        style: AppTypography.labelSmall(color: AppColors.textSecondaryLight),
      ),
      trailing: Switch(
        value: rule.isActive,
        onChanged: (value) {
          setState(() {
            _rulesEngine.updateRule(rule.copyWith(isActive: value));
          });
        },
      ),
    );
  }

  Widget _buildAutoTransferCard(bool isDark) {
    final rules = _transferService.rules;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Automatic Transfers', style: AppTypography.bodyMedium(fontWeight: FontWeight.w600)),
            subtitle: Text(
              'Automatically move money based on triggers',
              style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
            ),
            trailing: AppButton.primary(
              label: 'Add',
              onPressed: () => _showAddAutoTransferDialog(),
              size: AppButtonSize.small,
            ),
          ),
          if (rules.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No auto-transfer rules yet',
                  style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
                ),
              ),
            )
          else
            ...rules.map((rule) => _buildAutoTransferTile(rule)),
        ],
      ),
    );
  }

  Widget _buildAutoTransferTile(AutoTransferRule rule) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.sync_alt, color: AppColors.primary, size: 20),
      ),
      title: Text(rule.name, style: AppTypography.bodySmall()),
      subtitle: Text(
        '${rule.calculationType.name}: \$${rule.amount}',
        style: AppTypography.labelSmall(color: AppColors.textSecondaryLight),
      ),
      trailing: Switch(
        value: rule.isActive,
        onChanged: (value) {
          setState(() {
            _transferService.addAutoTransferRule(rule.copyWith(isActive: value));
          });
        },
      ),
    );
  }

  Widget _buildRoundUpCard(bool isDark) {
    final rules = _transferService.roundUpRules;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Round-Up Savings', style: AppTypography.bodyMedium(fontWeight: FontWeight.w600)),
            subtitle: Text(
              'Round up purchases and save the change',
              style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
            ),
            trailing: AppButton.primary(
              label: 'Add',
              onPressed: () => _showAddRoundUpDialog(),
              size: AppButtonSize.small,
            ),
          ),
          if (rules.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No round-up rules yet',
                  style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
                ),
              ),
            )
          else
            ...rules.map((rule) => _buildRoundUpTile(rule)),
        ],
      ),
    );
  }

  Widget _buildRoundUpTile(RoundUpRule rule) {
    String roundUpText;
    switch (rule.roundUpTo) {
      case RoundUpTo.nearestDollar:
        roundUpText = 'Nearest \$1';
        break;
      case RoundUpTo.nearestFive:
        roundUpText = 'Nearest \$5';
        break;
      case RoundUpTo.nearestTen:
        roundUpText = 'Nearest \$10';
        break;
      case RoundUpTo.custom:
        roundUpText = 'Nearest \$${rule.customAmount}';
        break;
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.rounded_corner, color: AppColors.success, size: 20),
      ),
      title: Text(rule.name, style: AppTypography.bodySmall()),
      subtitle: Text(
        roundUpText,
        style: AppTypography.labelSmall(color: AppColors.textSecondaryLight),
      ),
      trailing: Switch(
        value: rule.isActive,
        onChanged: (value) {
          setState(() {
            _transferService.addRoundUpRule(
              RoundUpRule(
                id: rule.id,
                name: rule.name,
                roundUpTo: rule.roundUpTo,
                customAmount: rule.customAmount,
                sourceWalletId: rule.sourceWalletId,
                savingsWalletId: rule.savingsWalletId,
                isActive: value,
                createdAt: rule.createdAt,
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildSavingsSummaryCard(bool isDark) {
    final summary = _transferService.getSavingsSummary();

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Savings Summary (Last 30 Days)', style: AppTypography.bodyMedium(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryStat(
                    'Total Saved',
                    '\$${summary.totalSaved.toStringAsFixed(2)}',
                    AppColors.success,
                  ),
                ),
                Expanded(
                  child: _buildSummaryStat(
                    'Transfers',
                    '${summary.transferCount}',
                    AppColors.primary,
                  ),
                ),
                Expanded(
                  child: _buildSummaryStat(
                    'Average',
                    '\$${summary.averagePerTransfer.toStringAsFixed(2)}',
                    AppColors.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.titleMedium(
            color: color,
          ).copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.labelSmall(color: AppColors.textSecondaryLight),
        ),
      ],
    );
  }

  void _showAddRuleDialog() {
    // TODO: Implement rule creation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Smart Rule'),
        content: const Text('Rule creation dialog to be implemented'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAllRules() {
    // TODO: Show all rules screen
  }

  void _showAddAutoTransferDialog() {
    final walletBloc = context.read<WalletBloc>();
    final wallets = walletBloc.wallets;

    if (wallets.length < 2) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Need More Wallets'),
          content: const Text('You need at least 2 wallets to set up auto-transfers.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _AutoTransferDialog(
        wallets: wallets,
        onSave: (rule) {
          setState(() {
            _transferService.addAutoTransferRule(rule);
          });
        },
      ),
    );
  }

  void _showAddRoundUpDialog() {
    final walletBloc = context.read<WalletBloc>();
    final wallets = walletBloc.wallets;

    if (wallets.length < 2) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Need More Wallets'),
          content: const Text('You need at least 2 wallets to set up round-up savings.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _RoundUpDialog(
        wallets: wallets,
        onSave: (rule) {
          setState(() {
            _transferService.addRoundUpRule(rule);
          });
        },
      ),
    );
  }
}

class _AutoTransferDialog extends StatefulWidget {
  final List<Wallet> wallets;
  final Function(AutoTransferRule) onSave;

  const _AutoTransferDialog({
    required this.wallets,
    required this.onSave,
  });

  @override
  State<_AutoTransferDialog> createState() => _AutoTransferDialogState();
}

class _AutoTransferDialogState extends State<_AutoTransferDialog> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String? _sourceWalletId;
  String? _destWalletId;
  CalculationType _calcType = CalculationType.fixedAmount;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Auto-Transfer'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Rule Name'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _sourceWalletId,
              decoration: const InputDecoration(labelText: 'From Wallet'),
              items: widget.wallets.map((w) {
                return DropdownMenuItem(value: w.id, child: Text(w.name));
              }).toList(),
              onChanged: (v) => setState(() => _sourceWalletId = v),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _destWalletId,
              decoration: const InputDecoration(labelText: 'To Wallet'),
              items: widget.wallets.map((w) {
                return DropdownMenuItem(value: w.id, child: Text(w.name));
              }).toList(),
              onChanged: (v) => setState(() => _destWalletId = v),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CalculationType>(
              value: _calcType,
              decoration: const InputDecoration(labelText: 'Calculation Type'),
              items: CalculationType.values.map((t) {
                return DropdownMenuItem(value: t, child: Text(t.name));
              }).toList(),
              onChanged: (v) => setState(() => _calcType = v!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: _calcType == CalculationType.percentage ? 'Percentage (%)' : 'Amount (\$)',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        AppButton.primary(
          label: 'Save',
          onPressed: () {
            if (_nameController.text.isEmpty ||
                _sourceWalletId == null ||
                _destWalletId == null ||
                _amountController.text.isEmpty) {
              return;
            }

            final rule = AutoTransferRule(
              id: const Uuid().v4(),
              name: _nameController.text,
              trigger: TransferTrigger(type: TriggerType.incomeReceived),
              sourceWalletId: _sourceWalletId!,
              destinationWalletId: _destWalletId!,
              calculationType: _calcType,
              amount: double.parse(_amountController.text),
              createdAt: DateTime.now(),
            );

            widget.onSave(rule);
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}

class _RoundUpDialog extends StatefulWidget {
  final List<Wallet> wallets;
  final Function(RoundUpRule) onSave;

  const _RoundUpDialog({
    required this.wallets,
    required this.onSave,
  });

  @override
  State<_RoundUpDialog> createState() => _RoundUpDialogState();
}

class _RoundUpDialogState extends State<_RoundUpDialog> {
  final _nameController = TextEditingController();
  String? _sourceWalletId;
  String? _savingsWalletId;
  RoundUpTo _roundUpTo = RoundUpTo.nearestDollar;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Round-Up Rule'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Rule Name'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _sourceWalletId,
              decoration: const InputDecoration(labelText: 'Spending Wallet'),
              items: widget.wallets.map((w) {
                return DropdownMenuItem(value: w.id, child: Text(w.name));
              }).toList(),
              onChanged: (v) => setState(() => _sourceWalletId = v),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _savingsWalletId,
              decoration: const InputDecoration(labelText: 'Savings Wallet'),
              items: widget.wallets.map((w) {
                return DropdownMenuItem(value: w.id, child: Text(w.name));
              }).toList(),
              onChanged: (v) => setState(() => _savingsWalletId = v),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<RoundUpTo>(
              value: _roundUpTo,
              decoration: const InputDecoration(labelText: 'Round Up To'),
              items: RoundUpTo.values.map((t) {
                String label;
                switch (t) {
                  case RoundUpTo.nearestDollar:
                    label = 'Nearest \$1';
                    break;
                  case RoundUpTo.nearestFive:
                    label = 'Nearest \$5';
                    break;
                  case RoundUpTo.nearestTen:
                    label = 'Nearest \$10';
                    break;
                  case RoundUpTo.custom:
                    label = 'Custom';
                    break;
                }
                return DropdownMenuItem(value: t, child: Text(label));
              }).toList(),
              onChanged: (v) => setState(() => _roundUpTo = v!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        AppButton.primary(
          label: 'Save',
          onPressed: () {
            if (_nameController.text.isEmpty ||
                _sourceWalletId == null ||
                _savingsWalletId == null) {
              return;
            }

            final rule = RoundUpRule(
              id: const Uuid().v4(),
              name: _nameController.text,
              roundUpTo: _roundUpTo,
              sourceWalletId: _sourceWalletId!,
              savingsWalletId: _savingsWalletId!,
              createdAt: DateTime.now(),
            );

            widget.onSave(rule);
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
